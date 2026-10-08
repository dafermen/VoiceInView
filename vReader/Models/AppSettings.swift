import Foundation
import Observation
import SwiftUI

enum AppAppearance: String, CaseIterable, Equatable, Hashable, Sendable {
    case system, light, dark
}

@MainActor
@Observable
final class AppSettings {
    @ObservationIgnored private let defaults: UserDefaults
    var captionSize: Double { didSet { defaults.set(captionSize, forKey: "captionSize") } }
    var keepAwake: Bool { didSet { defaults.set(keepAwake, forKey: "keepAwake") } }
    var autoSave: Bool { didSet { defaults.set(autoSave, forKey: "autoSave") } }
    var appearance: AppAppearance { didSet { defaults.set(appearance.rawValue, forKey: "appearance") } }
    let transcriptionLanguage = "en-US"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedSize = defaults.object(forKey: "captionSize") as? Double ?? 28
        captionSize = min(max(storedSize.isFinite ? storedSize : 28, 20), 44)
        keepAwake = defaults.object(forKey: "keepAwake") as? Bool ?? true
        autoSave = defaults.object(forKey: "autoSave") as? Bool ?? true
        appearance = AppAppearance(rawValue: defaults.string(forKey: "appearance") ?? "") ?? .system
    }

    var colorScheme: ColorScheme? {
        switch appearance {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
