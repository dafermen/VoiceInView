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
    // Global defaults are explicit opt-ins and survive a new session or app relaunch.
    var saveAudio: Bool { didSet { defaults.set(saveAudio, forKey: "saveAudio") } }
    var continueInBackground: Bool { didSet { defaults.set(continueInBackground, forKey: "continueInBackground") } }
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
        saveAudio = defaults.bool(forKey: "saveAudio")
        continueInBackground = defaults.bool(forKey: "continueInBackground")
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
