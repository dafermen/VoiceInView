import SwiftUI

struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var coordinator: SessionCoordinator?
    @State private var storageFailure = false

    var body: some View {
        Group {
            if let coordinator {
                TabView {
                    NavigationStack {
                        CaptionScreen(model: coordinator.caption, newSession: { await coordinator.newSession() })
                            .toolbar {
                                Button("Save Session") { coordinator.saveCurrent(ended: coordinator.caption.state == .ended) }
                            }
                    }
                    .tabItem { Label("Captions", systemImage: "captions.bubble") }
                    NavigationStack { SessionHistoryView(coordinator: coordinator) }
                        .tabItem { Label("Sessions", systemImage: "clock") }
                }
                .modelContainer(coordinator.repository.container)
                .alert("Storage problem", isPresented: Binding(
                    get: { coordinator.storageMessage != nil },
                    set: { if !$0 { coordinator.storageMessage = nil } })) {
                        Button("OK") { coordinator.storageMessage = nil }
                    } message: { Text(coordinator.storageMessage ?? "") }
            } else if storageFailure {
                ContentUnavailableView {
                    Label("Local storage unavailable", systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text("Your saved data has not been deleted. Free storage and try again.")
                } actions: {
                    Button("Retry") { openStorage() }
                }
            } else {
                ProgressView("Opening local sessions")
            }
        }
        .task { if coordinator == nil { openStorage() } }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                Task { await coordinator?.caption.background() }
            } else if phase == .active {
                coordinator?.caption.foregrounded()
            }
        }
    }

    private func openStorage() {
        do {
            coordinator = SessionCoordinator(repository: try TranscriptRepository())
            storageFailure = false
        } catch { storageFailure = true }
    }
}
