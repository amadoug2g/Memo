import SwiftUI

// MARK: - Root view

struct TranscriptionView: View {
    @EnvironmentObject var appState: AppState
    @FocusState private var editorFocused: Bool
    @State private var transcribingElapsed: Int = 0
    @State private var transcribingTimer: Timer?
    @State private var isVisible = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isCompact: Bool {
        appState.isRecording || appState.isTranscribing
    }

    var body: some View {
        Group {
            if isCompact {
                compactBody
            } else {
                fullBody
            }
        }
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.95, anchor: .bottom)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: appState.recordingState)
        .onAppear {
            if reduceMotion {
                isVisible = true
            } else {
                withAnimation(.easeOut(duration: 0.12)) { isVisible = true }
            }
        }
        .onChange(of: appState.recordingState) { state in
            if state == .editing { editorFocused = true }
        }
    }

    // MARK: - Compact pill (recording / transcribing)

    private var compactBody: some View {
        HStack(spacing: 6) {
            if appState.isRecording {
                WaveformView(level: appState.audioLevel)
            } else {
                ProgressView()
                    .scaleEffect(0.55)
                    .frame(width: 14, height: 14)
                if transcribingElapsed >= 2 {
                    Text("\(transcribingElapsed)s")
                        .font(.system(size: 10, weight: .medium).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            reduceTransparency
                ? AnyShapeStyle(Color(NSColor.windowBackgroundColor))
                : AnyShapeStyle(.ultraThinMaterial),
            in: Capsule()
        )
        .shadow(color: Color.primary.opacity(0.12), radius: 8, y: 3)
        .fixedSize()  // Tell NSHostingView: this is the exact size, don't expand
        .onAppear {
            if appState.isTranscribing { startTranscribingTimer() }
        }
        .onDisappear { stopTranscribingTimer() }
        .onChange(of: appState.isTranscribing) { transcribing in
            if transcribing { startTranscribingTimer() }
            else { stopTranscribingTimer() }
        }
    }

    // MARK: - Full panel (editing / error)

    private var fullBody: some View {
        VStack(spacing: 0) {
            if appState.isEditing {
                editingContent
                Divider()
                footer
            } else if case .error(let message) = appState.recordingState {
                errorContent(message)
            }
        }
        .background(
            reduceTransparency
                ? AnyShapeStyle(Color(NSColor.windowBackgroundColor))
                : AnyShapeStyle(.ultraThinMaterial),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .frame(width: 400)
        .shadow(color: Color.primary.opacity(0.15), radius: 16, y: 5)
    }

    // MARK: - Editing

    private var editingContent: some View {
        TextEditor(text: $appState.transcribedText)
            .focused($editorFocused)
            .font(.system(.body, design: .rounded))
            .scrollContentBackground(.hidden)
            .padding(16)
            .frame(minHeight: 72, maxHeight: 140)
            .accessibilityLabel("Transcription")
            .accessibilityHint("Edit text before pasting into the active application")
    }

    // MARK: - Error

    private func errorContent(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .imageScale(.medium)
                    .accessibilityHidden(true)
                Text(message)
                    .font(.system(.callout, design: .rounded))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("Press ⌥ Space to try again")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 6) {
            if appState.postProcessingEnabled {
                polishButton
            }
            Spacer()
            Button("Paste") { appState.confirmAndPaste() }
                .accessibilityLabel("Paste")
                .accessibilityHint("Pastes the transcribed text into the previously active application")
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(appState.transcribedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Polish button (AI post-processing on demand)

    @ViewBuilder
    private var polishButton: some View {
        if appState.isPostProcessing {
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 14, height: 14)
                Text("Polishing…")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Applying AI post-processing")
        } else {
            Button {
                appState.applyPostProcessing()
            } label: {
                Label("Polish", systemImage: "wand.and.sparkles")
                    .font(.system(size: 11))
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Apply AI post-processing")
            .accessibilityHint("Rewrites the transcription using the selected AI prompt")
            .disabled(appState.transcribedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                      || appState.isPostProcessing)
        }
    }

    // MARK: - Timer helpers

    private func startTranscribingTimer() {
        transcribingElapsed = 0
        transcribingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            transcribingElapsed += 1
        }
    }

    private func stopTranscribingTimer() {
        transcribingTimer?.invalidate()
        transcribingTimer = nil
        transcribingElapsed = 0
    }
}

// MARK: - WaveformView

struct WaveformView: View {
    var level: Float

    private let barCount = 5
    @State private var phases: [Double]
    @State private var glowPulse: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(level: Float) {
        self.level = level
        _phases = State(initialValue: (0..<5).map { Double($0) * 0.5 })
    }

    private let timer = Timer.publish(every: 0.07, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<barCount, id: \.self) { barIndex in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.red.opacity(barOpacity(for: barIndex)))
                    .frame(width: 3, height: reduceMotion ? 8 : barHeight(for: barIndex))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.07), value: barHeight(for: barIndex))
            }
        }
        .frame(height: 20)
        .padding(6)
        .background(
            Color.red.opacity(reduceMotion ? 0 : (glowPulse ? 0.18 : 0.06)),
            in: Capsule()
        )
        .shadow(
            color: Color.red.opacity(reduceMotion ? 0 : (glowPulse ? 0.45 : 0.15)),
            radius: glowPulse ? 8 : 4
        )
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.75).repeatForever(autoreverses: true),
            value: glowPulse
        )
        .accessibilityHidden(true)
        .onAppear {
            if !reduceMotion { glowPulse = true }
        }
        .onReceive(timer) { _ in
            if !reduceMotion {
                for barIndex in 0..<barCount { phases[barIndex] += 0.3 }
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let base: CGFloat = 3
        let peak: CGFloat = 18
        let envelope = CGFloat(level)
        let wave = CGFloat((sin(phases[index]) + 1) / 2)
        let idleHeight = base + (peak * 0.12) * wave
        return envelope > 0.02
            ? base + (peak - base) * envelope * (0.5 + 0.5 * wave)
            : idleHeight
    }

    private func barOpacity(for index: Int) -> Double {
        let centre = Double(barCount - 1) / 2
        let dist = abs(Double(index) - centre) / centre
        return 0.9 - dist * 0.25
    }
}
