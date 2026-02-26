import Foundation
import Observation
import os

// MARK: - OpenRouter API Models
struct OpenRouterRequest: Codable {
    let model: String
    let messages: [OpenRouterMessage]
}

struct OpenRouterMessage: Codable {
    let role: String
    let content: String
}

struct OpenRouterResponse: Codable {
    let choices: [OpenRouterChoice]?
}

struct OpenRouterChoice: Codable {
    let message: OpenRouterMessage?
}

// MARK: - AI Service
/// Gemini API wrapper for AI-powered interpretations.
@Observable
class AIService {
    static let shared = AIService()

    var isGenerating: Bool = false
    private let logger = Logger(subsystem: "rk.horoscope", category: "AIService")

    private init() {}

    // MARK: - Core API Call
    private func generateContent(prompt: String, systemInstruction: String? = nil) async throws -> String {
        guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else {
            throw URLError(.badURL)
        }

        let apiKey = Secrets.openRouterAPIKey
        guard !apiKey.isEmpty else {
            throw ConfigurationError.missingSecret("OPENROUTER_API_KEY")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Optional OpenRouter headers
        request.setValue("Mystik Astroloji", forHTTPHeaderField: "X-Title")
        
        var messages: [OpenRouterMessage] = []
        if let sysInst = systemInstruction {
            messages.append(OpenRouterMessage(role: "system", content: sysInst))
        }
        messages.append(OpenRouterMessage(role: "user", content: prompt))
        
        let reqBody = OpenRouterRequest(
            model: "google/gemini-3-flash-preview",
            messages: messages
        )
        
        request.httpBody = try JSONEncoder().encode(reqBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown"
            logger.error("OpenRouter text request failed: \(errorBody, privacy: .private(mask: .hash))")
            throw URLError(.badServerResponse)
        }
        
        let orResponse = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        guard let text = orResponse.choices?.first?.message?.content else {
            return "Yorum alınamadı."
        }
        
        return text
    }

    private func generateMultimodalContent(
        prompt: String,
        systemInstruction: String? = nil,
        imageData: Data
    ) async throws -> String {
        guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else {
            throw URLError(.badURL)
        }

        let apiKey = Secrets.openRouterAPIKey
        guard !apiKey.isEmpty else {
            throw ConfigurationError.missingSecret("OPENROUTER_API_KEY")
        }

        let base64Image = imageData.base64EncodedString()
        let imageDataURL = "data:image/jpeg;base64,\(base64Image)"

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Mystik Astroloji", forHTTPHeaderField: "X-Title")

        var messages: [[String: Any]] = []
        if let systemInstruction {
            messages.append([
                "role": "system",
                "content": systemInstruction
            ])
        }

        messages.append([
            "role": "user",
            "content": [
                [
                    "type": "text",
                    "text": prompt
                ],
                [
                    "type": "image_url",
                    "image_url": [
                        "url": imageDataURL
                    ]
                ]
            ]
        ])

        let requestBody: [String: Any] = [
            "model": "google/gemini-2.0-flash-001",
            "messages": messages
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown"
            logger.error("OpenRouter multimodal request failed: \(errorBody, privacy: .private(mask: .hash))")
            throw URLError(.badServerResponse)
        }

        if let content = parseAssistantContent(from: data) {
            return content
        }

        return "Yorum alınamadı."
    }

    private func parseAssistantContent(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any] else {
            return nil
        }

        if let content = message["content"] as? String {
            let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        if let parts = message["content"] as? [[String: Any]] {
            let text = parts
                .compactMap { $0["text"] as? String }
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return text.isEmpty ? nil : text
        }

        return nil
    }

    // MARK: - Natal Chart Interpretation

    func interpretNatalChart(chartData: ChartData, birthData: BirthData) async throws -> String {
        isGenerating = true
        defer { isGenerating = false }

        // Find Big 3
        let sun = chartData.planetPositions.first(where: { $0.planet == .sun })?.sign.rawValue ?? birthData.sunSign.rawValue
        let moon = chartData.planetPositions.first(where: { $0.planet == .moon })?.sign.rawValue ?? "Bilinmiyor"
        let ascendant = chartData.houseCusps.first?.sign.rawValue ?? "Bilinmiyor"
        
        let systemPrompt = "Sen 'Mystik' adında, uzman bir astroloji asistanısın. Kısa, samimi, modern ve ilham verici bir dille astroloji yorumu yaparsın. Markdown formatı kullanırsın."
        
        let prompt = """
        Kullanıcının adı yok ama ona göre bir natal harita yorumu yap.
        Güneş Burcu: \(sun)
        Ay Burcu: \(moon)
        Yükselen Burcu: \(ascendant)
        
        Lütfen bu üç ana yerleşim (Big 3) üzerinden kişinin karakterini, iç dünyasını ve dışarıya yansıttığı imajı kısaca ama derinlemesine analiz et. Etkileyici bir başlıkla başla.
        """

        return try await generateContent(prompt: prompt, systemInstruction: systemPrompt)
    }

    // MARK: - Transit Interpretation

    func interpretTransit(event: TransitEvent, birthData: BirthData) async throws -> String {
        isGenerating = true
        defer { isGenerating = false }

        let systemPrompt = "Sen uzman bir astroloğsun. Transitlerin etkilerini anlaşılır şekilde açıklarsın."
        let prompt = """
        Kullanıcının \(event.natalPlanet.rawValue) gezegeni üzerinden şu anda \(event.transitPlanet.rawValue) geçiyor ve \(event.aspectType.rawValue) açısı yapıyor. 
        Bu \(event.durationDays) günlük bir transit. Etkisi: \(event.severity.rawValue).
        Lütfen bu transetin kullanıcının hayatına kısa vadeli etkilerini yorumla.
        """

        return try await generateContent(prompt: prompt, systemInstruction: systemPrompt)
    }

    // MARK: - Dream Interpretation

    func interpretDream(dreamText: String) async throws -> String {
        isGenerating = true
        defer { isGenerating = false }

        let systemPrompt = "Sen rüya analizleri ve sembolizm konusunda uzman bir rehbersin."
        let prompt = """
        Kullanıcının gördüğü rüya: "\(dreamText)"
        Lütfen bu rüyayı psikolojik ve spiritüel (mistik) açılardan kısaca yorumla. Sembollerin olası anlamlarını açıkla.
        """

        return try await generateContent(prompt: prompt, systemInstruction: systemPrompt)
    }

    // MARK: - Palm Reading

    func interpretPalm(imageData: Data?) async throws -> String {
        isGenerating = true
        defer { isGenerating = false }

        guard let imageData, !imageData.isEmpty else {
            throw AIServiceError.missingPalmImage
        }

        let systemPrompt = "Sen el falı bakan mistik bir yapay zekasın."
        let prompt = """
        Bu avuç içi fotoğrafını analiz et.
        Kısa ama kişiselleştirilmiş bir el falı yorumu yaz.
        Kalp çizgisi, akıl çizgisi, yaşam çizgisi ve kariyer eğiliminden bahset.
        Ton: samimi, mistik, umut veren.
        """

        return try await generateMultimodalContent(
            prompt: prompt,
            systemInstruction: systemPrompt,
            imageData: imageData
        )
    }

    // MARK: - Chat Response

    func getChatResponse(
        messages: [ChatMessage],
        context: ChatContext,
        birthData: BirthData?
    ) async throws -> String {
        isGenerating = true
        defer { isGenerating = false }

        var systemPrompt = "Sen 'Mystik' adında astroloji, rüya yorumu, tarot ve spiritüel danışmanlık yapan bir yapay zekasın. Kısa, samimi ve mistik bir dille yanıt ver."
        
        if let bd = birthData {
            systemPrompt += " Kullanıcının Güneş burcu \(bd.sunSign.rawValue). Yorumlarına bunu dahil edebilirsin."
        }
        
        systemPrompt += " Şu anda konuştuğunuz bağlam: \(context.rawValue)."

        // Send full conversation history for multi-turn context
        guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else {
            throw URLError(.badURL)
        }

        let apiKey = Secrets.openRouterAPIKey
        guard !apiKey.isEmpty else {
            throw ConfigurationError.missingSecret("OPENROUTER_API_KEY")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Mystik Astroloji", forHTTPHeaderField: "X-Title")
        
        // Build message array with system prompt + full history
        var orMessages: [OpenRouterMessage] = [
            OpenRouterMessage(role: "system", content: systemPrompt)
        ]
        
        // Add conversation history (skip system messages, limit to last 20 for token efficiency)
        let recentMessages = messages.suffix(20)
        for msg in recentMessages where msg.role != .system {
            orMessages.append(OpenRouterMessage(role: msg.role.rawValue, content: msg.content))
        }
        
        let reqBody = OpenRouterRequest(
            model: "google/gemini-3-flash-preview",
            messages: orMessages
        )
        
        request.httpBody = try JSONEncoder().encode(reqBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown"
            logger.error("OpenRouter chat request failed (\((response as? HTTPURLResponse)?.statusCode ?? 0)): \(errorBody, privacy: .private(mask: .hash))")
            throw URLError(.badServerResponse)
        }
        
        let orResponse = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        guard let text = orResponse.choices?.first?.message?.content else {
            return "Yorum alınamadı."
        }
        
        return text
    }
}

enum AIServiceError: LocalizedError {
    case missingPalmImage

    var errorDescription: String? {
        switch self {
        case .missingPalmImage:
            return "Lütfen önce elinizin fotoğrafını ekleyin."
        }
    }
}
