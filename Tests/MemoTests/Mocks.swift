import Foundation
import XCTest
@testable import Memo

// MARK: - MockURLProtocol

final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responses: [(error: Error?, data: Data?, statusCode: Int?)] = []
    nonisolated(unsafe) static var requestCount = 0

    static func reset() {
        responses = []
        requestCount = 0
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let index = min(Self.requestCount, Self.responses.count - 1)
        Self.requestCount += 1
        let entry = Self.responses[index]

        if let error = entry.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        let statusCode = entry.statusCode ?? 200
        let url = request.url ?? URL(string: "https://mock.test")!
        let httpResponse = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: nil)!
        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
        if let data = entry.data {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

func makeMockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    config.timeoutIntervalForRequest = 120
    config.timeoutIntervalForResource = 300
    return URLSession(configuration: config)
}

// MARK: - MockAudioRecorder

final class MockAudioRecorder: AudioRecording {
    var onLevelUpdate: ((Float) -> Void)?

    // Configuration
    var permissionGranted = true
    var startError: Error?
    var stopResult: Result<URL, Error> = .success(URL(fileURLWithPath: "/dev/null"))

    // Spies
    private(set) var prepareCallCount = 0
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var cancelCallCount = 0

    func requestPermission(completion: @escaping (Bool) -> Void) {
        completion(permissionGranted)
    }

    func prepareToRecord() {
        prepareCallCount += 1
    }

    func startRecording() throws {
        startCallCount += 1
        if let err = startError { throw err }
    }

    func stopRecording() async throws -> URL {
        stopCallCount += 1
        return try stopResult.get()
    }

    func cancelRecording() {
        cancelCallCount += 1
    }
}

// MARK: - MockTranscriber

final class MockTranscriber: Transcribing {
    var result: Result<String, Error> = .success("Hello world")
    private(set) var callCount = 0

    func transcribe(audioURL: URL, apiKey: String, language: String?) async throws -> String {
        callCount += 1
        return try result.get()
    }
}
