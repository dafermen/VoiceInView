import Foundation
import Observation
import SwiftUI
import UIKit

enum AppAppearance: String, CaseIterable, Equatable, Hashable, Sendable {
    case system, light, dark
}

/// Persist a stable locale; unknown/older preferences retain English as the default.
enum CaptureLanguage: String, CaseIterable, Sendable, Codable {
    case english = "en-US", spanish = "es-ES"
    var name: String { self == .english ? "English" : "Español" }
    var code: String { self == .english ? "en" : "es" }
    var opposite: Self { self == .english ? .spanish : .english }
    var mode: TranscriptLanguage { self == .english ? .english : .spanish }
}

enum ReaderPaper: String, CaseIterable {
    case system, yellow, blue, green, purple
    var label: String {
        switch self { case .system: "System"; case .yellow: "Amarillo claro"; case .blue: "Azul claro"
        case .green: "Verde claro"; case .purple: "Morado claro" }
    }
    var color: Color {
        switch self {
        case .system: Color(uiColor: .systemBackground)
        case .yellow: Color(red: 1, green: 0.97, blue: 0.82)
        case .blue: Color(red: 0.87, green: 0.95, blue: 1)
        case .green: Color(red: 0.89, green: 0.97, blue: 0.87)
        case .purple: Color(red: 0.95, green: 0.89, blue: 0.99)
        }
    }
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
    var captureLanguage: CaptureLanguage { didSet { defaults.set(captureLanguage.rawValue, forKey: "captureLanguage") } }
    var readerPaper: ReaderPaper { didSet { defaults.set(readerPaper.rawValue, forKey: "readerPaper") } }
    var ruledPaper: Bool { didSet { defaults.set(ruledPaper, forKey: "ruledPaper") } }
    var transcriptionLanguage: String { captureLanguage.rawValue }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        captureLanguage = CaptureLanguage(rawValue: defaults.string(forKey: "captureLanguage") ?? "") ?? .english
        readerPaper = ReaderPaper(rawValue: defaults.string(forKey: "readerPaper") ?? "") ?? .system
        ruledPaper = defaults.bool(forKey: "ruledPaper")
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


/// Decorative notebook guides, never accessibility elements or gesture targets.
struct ReaderSurface: View {
    let settings: AppSettings
    @Environment(\.colorScheme) private var scheme
    @ScaledMetric(relativeTo: .title) private var scaledSize: CGFloat = 28
    var body: some View {
        let points = scaledSize * settings.captionSize / 28
        let step = max(24, UIFont.systemFont(ofSize: points).lineHeight + settings.lineSpacing)
        return ZStack {
            if settings.highContrast { scheme == .dark ? Color.black : Color.white }
            else { settings.readerPaper.color }
            if settings.ruledPaper && !settings.highContrast {
                NotebookRuling(step: step, dark: scheme == .dark)
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// CoreGraphics is enough for horizontal guides; no Canvas/Metal shader pipeline is needed.
/// UIKit redraws on size changes, while SwiftUI supplies immutable drawing preferences.
private struct NotebookRuling: UIViewRepresentable {
    let step: CGFloat
    let dark: Bool
    func makeUIView(context: Context) -> RulingView {
        let view = RulingView()
        view.isOpaque = false
        view.backgroundColor = .clear
        view.contentMode = .redraw
        view.isUserInteractionEnabled = false
        view.accessibilityElementsHidden = true
        return view
    }
    func updateUIView(_ view: RulingView, context: Context) {
        view.step = step
        view.ink = (dark ? UIColor.white : UIColor.black).withAlphaComponent(0.12)
        view.setNeedsDisplay()
    }
    final class RulingView: UIView {
        var step: CGFloat = 38
        var ink = UIColor.black.withAlphaComponent(0.12)
        override func draw(_ rect: CGRect) {
            guard bounds.width.isFinite, bounds.height.isFinite, step.isFinite, step > 0,
                  let context = UIGraphicsGetCurrentContext() else { return }
            let count = Int(min(1000, max(0, bounds.height / step)))
            context.setStrokeColor(ink.cgColor)
            context.setLineWidth(0.5)
            for index in 0..<count {
                let y = 14 + CGFloat(index + 1) * step
                context.move(to: CGPoint(x: 0, y: y))
                context.addLine(to: CGPoint(x: bounds.width, y: y))
            }
            context.strokePath()
        }
    }
}


struct ReaderPaperOptions: View {
    @Bindable var settings: AppSettings
    var body: some View {
        Section("Fondo de lectura") {
            Picker("Color del fondo", selection: $settings.readerPaper) {
                ForEach(ReaderPaper.allCases, id: \.self) { Text($0.label).tag($0) }
            }.accessibilityIdentifier("readerPaperPicker")
            Toggle("Renglones de cuaderno", isOn: $settings.ruledPaper)
                .accessibilityIdentifier("ruledPaperToggle")
            Text("Los colores claros usan texto oscuro. Alto contraste tiene prioridad y oculta los renglones.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
