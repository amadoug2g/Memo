import Foundation

// MARK: - Protocol

protocol Transcribing: AnyObject {
    func transcribe(audioURL: URL, apiKey: String, language: String?) async throws -> String
}

// MARK: - Errors

enum WhisperError: LocalizedError {
    case missingAPIKey
    case httpError(Int, String)
    case emptyResponse
    case timeout

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is not set. Open Settings (menubar icon → Settings…) to add it."
        case .httpError(let code, let body):
            if let data = body.data(using: .utf8),
               let json = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                return "API error \(code): \(json.error.message)"
            }
            return "API error \(code): \(body)"
        case .emptyResponse:
            return "The API returned an empty transcription."
        case .timeout:
            return "Transcription timed out — the server took too long to respond. Please try again."
        }
    }
}

private struct OpenAIErrorResponse: Decodable {
    struct ErrorBody: Decodable { let message: String }
    let error: ErrorBody
}

class WhisperService: Transcribing {
    private let endpoint: URL = {
        guard let url = URL(string: "https://api.openai.com/v1/audio/transcriptions") else {
            preconditionFailure("Invalid hardcoded URL for Whisper API endpoint")
        }
        return url
    }()

    private let session: URLSession
    private let maxAttempts: Int
    private let baseRetryDelay: TimeInterval

    init(session: URLSession? = nil, maxAttempts: Int = 3, baseRetryDelay: TimeInterval = 2.0) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest  = 120
            config.timeoutIntervalForResource = 300
            self.session = URLSession(configuration: config)
        }
        self.maxAttempts = maxAttempts
        self.baseRetryDelay = baseRetryDelay
    }

    func transcribe(audioURL: URL, apiKey: String, language: String?) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw WhisperError.missingAPIKey
        }

        let audioData = try Data(contentsOf: audioURL)
        let boundary = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = buildMultipartBody(
            audioData: audioData,
            filename: audioURL.lastPathComponent,
            language: language,
            boundary: boundary
        )

        var lastError: Error = WhisperError.timeout
        for attempt in 1...maxAttempts {
            do {
                let (data, response) = try await session.data(for: request)

                if let http = response as? HTTPURLResponse {
                    if http.statusCode == 200 {
                        let text = (String(data: data, encoding: .utf8) ?? "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { throw WhisperError.emptyResponse }
                        return text
                    }
                    if http.statusCode >= 500 {
                        lastError = WhisperError.httpError(http.statusCode, String(data: data, encoding: .utf8) ?? "")
                        if attempt < maxAttempts {
                            try await Task.sleep(nanoseconds: UInt64(baseRetryDelay * 1_000_000_000) * UInt64(1 << (attempt - 1)))
                            continue
                        }
                        throw lastError
                    }
                    throw WhisperError.httpError(http.statusCode, String(data: data, encoding: .utf8) ?? "")
                }
            } catch let error as WhisperError {
                throw error
            } catch let urlError as URLError where urlError.code == .timedOut || urlError.code == .networkConnectionLost {
                lastError = WhisperError.timeout
                if attempt < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(baseRetryDelay * 1_000_000_000) * UInt64(1 << (attempt - 1)))
                    continue
                }
            }
        }
        throw lastError
    }

    // MARK: - Multipart body

    private func buildMultipartBody(
        audioData: Data,
        filename: String,
        language: String?,
        boundary: String
    ) -> Data {
        var body = Data()

        body.appendField(name: "model", value: "gpt-4o-mini-transcribe", boundary: boundary)
        body.appendField(name: "response_format", value: "text", boundary: boundary)
        if let lang = language, !lang.isEmpty {
            body.appendField(name: "language", value: lang, boundary: boundary)
        }
        body.appendFile(
            name: "file",
            filename: filename,
            mimeType: "audio/m4a",
            data: audioData,
            boundary: boundary
        )
        body.append("--\(boundary)--\r\n")

        return body
    }
}

// MARK: - Data helpers

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) { append(data) }
    }

    mutating func appendField(name: String, value: String, boundary: String) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        append("\(value)\r\n")
    }

    mutating func appendFile(name: String, filename: String, mimeType: String, data: Data, boundary: String) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        append("Content-Type: \(mimeType)\r\n\r\n")
        append(data)
        append("\r\n")
    }
}
