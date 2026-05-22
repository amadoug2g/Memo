import Foundation
import AVFoundation

// MARK: - Protocol

/// Abstracts the audio recording pipeline for testability.
/// Injected into `AppState` at init time.
protocol AudioRecording: AnyObject {
    var onLevelUpdate: ((Float) -> Void)? { get set }
    func requestPermission(completion: @escaping (Bool) -> Void)
    /// Pre-warms the recorder so the next `startRecording()` call is instant.
    /// Safe to call multiple times — no-ops if already prepared.
    func prepareToRecord()
    func startRecording() throws
    func stopRecording() async throws -> URL
    func cancelRecording()
}

// MARK: - Errors

enum AudioRecorderError: LocalizedError {
    case permissionDenied
    case alreadyRecording
    case setupFailed(Error)
    case encodingFailed(Error?)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone access denied. Enable it in System Settings › Privacy & Security › Microphone."
        case .alreadyRecording:
            return "A recording is already in progress."
        case .setupFailed(let err):
            return "Audio setup failed: \(err.localizedDescription)"
        case .encodingFailed(let err):
            let detail = err?.localizedDescription ?? "unknown error"
            return "Audio encoding failed: \(detail)"
        }
    }
}

// MARK: - Implementation

class AudioRecorder: NSObject, AVAudioRecorderDelegate, AudioRecording {
    private var recorder: AVAudioRecorder?
    private var outputURL: URL?
    private var levelTimer: Timer?
    private var encodeError: Error?

    var onLevelUpdate: ((Float) -> Void)?

    // Shared settings — medium quality is indistinguishable to Whisper at 16kHz
    // and produces ~20% smaller files, reducing upload time on slow connections.
    private let recordingSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 16_000,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
    ]

    // MARK: - Permissions

    func requestPermission(completion: @escaping (Bool) -> Void) {
        AudioRecorder.requestPermission(completion: completion)
    }

    static func requestPermission(completion: @escaping (Bool) -> Void) {
        if #available(macOS 14, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                completion(true)
            case .undetermined:
                AVAudioApplication.requestRecordPermission { granted in
                    completion(granted)
                }
            case .denied:
                completion(false)
            @unknown default:
                completion(false)
            }
        } else {
            switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized:
                completion(true)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .audio, completionHandler: completion)
            default:
                completion(false)
            }
        }
    }

    // MARK: - Pre-warming

    /// Builds the AVAudioRecorder and calls `prepareToRecord()` so buffer
    /// allocation happens before the user presses the hotkey. Calling
    /// `startRecording()` after this just calls `.record()` — near-zero latency.
    func prepareToRecord() {
        guard recorder == nil else { return }
        try? buildRecorder()
    }

    // MARK: - Recording

    func startRecording() throws {
        let isGranted: Bool
        if #available(macOS 14, *) {
            isGranted = AVAudioApplication.shared.recordPermission == .granted
        } else {
            isGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        }
        guard isGranted else {
            throw AudioRecorderError.permissionDenied
        }

        // If already pre-warmed, skip allocation and go straight to record.
        if recorder == nil {
            try buildRecorder()
        }

        recorder?.record()
        startLevelTimer()
    }

    /// Stops recording and returns the URL of the recorded file.
    /// `AVAudioRecorder.stop()` is synchronous, so no continuation is needed.
    func stopRecording() async throws -> URL {
        levelTimer?.invalidate()
        levelTimer = nil
        // This method is called from a non-@MainActor Task, so we cannot use
        // assumeIsolated. Dispatch the level reset explicitly to main.
        let update = onLevelUpdate
        DispatchQueue.main.async { update?(0) }

        recorder?.stop()
        recorder = nil

        defer {
            outputURL = nil
            encodeError = nil
        }

        if let err = encodeError {
            throw AudioRecorderError.encodingFailed(err)
        }
        guard let url = outputURL else {
            throw AudioRecorderError.encodingFailed(nil)
        }
        return url
    }

    /// Stops recording and discards the audio file — for cancellations and short taps.
    func cancelRecording() {
        levelTimer?.invalidate()
        levelTimer = nil
        onLevelUpdate?(0)

        recorder?.stop()
        recorder = nil

        if let url = outputURL {
            try? FileManager.default.removeItem(at: url)
        }
        outputURL = nil
        encodeError = nil
    }

    // MARK: - AVAudioRecorderDelegate

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        levelTimer?.invalidate()
        levelTimer = nil
        encodeError = error
        self.recorder = nil
    }

    // MARK: - Private

    private func buildRecorder() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        let rec = try AVAudioRecorder(url: url, settings: recordingSettings)
        rec.delegate = self
        rec.isMeteringEnabled = true
        rec.prepareToRecord()   // pre-allocates codec buffers

        recorder = rec
        outputURL = url
        encodeError = nil
    }

    private func startLevelTimer() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let rec = self.recorder, rec.isRecording else { return }
            rec.updateMeters()
            let dB = rec.averagePower(forChannel: 0)
            let normalized = Float(max(0.0, (dB + 60.0) / 60.0))
            self.onLevelUpdate?(normalized)
        }
    }
}
