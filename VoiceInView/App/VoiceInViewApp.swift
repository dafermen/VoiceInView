import SwiftUI

/// Entrada de la app: crea la escena; AppRootView conecta vistas, servicios y almacenamiento.
@main
@MainActor
struct VoiceInViewApp: App {
    var body: some Scene {
        WindowGroup { AppRootView() }
    }
}
