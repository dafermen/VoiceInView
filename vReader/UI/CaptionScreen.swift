import SwiftUI
import UIKit

struct CaptionScreen: View {
    @Bindable var model: CaptionViewModel
    @Bindable var settings: AppSettings = AppSettings()
    var newSession: (() async -> Void)? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title) private var scaledSize = 28
    @State private var followLive = true
    @State private var confirmNewSession = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(model.state.title, systemImage: model.state == .listening ? "mic.fill" : "mic")
                    .font(.headline)
                    .accessibilityIdentifier("listeningStatus")
                Spacer()
                TimelineView(.periodic(from: Date(), by: 1)) { context in
                    Text(SessionClock.format(model.currentDuration(at: context.date)))
                        .monospacedDigit().accessibilityLabel("Listening time")
                }
            }
            if case .problem(let message) = model.state {
                Text(message).font(.callout).accessibilityIdentifier("captureError")
            }
            if model.readiness != .ready {
                Text(model.readiness.description).font(.callout)
                if model.readiness == .missingAssets || readinessProblem {
                    Button("Install English Model (Internet required)") {
                        Task { await model.installAssets() }
                    }
                    .disabled(model.state.active || model.state.busy)
                }
            }
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        if model.transcript.finalized.isEmpty && model.transcript.partial.isEmpty {
                            Text("Live English captions will appear here.")
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("captionPlaceholder")
                        }
                        ForEach(model.transcript.finalized) { segment in
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
                    .font(.system(size: scaledSize * settings.captionSize / 28))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical)
                }
                .onChange(of: model.transcript.finalized.count) { _, _ in scrollToLive(proxy) }
                .onChange(of: model.transcript.partial) { _, _ in scrollToLive(proxy) }
                .onChange(of: followLive) { _, enabled in if enabled { proxy.scrollTo("liveBottom", anchor: .bottom) } }
            }
            HStack {
                Button(model.state == .paused || isProblem ? "Resume" : "Start Listening") {
                    Task { await model.start() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.state.active || model.state.busy || model.state == .ended)
                if model.state == .listening {
                    Button("Pause") { Task { await model.pause() } }
                        .buttonStyle(.bordered)
                }
                Button("Stop") { Task { await model.stop() } }
                    .buttonStyle(.bordered)
                    .disabled(model.state.busy || (!model.state.active && model.state != .paused && !isProblem))
            }
            .frame(minHeight: 44)
            if model.permissionDenied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
                .frame(minHeight: 44)
            }
            DisclosureGroup("Reading options") {
                VStack(alignment: .leading) {
                    Text("Caption size")
                    Slider(value: $settings.captionSize, in: 20...44, step: 2)
                        .accessibilityLabel("Caption size")
                    Toggle("Follow live captions", isOn: $followLive)
                    Toggle("Keep screen awake while listening", isOn: $settings.keepAwake)
                }
            }
            Text("On-device English captions. Accuracy varies with distance, noise and speech.")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("vReader")
        .toolbar {
            Button("New Session") { confirmNewSession = true }
                .disabled(model.state.active || model.state.busy)
        }
        .confirmationDialog("Start a new session? Save current captions first if auto-save is off.",
                            isPresented: $confirmNewSession, titleVisibility: .visible) {
            Button("New Session", role: .destructive) { Task { if let newSession { await newSession() } else { await model.reset() } } }
        }
        .task { await model.checkReadiness() }
        .onChange(of: model.state) { _, _ in applyWakePreference() }
        .onChange(of: settings.keepAwake) { _, _ in applyWakePreference() }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    private var isProblem: Bool { if case .problem = model.state { true } else { false } }
    private var readinessProblem: Bool { if case .problem = model.readiness { true } else { false } }

    private func applyWakePreference() {
        UIApplication.shared.isIdleTimerDisabled = settings.keepAwake && model.state == .listening
    }

    private func scrollToLive(_ proxy: ScrollViewProxy) {
        guard followLive else { return }
        if reduceMotion { proxy.scrollTo("liveBottom", anchor: .bottom) }
        else { withAnimation(.easeOut(duration: 0.15)) { proxy.scrollTo("liveBottom", anchor: .bottom) } }
    }
}
