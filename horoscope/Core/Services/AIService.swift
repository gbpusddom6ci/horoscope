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
    private let openRouterModel = "google/gemini-3-flash-preview"

    var isGenerating: Bool = false
    private let logger = Logger(subsystem: "rk.horoscope", category: "AIService")

    private init() {}

    private func validateOpenRouterResponse(
        data: Data,
        response: URLResponse,
        requestLabel: String
    ) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown"
            logger.error("\(requestLabel, privacy: .public) failed (\(httpResponse.statusCode)): \(errorBody, privacy: .private(mask: .hash))")
            throw mapHTTPError(statusCode: httpResponse.statusCode)
        }
    }

    private func mapHTTPError(statusCode: Int) -> AIServiceError {
        switch statusCode {
        case 401, 403:
            return .unauthorized
        case 429:
            return .rateLimited
        case 500..<600:
            return .upstreamUnavailable
        default:
            return .requestFailed(statusCode: statusCode)
        }
    }

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
        request.setValue("Mystic Astrology", forHTTPHeaderField: "X-Title")
        
        var messages: [OpenRouterMessage] = []
        if let sysInst = systemInstruction {
            messages.append(OpenRouterMessage(role: "system", content: sysInst))
        }
        messages.append(OpenRouterMessage(role: "user", content: prompt))
        
        let reqBody = OpenRouterRequest(
            model: openRouterModel,
            messages: messages
        )
        
        request.httpBody = try JSONEncoder().encode(reqBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        try validateOpenRouterResponse(data: data, response: response, requestLabel: "OpenRouter text request")
        
        let orResponse = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        guard let text = orResponse.choices?.first?.message?.content else {
            throw AIServiceError.emptyResponse
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
        request.setValue("Mystic Astrology", forHTTPHeaderField: "X-Title")

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
            "model": openRouterModel,
            "messages": messages
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateOpenRouterResponse(data: data, response: response, requestLabel: "OpenRouter multimodal request")

        if let content = parseAssistantContent(from: data) {
            return content
        }

        throw AIServiceError.emptyResponse
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
        let sun = chartData.planetPositions.first(where: { $0.planet == .sun })?.sign.localizedDisplayName ?? birthData.sunSign.localizedDisplayName
        let moon = chartData.planetPositions.first(where: { $0.planet == .moon })?.sign.localizedDisplayName ?? String(localized: "common.unknown")
        let ascendant = chartData.houseCusps.first?.sign.localizedDisplayName ?? String(localized: "common.unknown")
        
        let systemPrompt = "You are 'Mystic', an expert astrology assistant. Provide concise, warm, modern, and inspiring astrology guidance. Use Markdown formatting."
        
        let prompt = """
        The user's name is unavailable, but provide a natal chart interpretation tailored to them.
        Sun Sign: \(sun)
        Moon Sign: \(moon)
        Rising Sign: \(ascendant)

        Please analyze personality, inner emotional world, and outward expression based on this Big 3 summary in a concise but meaningful way. Start with a compelling title.
        """

        return try await generateContent(prompt: prompt, systemInstruction: systemPrompt)
    }

    // MARK: - Transit Interpretation

    func interpretTransit(event: TransitEvent, birthData: BirthData) async throws -> String {
        isGenerating = true
        defer { isGenerating = false }

        let systemPrompt = "You are an expert astrologer. Explain transit effects clearly and practically."
        let prompt = """
        The user's natal \(event.natalPlanet.localizedDisplayName) is currently receiving a \(event.aspectType.localizedDisplayName) from transiting \(event.transitPlanet.localizedDisplayName).
        This transit lasts \(event.durationDays) days. Severity: \(event.severity.localizedDisplayName).
        Please interpret the short-term effects of this transit on the user's life.
        """

        return try await generateContent(prompt: prompt, systemInstruction: systemPrompt)
    }

    // MARK: - Dream Interpretation

    func interpretDream(dreamText: String) async throws -> String {
        isGenerating = true
        defer { isGenerating = false }

        let systemPrompt = "You are an expert guide in dream analysis and symbolism."
        let prompt = """
        User's dream: "\(dreamText)"
        Please interpret this dream briefly from both psychological and spiritual perspectives. Explain likely meanings of key symbols.
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

        let systemPrompt = "You are a mystical AI palm reader."
        let prompt = """
        Analyze this palm photo.
        Write a concise but personalized palm reading.
        Mention the heart line, head line, life line, and career tendencies.
        Tone: warm, mystical, and hopeful.
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

        var systemPrompt = "You are 'Mystic', an AI assistant for astrology, dream interpretation, tarot, and spiritual guidance. Reply in concise, warm, and mystical English."
        
        if let bd = birthData {
            systemPrompt += " The user's Sun sign is \(bd.sunSign.localizedDisplayName). You may incorporate this context in your response."
        }
        
        systemPrompt += " Current conversation context: \(context.localizedDisplayName)."

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
        request.setValue("Mystic Astrology", forHTTPHeaderField: "X-Title")
        
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
            model: openRouterModel,
            messages: orMessages
        )
        
        request.httpBody = try JSONEncoder().encode(reqBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        try validateOpenRouterResponse(data: data, response: response, requestLabel: "OpenRouter chat request")
        
        let orResponse = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        guard let text = orResponse.choices?.first?.message?.content else {
            throw AIServiceError.emptyResponse
        }
        
        return text
    }
}

enum AIServiceError: LocalizedError {
    case missingPalmImage
    case unauthorized
    case rateLimited
    case upstreamUnavailable
    case requestFailed(statusCode: Int)
    case invalidResponse
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .missingPalmImage:
            return String(localized: "ai.error.missing_palm_image")
        case .unauthorized:
            return String(localized: "ai.error.unauthorized")
        case .rateLimited:
            return String(localized: "ai.error.rate_limited")
        case .upstreamUnavailable:
            return String(localized: "ai.error.upstream_unavailable")
        case .requestFailed(let statusCode):
            return String(format: String(localized: "ai.error.request_failed"), statusCode)
        case .invalidResponse:
            return String(localized: "ai.error.invalid_response")
        case .emptyResponse:
            return String(localized: "ai.error.empty_response")
        }
    }
}
