import SwiftUI
import UIKit

@MainActor
struct CaptionScreen: View {
    @Bindable var model: CaptionViewModel
    @Bindable var settings: AppSettings
    var newSession: (() async -> Void)? = nil
    var saveSession: (() -> Void)? = nil
    var bookmarkSegment: ((CaptionSegment) -> Void)? = nil
    var showBookmarks: (() -> Void)? = nil
    var bookmarkedIDs: Set<UUID> = []
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title) private var scaledSize: CGFloat = 28
    @State private var readingStartID: UUID?
    @State private var isFullScreen = false
    @State private var followLive = true
    @State private var confirmNewSession = false
    @State private var showingOptions = false
    @State private var showingStatus = false
    @State private var showingActions = false

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.width > geometry.size.height && !dynamicTypeSize.isAccessibilitySize
            VStack(spacing: 0) {
                if !compact && !isFullScreen {
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
                if isFullScreen || compact || model.state != .ended {
                    Divider()
                    HStack(spacing: 8) {
                        if isFullScreen {
                            status
                            Spacer(minLength: 0)
                            primaryButton(iconOnly: true)
                            if model.state != .ended { stopButton(iconOnly: true) }
                            fullScreenButton
                        } else {
                            if compact { status; Spacer(minLength: 0) }
                            if model.state != .ended { captureControls }
                            if compact { utilities }
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 6)
                    .background(.bar)
                }
            }
        }
        .navigationTitle("VoiceInView")
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(isFullScreen ? .hidden : .visible, for: .tabBar)
        .statusBarHidden(isFullScreen)
        .sheet(isPresented: $showingOptions) { readingOptions }
        .sheet(isPresented: $showingStatus) { statusDetails }
        .confirmationDialog("Session actions", isPresented: $showingActions, titleVisibility: .visible) {
            if let saveSession {
                Button("Save Session", action: saveSession)
                    .disabled(model.transcript.finalized.isEmpty)
            }
            Button("New Session", role: .destructive) { Task { await beginNewSession() } }
                .disabled(model.state.active || model.state.busy || model.preparationPending)
            if let showBookmarks { Button("Bookmarks", action: showBookmarks) }
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
        HStack(spacing: 0) {
            if model.state == .ended { newSessionButton }
            fullScreenButton
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

    private var fullScreenButton: some View {
        Button { isFullScreen.toggle() } label: {
            Image(systemName: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel(isFullScreen ? "Exit full screen" : "Full screen")
        .accessibilityIdentifier("fullScreenButton")
    }

    private var firstVisibleIndex: Int {
        if followLive { return max(0, model.transcript.finalized.count - 300) }
        guard let readingStartID else { return 0 }
        return model.transcript.finalized.firstIndex { $0.id == readingStartID } ?? 0
    }

    private var followBinding: Binding<Bool> {
        Binding(get: { followLive }, set: { enabled in
            if enabled { followLive = true } else { pauseFollowing() }
        })
    }

    private func pauseFollowing() {
        guard followLive else { return }
        readingStartID = model.transcript.finalized.dropFirst(firstVisibleIndex).first?.id
        followLive = false
    }

    private var captionFont: Font {
        .system(size: scaledSize * CGFloat(settings.captionSize) / 28,
                weight: settings.boldCaptions ? .semibold : .regular)
    }

    private var transcript: some View {
        ScrollViewReader { proxy in
            GeometryReader { viewport in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        if !hasCaptions {
                            Text("Live English captions will appear here.")
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("captionPlaceholder")
                        }
                        if firstVisibleIndex > 0 {
                            Button("Load Earlier Captions") {
                                let index = max(0, firstVisibleIndex - 300)
                                pauseFollowing()
                                readingStartID = model.transcript.finalized[index].id
                            }
                            .font(.body).frame(minHeight: 44)
                        }
                        ForEach(model.transcript.finalized.dropFirst(firstVisibleIndex)) { segment in
                            VStack(alignment: .leading, spacing: 4) {
                                if bookmarkedIDs.contains(segment.id) {
                                    Label("Bookmarked", systemImage: "bookmark.fill").font(.caption)
                                }
                                Text(segment.text).textSelection(.enabled)
                                    .accessibilityIdentifier("caption-" + segment.id.uuidString)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contextMenu {
                                if let bookmarkSegment {
                                    Button(bookmarkedIDs.contains(segment.id) ? "Remove bookmark" : "Save bookmark",
                                           systemImage: "bookmark") { bookmarkSegment(segment) }
                                }
                            }
                            .accessibilityAction(named: "Toggle bookmark") { bookmarkSegment?(segment) }
                        }
                        // A single stable container avoids replacing the entire provisional view
                        // whenever the recognizer revises its audio range or identifier.
                        if !model.transcript.partial.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Live · may change").font(.caption)
                                Text(model.transcript.partial.map(\.text).joined(separator: "\n"))
                                    .accessibilityIdentifier("provisionalCaption")
                            }
                            .id("provisionalCaption")
                        }
                        Color.clear.frame(height: 1).id("liveBottom")
                    }
                    .font(captionFont)
                    .lineSpacing(settings.lineSpacing)
                    .frame(maxWidth: .infinity, minHeight: max(0, viewport.size.height - 32), alignment: .topLeading)
                    .padding(16)
                    .transaction { $0.animation = nil }
                }
                .defaultScrollAnchor(followLive ? .bottom : nil)
                .foregroundStyle(settings.highContrast ? (colorScheme == .dark ? Color.white : Color.black) : Color.primary)
                .background(settings.highContrast ? (colorScheme == .dark ? Color.black : Color.white) : Color(uiColor: .systemBackground))
                .accessibilityIdentifier("captionScrollView")
                .accessibilityValue("\(model.transcript.finalized.count) finished paragraphs. " +
                                    (followLive ? "Following live captions" : "Reading earlier captions"))
                .simultaneousGesture(DragGesture(minimumDistance: 10).onChanged { value in
                    if hasCaptions && value.translation.height > 10 && value.translation.height > abs(value.translation.width) {
                        pauseFollowing()
                    }
                })
                .accessibilityAction(named: "Read earlier captions") { pauseFollowing() }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if !followLive && hasCaptions {
                        Button { followLive = true } label: {
                            Label("Back to live", systemImage: "arrow.down.to.line")
                                .font(.subheadline).frame(minHeight: 44).padding(.horizontal, 12)
                        }
                        .accessibilityIdentifier("backToLiveButton")
                        .background(.regularMaterial, in: Capsule()).padding(.bottom, 4)
                    }
                }
                .onChange(of: model.transcript.finalized) { _, _ in scrollToLive(proxy) }
                .onChange(of: model.transcript.partial) { _, _ in scrollToLive(proxy) }
                .onChange(of: followLive) { _, enabled in if enabled { scrollToLive(proxy) } }
                .onChange(of: isFullScreen) { _, _ in scrollToLive(proxy) }
            }
        }
    }

    private var captureControls: some View {
        HStack(spacing: 8) {
            primaryButton(iconOnly: false)
            stopButton(iconOnly: false)
        }
        .font(.body.weight(.semibold))
    }

    private var newSessionButton: some View {
        Button { confirmNewSession = true } label: {
            Image(systemName: "plus").font(.title3.weight(.semibold))
                .frame(width: 44, height: 44).foregroundStyle(.white)
                .background(Color.accentColor, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("New Session").accessibilityIdentifier("primaryCaptionAction")
    }

    @ViewBuilder private func primaryButton(iconOnly: Bool) -> some View {
        if model.state == .ended {
            newSessionButton
        } else {
            Button {
                Task { if model.state == .listening { await model.pause() } else { await model.start() } }
            } label: {
                Group {
                    if iconOnly { Image(systemName: primaryIcon).frame(width: 44, height: 44) }
                    else { Label(primaryTitle, systemImage: primaryIcon).frame(maxWidth: .infinity, minHeight: 44) }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel(primaryTitle)
            .accessibilityIdentifier("primaryCaptionAction")
            .disabled(model.state.busy || model.preparationPending)
        }
    }

    private func stopButton(iconOnly: Bool) -> some View {
        Button { Task { await model.stop() } } label: {
            Group {
                if iconOnly { Image(systemName: "stop.fill").frame(width: 44, height: 44) }
                else { Label("Stop", systemImage: "stop.fill").frame(minHeight: 44) }
            }
        }
        .buttonStyle(.bordered)
        .accessibilityLabel("Stop")
        .disabled(model.state == .stopping || (!model.state.active && model.state != .paused && !isProblem))
    }

    private var readingOptions: some View {
        NavigationStack {
            Form {
                Section("Text size") {
                    Text("Make every word easy to read.")
                        .font(captionFont)
                        .lineSpacing(settings.lineSpacing)
                    Slider(value: $settings.captionSize, in: 20...44, step: 2)
                        .accessibilityLabel("Caption size")
                        .accessibilityValue("\(Int(settings.captionSize)) points")
                }
                Section("Reading style") {
                    Slider(value: $settings.lineSpacing, in: 0...16, step: 2) {
                        Text("Line spacing")
                    }
                    .accessibilityLabel("Line spacing")
                    .accessibilityValue("\(Int(settings.lineSpacing)) points")
                    Toggle("Bold text", isOn: $settings.boldCaptions)
                    Toggle("High contrast", isOn: $settings.highContrast)
                }
                Section {
                    Toggle("Follow live captions", isOn: followBinding)
                    Toggle("Keep screen awake while listening", isOn: $settings.keepAwake)
                } footer: {
                    Text("Scroll back to reread without interrupting listening. Tap Back to live to follow again.")
                }
                Section {
                    Text(settings.autoSave ? "Final captions save on this iPhone." : "Use Session actions → Save Session to keep your captions.")
                    Text("Touch and hold a finished paragraph to save a bookmark. Bookmarks also save the current session on this iPhone.")
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
        readingStartID = nil
        followLive = true
    }

    private func applyWakePreference() {
        UIApplication.shared.isIdleTimerDisabled = settings.keepAwake && model.state == .listening
    }

    private func scrollToLive(_ proxy: ScrollViewProxy) {
        guard followLive else { return }
        // Do not repeatedly animate provisional word revisions.
        proxy.scrollTo("liveBottom", anchor: .bottom)
    }
}
