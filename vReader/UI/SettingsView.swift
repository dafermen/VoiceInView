import SwiftUI
import AVFoundation
import UIKit

struct SettingsView: View {
    @Bindable var settings: AppSettings
    let coordinator: SessionCoordinator

    var body: some View {
        Form {
            Section("Offline preparation") {
                NavigationLink("Offline Readiness") { OfflineReadinessView(coordinator: coordinator) }
                NavigationLink("Microphone Check") { MicrophoneCheckView() }
                    .disabled(coordinator.caption.state.active || coordinator.caption.state.busy)
            }
            Section("Captions") {
                LabeledContent("Language", value: "English (United States)")
                Text("Additional transcription languages are not available yet.").font(.caption)
                Slider(value: $settings.captionSize, in: 20...44, step: 2) { Text("Caption size") }
                Toggle("Keep screen awake while listening", isOn: $settings.keepAwake)
                Picker("Appearance", selection: $settings.appearance) {
                    ForEach(AppAppearance.allCases, id: \.self) { appearance in
                        Text(appearance.rawValue.capitalized).tag(appearance)
                    }
                }
            }
            Section("Local sessions") {
                Toggle("Auto-save final captions", isOn: $settings.autoSave)
                    .disabled(coordinator.caption.state.active || coordinator.caption.state.busy ||
                              coordinator.caption.state == .paused)
                Text("When off, captions remain in memory until you tap Save Session. Leaving or closing the app may lose unsaved text.")
                    .font(.caption)
                Text("Saved sessions are excluded from device backup. Export anything you need to keep.")
                    .font(.caption)
            }
            Section("Privacy") {
                NavigationLink("Privacy Policy") { PrivacyPolicyView() }
                Text("No accounts, analytics, tracking or stored audio.")
            }
        }
        .navigationTitle("Settings")
    }
}

struct OfflineReadinessView: View {
    let coordinator: SessionCoordinator
    @Environment(\.scenePhase) private var phase
    @State private var permission = MicrophonePermission.undetermined
    @State private var storage = StorageReadiness(availableBytes: nil)
    @State private var instructions = false

    private var ready: Bool {
        permission == .granted && coordinator.caption.readiness == .ready && storage.ready
    }

    var body: some View {
        Form {
            Section("Required checks") {
                LabeledContent("Microphone", value: permission == .granted ? "Ready" : "Permission needed")
                LabeledContent("English model", value: coordinator.caption.readiness.description)
                LabeledContent("Local storage", value: storage.description)
                LabeledContent("Offline transcription", value: ready ? "Ready for offline test" : "Not ready")
                if permission == .undetermined {
                    Button("Allow Microphone") {
                        Task {
                            _ = await AVAudioApplication.requestRecordPermission()
                            refreshPermission()
                        }
                    }
                } else if permission == .denied {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    }
                }
                if coordinator.caption.readiness == .missingAssets || modelProblem {
                    Button("Install English Model") {
                        Task { await coordinator.caption.installAssets() }
                    }
                    .disabled(coordinator.caption.state.active || coordinator.caption.state.busy)
                    Text("Model installation needs Internet and may require additional storage.")
                }
                Button("Refresh Checks") { Task { await refresh() } }
            }
            Section {
                Button("Test Offline Mode") { instructions = true }
                Text("Installed assets are required, but only a real offline test verifies your device. This screen does not detect Airplane Mode.")
                    .font(.caption)
            }
        }
        .navigationTitle("Offline Readiness")
        .task { await refresh() }
        .onChange(of: phase) { _, phase in
            if phase == .active { Task { await refresh() } }
        }
        .sheet(isPresented: $instructions) {
            NavigationStack {
                List {
                    Text("1. Install the English model and allow microphone access while online.")
                    Text("2. Enable Airplane Mode in Control Center or Settings, and turn Wi-Fi off.")
                    Text("3. Return to Captions, tap Start Listening, and speak a full English sentence.")
                    Text("4. Verify live and final captions appear; tap Stop and check the saved session.")
                    Text("5. Repeat before attending a conference. If a check fails, prepare the device while online.")
                }
                .navigationTitle("Test Offline Mode")
                .toolbar { Button("Done") { instructions = false } }
            }
        }
    }

    private var modelProblem: Bool {
        if case .problem = coordinator.caption.readiness { return true }
        return false
    }

    private func refreshPermission() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: permission = .granted
        case .denied: permission = .denied
        case .undetermined: permission = .undetermined
        @unknown default: permission = .unavailable
        }
    }

    private func refresh() async {
        refreshPermission()
        storage = StorageReadiness.check(at: coordinator.repository.storageURL)
        await coordinator.caption.checkReadiness()
    }
}
