import Foundation
import Observation

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
/// Currently returns mock responses. Replace with real API calls after setup.
@Observable
class AIService {
    static let shared = AIService()

    var isGenerating: Bool = false

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
            print("API Error: \(String(data: data, encoding: .utf8) ?? "Unknown")")
            throw URLError(.badServerResponse)
        }
        
        let orResponse = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        guard let text = orResponse.choices?.first?.message?.content else {
            return "Yorum alınamadı."
        }
        
        return text
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

        // Multimodal is complex for MVP, so we will return a fun AI generated general text for now,
        // unless we want to send base64 image (which gemini-pro-vision or gemini-1.5-flash supports).
        // Since we are using gemini-pro (text only) in generateContent, we'll keep it as text logic for now.
        let systemPrompt = "Sen el falı bakan mistik bir yapay zekasın."
        let prompt = "Kullanıcı elinin fotoğrafını gönderdi (görsel işlemeyi atlıyoruz şimdilik). Ona çok kısa, etkileyici ve genel geçer mistik bir el falı yorumu yap (kalp çizgisi, akıl çizgisi, kariyer gibi şeylerden bahset)."

        return try await generateContent(prompt: prompt, systemInstruction: systemPrompt)
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
            print("API Error (\((response as? HTTPURLResponse)?.statusCode ?? 0)): \(errorBody)")
            throw URLError(.badServerResponse)
        }
        
        let orResponse = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        guard let text = orResponse.choices?.first?.message?.content else {
            return "Yorum alınamadı."
        }
        
        return text
    }
}
