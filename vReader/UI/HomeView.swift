import SwiftUI

struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var model = CaptionViewModel()

    var body: some View {
        NavigationStack { CaptionScreen(model: model) }
            .onChange(of: scenePhase) { _, phase in
                if phase == .background { Task { await model.background() } }
                if phase == .active { model.foregrounded() }
            }
    }
}
