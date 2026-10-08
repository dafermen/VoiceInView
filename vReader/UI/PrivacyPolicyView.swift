import SwiftUI

@MainActor
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy").font(.title.bold())
                Text("vReader uses your microphone only when you choose to listen. English speech is processed on your device. vReader does not upload or save microphone audio.")
                Text("Final captions can be saved locally on this iPhone. You can rename, export and delete sessions. Saved transcripts are excluded from device backup; deleting the app removes them.")
                Text("On-device English recognition must be available before listening. Depending on your iOS version and app build, prepare English Dictation in iPhone Settings or use the model installation option if shown. System model setup may need Internet; recognition is required to stay on your device.")
                Text("Export, Copy and Share are explicit actions. The destination you choose may sync or transmit the transcript according to its own privacy policy.")
                Text("vReader includes no advertising, tracking, analytics or required account.")
                Text("Last updated: October 8, 2026.")
                    .font(.footnote)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding()
        }
        .navigationTitle("Privacy")
    }
}
