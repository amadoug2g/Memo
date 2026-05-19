import Foundation

// MARK: - Protocol

protocol PostProcessing: AnyObject {
    func process(text: String, prompt: String, apiKey: String) async throws -> String
}

// MARK: - Preset prompts

enum PostProcessingPrompt: String, CaseIterable, Identifiable {
    case cleanGrammar      = "cleanGrammar"
    case formalFrench      = "formalFrench"
    case translateEnglish  = "translateEnglish"
    case bulletPoints      = "bulletPoints"
    case emailFormat       = "emailFormat"
    case custom            = "custom"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .cleanGrammar:     return "Clean grammar & punctuation"
        case .formalFrench:     return "Formal French"
        case .translateEnglish: return "Translate to English"
        case .bulletPoints:     return "Bullet points"
        case .emailFormat:      return "Email format"
        case .custom:           return "Custom prompt…"
        }
    }

    var systemPrompt: String {
        switch self {
        case .cleanGrammar:
            return "You are a proofreading assistant. Correct grammar, spelling, and punctuation in the user's text. Keep the same language, tone, and meaning. Return only the corrected text with no explanations."
        case .formalFrench:
            return "Tu es un assistant de rédaction professionnelle. Reformule le texte de l'utilisateur en français formel, en conservant le sens. Retourne uniquement le texte reformulé, sans explications."
        case .translateEnglish:
            return "You are a translation assistant. Translate the user's text into natural, fluent English. Return only the translation with no explanations."
        case .bulletPoints:
            return "You are a summarization assistant. Convert the user's text into a concise bullet-point list. Use plain dashes (-) as bullets. Return only the bullets with no preamble."
        case .emailFormat:
            return "You are an email writing assistant. Reformat the user's text into a clear, professional email with an appropriate greeting and closing. Return only the email text."
        case .custom:
            return ""
        }
    }
}

// MARK: - API provider

enum PostProcessingAPI: String, CaseIterable, Identifiable {
    case openAI  = "openAI"
    case claude  = "claude"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .openAI:  return "OpenAI (GPT-4o mini)"
        case .claude:  return "Anthropic (Claude Haiku)"
        }
    }
}

// MARK: - Errors

enum PostProcessorError: LocalizedError {
    case missingAPIKey
    case httpError(Int, String)
    case emptyResponse
    case emptyPrompt

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Post-processing API key is not set. Add it in Settings under Post-processing."
        case .httpError(let code, let body):
            return "Post-processing API error \(code): \(body)"
        case .emptyResponse:
            return "Post-processing returned an empty response."
        case .emptyPrompt:
            return "No system prompt provided for post-processing."
        }
    }
}

// MARK: - PostProcessor

final class PostProcessor: PostProcessing {

    private let api: PostProcessingAPI

    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest  = 30
        config.timeoutIntervalForResource = 90
        return URLSession(configuration: config)
    }()

    init(api: PostProcessingAPI = .openAI) {
        self.api = api
    }

    func process(text: String, prompt: String, apiKey: String) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw PostProcessorError.missingAPIKey
        }
        guard !prompt.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw PostProcessorError.emptyPrompt
        }

        switch api {
        case .openAI:
            return try await callOpenAI(text: text, systemPrompt: prompt, apiKey: apiKey)
        case .claude:
            return try await callClaude(text: text, systemPrompt: prompt, apiKey: apiKey)
        }
    }

    // MARK: - OpenAI

    private func callOpenAI(text: String, systemPrompt: String, apiKey: String) async throws -> String {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            preconditionFailure("Invalid OpenAI endpoint URL")
        }

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user",   "content": text]
            ],
            "max_tokens": 2048
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response) = try await session.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw PostProcessorError.httpError(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }

        return try extractOpenAIContent(from: data)
    }

    private func extractOpenAIContent(from data: Data) throws -> String {
        struct Response: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable { let content: String }
                let message: Message
            }
            let choices: [Choice]
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        let content = decoded.choices.first?.message.content
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !content.isEmpty else { throw PostProcessorError.emptyResponse }
        return content
    }

    // MARK: - Anthropic Claude

    private func callClaude(text: String, systemPrompt: String, apiKey: String) async throws -> String {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            preconditionFailure("Invalid Claude endpoint URL")
        }

        let body: [String: Any] = [
            "model": "claude-haiku-4-5",
            "max_tokens": 2048,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": text]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response) = try await session.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw PostProcessorError.httpError(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }

        return try extractClaudeContent(from: data)
    }

    private func extractClaudeContent(from data: Data) throws -> String {
        struct Response: Decodable {
            struct Content: Decodable {
                let type: String
                let text: String?
            }
            let content: [Content]
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        let content = decoded.content
            .first(where: { $0.type == "text" })?.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !content.isEmpty else { throw PostProcessorError.emptyResponse }
        return content
    }
}
