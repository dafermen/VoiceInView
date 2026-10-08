import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @State private var model = CaptionViewModel()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Live English captions").font(.title.bold())
                Text(model.state == .listening ? "LIVE · Listening" : "Not listening")
                    .font(.headline).accessibilityIdentifier("listeningStatus")
                if case .problem(let message) = model.state {
                    Text(message).accessibilityIdentifier("captureError")
                }
                if model.readiness != .ready {
                    Text(model.readiness.description)
                    if model.readiness == .missingAssets || isReadinessProblem {
                        Button("Install English Model (Internet required)") {
                            Task { await model.installAssets() }
                        }
                    }
                }
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(model.transcript.finalized) { segment in Text(segment.text) }
                        ForEach(model.transcript.partial) { segment in
                            Text(segment.text).foregroundStyle(.secondary)
                        }
                    }
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack {
                    Button("Start Listening") { Task { await model.start() } }
                        .buttonStyle(.borderedProminent)
                        .disabled(model.state.active || model.state.busy || model.state == .ended)
                    Button("Stop") { Task { await model.stop() } }
                        .buttonStyle(.bordered)
                        .disabled(!model.state.active)
                }
                if model.permissionDenied {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                }
                Text("Captions stay on this iPhone. Accuracy may vary.")
                    .font(.footnote)
            }
            .padding()
            .navigationTitle("vReader")
        }
        .task { await model.checkReadiness() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { Task { await model.background() } }
            if phase == .active { model.foregrounded() }
        }
    }

    private var isReadinessProblem: Bool {
        if case .problem = model.readiness { return true }
        return false
    }
}
