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
    var lineSpacing: Double { didSet { defaults.set(lineSpacing, forKey: "lineSpacing") } }
    var boldCaptions: Bool { didSet { defaults.set(boldCaptions, forKey: "boldCaptions") } }
    var highContrast: Bool { didSet { defaults.set(highContrast, forKey: "highContrast") } }
    var keepAwake: Bool { didSet { defaults.set(keepAwake, forKey: "keepAwake") } }
    var autoSave: Bool { didSet { defaults.set(autoSave, forKey: "autoSave") } }
    var appearance: AppAppearance { didSet { defaults.set(appearance.rawValue, forKey: "appearance") } }
    let transcriptionLanguage = "en-US"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedSize = defaults.object(forKey: "captionSize") as? Double ?? 28
        captionSize = min(max(storedSize.isFinite ? storedSize : 28, 20), 44)
        let storedSpacing = defaults.object(forKey: "lineSpacing") as? Double ?? 4
        lineSpacing = min(max(storedSpacing.isFinite ? storedSpacing : 4, 0), 16)
        boldCaptions = defaults.bool(forKey: "boldCaptions")
        highContrast = defaults.bool(forKey: "highContrast")
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
