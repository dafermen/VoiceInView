import SwiftUI

@MainActor
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy").font(.title.bold())
                Text("VoiceInView uses your microphone only when you choose to listen. English speech is processed on your device. VoiceInView does not upload microphone audio. Saving audio is off by default and can be enabled before each session. If enabled, audio stays on this iPhone until you export or delete it.")
                Text("Final captions and phrase bookmarks can be saved locally on this iPhone. You can rename, export and delete sessions. Saved transcripts and recordings are excluded from device backup; deleting the app removes them.")
                Text("On-device English recognition must be available before listening. Depending on your iOS version and app build, prepare English Dictation in iPhone Settings or use the model installation option if shown. System model setup may need Internet; recognition is required to stay on your device.")
                Text("Export, Copy and Share are explicit actions. The destination you choose may sync or transmit the transcript, audio or subtitles according to its own privacy policy.")
                Text("Listening normally stops when you leave the app. If you enable Continue in background for a session, the microphone remains active until you pause or stop, or iOS interrupts it. VoiceInView captures the microphone, not the internal audio of other apps.")
                Text("VoiceInView includes no advertising, tracking, analytics or required account.")
                Text("Last updated: October 9, 2026.")
                    .font(.footnote)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding()
        }
        .navigationTitle("Privacy")
    }
}
