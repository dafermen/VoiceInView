import SwiftUI
import UIKit

@MainActor
struct CaptionScreen: View {
    @Bindable var model: CaptionViewModel
    @Bindable var settings: AppSettings
    var newSession: (() async -> Void)? = nil
    var saveSession: (() -> Void)? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title) private var scaledSize: CGFloat = 28
    @State private var visibleFinalCount = 300
    @State private var followLive = true
    @State private var confirmNewSession = false
    @State private var showingOptions = false
    @State private var showingStatus = false
    @State private var showingActions = false

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.width > geometry.size.height && !dynamicTypeSize.isAccessibilitySize
            VStack(spacing: 0) {
                if !compact {
                    HStack {
                        status
                        Spacer(minLength: 8)
                        utilities
                    }
                    .padding(.horizontal, 16)
                }
                if let message = statusMessage {
                    Button { showingStatus = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: isProblem || model.permissionDenied ? "exclamationmark.circle" : "info.circle")
                            Text(message).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "chevron.right").font(.caption)
                        }
                        .font(.subheadline).padding(.horizontal, 16).frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .accessibilityLabel(message + ". Show details")
                    .accessibilityIdentifier("captionStatusDetails")
                }
                transcript
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Divider()
                HStack(spacing: 12) {
                    if compact { status; Spacer(minLength: 0) }
                    captureControls
                    if compact { utilities }
                }
                .padding(.horizontal, 16).padding(.vertical, 6)
                .background(.bar)
            }
        }
        .navigationTitle("VoiceInView")
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingOptions) { readingOptions }
        .sheet(isPresented: $showingStatus) { statusDetails }
        .confirmationDialog("Session actions", isPresented: $showingActions, titleVisibility: .visible) {
            if let saveSession {
                Button("Save Session", action: saveSession)
                    .disabled(model.transcript.finalized.isEmpty)
            }
            Button("New Session", role: .destructive) { Task { await beginNewSession() } }
                .disabled(model.state.active || model.state.busy || model.preparationPending)
            Button("Session information") { showingStatus = true }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Starting a new session clears any unsaved captions.")
        }
        .confirmationDialog("Start a new session? Any captions that have not been saved will be cleared.",
                            isPresented: $confirmNewSession, titleVisibility: .visible) {
            Button("New Session", role: .destructive) {
                Task { await beginNewSession() }
            }
        }
        .task { await model.checkReadiness() }
        .onChange(of: model.state) { _, _ in applyWakePreference() }
        .onChange(of: settings.keepAwake) { _, _ in applyWakePreference() }
        .onAppear { applyWakePreference() }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    private var status: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(statusTitle, systemImage: model.state == .listening ? "mic.fill" : "mic")
                .font(.subheadline.weight(.semibold))
                .accessibilityLabel(model.state.title)
                .accessibilityIdentifier("listeningStatus")
            TimelineView(.periodic(from: Date(), by: 1)) { context in
                Text(SessionClock.format(model.currentDuration(at: context.date)))
                    .font(.caption).monospacedDigit().foregroundStyle(.secondary)
                    .accessibilityLabel("Listening time")
                    .accessibilityValue(SessionClock.format(model.currentDuration(at: context.date)))
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(minHeight: 44)
    }

    private var utilities: some View {
        HStack(spacing: 4) {
            Button { showingOptions = true } label: {
                Image(systemName: "textformat.size").frame(width: 44, height: 44)
            }
            .accessibilityLabel("Reading options")
            .accessibilityIdentifier("readingOptionsButton")
            Button { showingActions = true } label: {
                Image(systemName: "ellipsis.circle").frame(width: 44, height: 44)
            }
            .accessibilityLabel("Session actions")
            .accessibilityIdentifier("sessionActionsButton")
        }
    }

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    if model.transcript.finalized.isEmpty && model.transcript.partial.isEmpty {
                        Text("Live English captions will appear here.")
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("captionPlaceholder")
                    }
                    if model.transcript.finalized.count > visibleFinalCount {
                        Button("Load Earlier Captions") {
                            followLive = false
                            visibleFinalCount += 300
                        }
                        .font(.body).frame(minHeight: 44)
                    }
                    ForEach(model.transcript.finalized.suffix(visibleFinalCount)) { segment in
                        Text(segment.text).textSelection(.enabled)
                    }
                    ForEach(model.transcript.partial) { segment in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Unfinished").font(.caption)
                            Text(segment.text).italic()
                        }
                    }
                    Color.clear.frame(height: 1).id("liveBottom")
                }
                .font(.system(size: scaledSize * CGFloat(settings.captionSize) / 28))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            }
            .accessibilityIdentifier("captionScrollView")
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !followLive && hasCaptions {
                    Button { followLive = true } label: {
                        Label("Back to live", systemImage: "arrow.down.to.line")
                            .font(.subheadline).frame(minHeight: 44).padding(.horizontal, 12)
                    }
                    .background(.regularMaterial, in: Capsule()).padding(.bottom, 4)
                }
            }
            .onChange(of: model.transcript.finalized.count) { _, _ in scrollToLive(proxy) }
            .onChange(of: model.transcript.partial) { _, _ in scrollToLive(proxy) }
            .onChange(of: followLive) { _, enabled in if enabled { proxy.scrollTo("liveBottom", anchor: .bottom) } }
        }
    }

    private var captureControls: some View {
        HStack(spacing: 12) {
            Button {
                if model.state == .ended { confirmNewSession = true }
                else { Task { if model.state == .listening { await model.pause() } else { await model.start() } } }
            } label: {
                Label(primaryTitle, systemImage: primaryIcon)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("primaryCaptionAction")
            .disabled(model.state.busy || model.preparationPending)
            Button { Task { await model.stop() } } label: {
                Label("Stop", systemImage: "stop.fill").frame(minHeight: 44)
            }
            .buttonStyle(.bordered)
            .disabled(model.state == .stopping || (!model.state.active && model.state != .paused && !isProblem))
        }
        .font(.body.weight(.semibold))
    }

    private var readingOptions: some View {
        NavigationStack {
            Form {
                Section("Text size") {
                    Text("Make every word easy to read.")
                        .font(.system(size: scaledSize * CGFloat(settings.captionSize) / 28))
                    Slider(value: $settings.captionSize, in: 20...44, step: 2)
                        .accessibilityLabel("Caption size")
                        .accessibilityValue("\(Int(settings.captionSize)) points")
                }
                Section {
                    Toggle("Follow live captions", isOn: $followLive)
                    Toggle("Keep screen awake while listening", isOn: $settings.keepAwake)
                } footer: {
                    Text("Turn off Follow live captions to read earlier text at your own pace.")
                }
                Section {
                    Text(settings.autoSave ? "Final captions save on this iPhone." : "Use Session actions → Save Session to keep your captions.")
                }
            }
            .navigationTitle("Reading options").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showingOptions = false } } }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var statusDetails: some View {
        NavigationStack {
            Form {
                if case .problem(let message) = model.state {
                    Section("Capture problem") { Text(message).accessibilityIdentifier("captureError") }
                }
                if let notice = model.notice { Section("Notice") { Text(notice) } }
                Section("Speech recognition") {
                    Text(model.readiness.description)
                    if model.readiness == .authorizationRequired {
                        Button("Allow Speech Recognition") { Task { await model.requestSpeechPermission() } }
                            .disabled(model.state.active || model.state.busy || model.preparationPending)
                    }
                    if model.readiness == .missingAssets {
                        Button("Install English Model (Internet required)") { Task { await model.installAssets() } }
                            .disabled(model.state.active || model.state.busy || model.preparationPending)
                    }
                    if model.permissionDenied || model.readiness == .authorizationDenied {
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        }
                    }
                }
                Section("Privacy and saving") {
                    Text(settings.autoSave ? "Final captions save on this iPhone." : "Captions are unsaved until you tap Save Session in Session actions.")
                    Text("On-device English captions. Accuracy varies with distance, noise and speech.")
                }
            }
            .navigationTitle("Session information").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showingStatus = false } } }
        }
    }

    private var statusMessage: String? {
        if case .problem(let message) = model.state { return message }
        if model.permissionDenied { return "Microphone access needed" }
        switch model.readiness {
        case .ready: break
        case .checking: return "Checking speech recognition…"
        case .authorizationRequired: return "Enable speech recognition"
        case .authorizationDenied: return "Speech recognition access needed"
        case .authorizationRestricted: return "Speech recognition is restricted"
        case .missingAssets, .systemModelUnavailable: return "English speech model needed"
        case .downloading: return "Installing English speech model…"
        case .unsupportedDevice, .unsupportedLanguage: return "On-device English unavailable"
        case .problem: return "Speech recognition needs attention"
        }
        if let notice = model.notice { return notice }
        if !settings.autoSave && hasCaptions { return "Auto-save is off · Save from Session actions" }
        return nil
    }

    private var statusTitle: String {
        switch model.state {
        case .idle: return "Ready"
        case .preparing: return "Preparing"
        case .listening: return "Listening"
        case .stopping: return "Finishing"
        default: return model.state.title
        }
    }

    private var primaryTitle: String {
        switch model.state {
        case .listening: return "Pause"
        case .paused, .problem: return "Resume"
        case .preparing: return "Preparing…"
        case .stopping: return "Finishing…"
        case .ended: return "New Session"
        case .idle: return "Start Listening"
        }
    }

    private var primaryIcon: String {
        switch model.state {
        case .listening: return "pause.fill"
        case .paused, .problem: return "play.fill"
        case .ended: return "plus"
        default: return "mic.fill"
        }
    }

    private var hasCaptions: Bool { !model.transcript.finalized.isEmpty || !model.transcript.partial.isEmpty }
    private var isProblem: Bool { if case .problem = model.state { true } else { false } }

    private func beginNewSession() async {
        if let newSession { await newSession() } else { await model.reset() }
        visibleFinalCount = 300
        followLive = true
    }

    private func applyWakePreference() {
        UIApplication.shared.isIdleTimerDisabled = settings.keepAwake && model.state == .listening
    }

    private func scrollToLive(_ proxy: ScrollViewProxy) {
        guard followLive else { return }
        if reduceMotion { proxy.scrollTo("liveBottom", anchor: .bottom) }
        else { withAnimation(.easeOut(duration: 0.15)) { proxy.scrollTo("liveBottom", anchor: .bottom) } }
    }
}
