import SwiftUI

@MainActor
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy").font(.title.bold())
                Text("VoiceInView uses your microphone only when you choose to listen. English speech is processed on your device. VoiceInView does not upload microphone audio. Saving audio is initially off. Audio and background preferences are remembered for future sessions; recording starts only when you choose to listen. If enabled, audio stays on this iPhone until you export or delete it.")
                Text("Final captions, phrase bookmarks and optional audio are stored in a local recovery draft. After Stop, Save Session keeps it in the library; Discard deletes it. Unfinished drafts are available in Sessions after reopening. You can rename, export and delete sessions. Saved transcripts and recordings are excluded from device backup; deleting the app removes them.")
                Text("On-device English recognition must be available before listening. Depending on your iOS version and app build, prepare English Dictation in iPhone Settings or use the model installation option if shown. System model setup may need Internet; recognition is required to stay on your device.")
                Text("Export, Copy and Share are explicit actions. The destination you choose may sync or transmit the transcript, audio or subtitles according to its own privacy policy.")
                Text("Listening normally stops when you leave the app. If Continue in background is enabled, the microphone remains active until you pause or stop, or iOS interrupts it. VoiceInView captures the microphone, not the internal audio of other apps.")
                Text("VoiceInView includes no advertising, tracking, analytics or required account.")
                Text("Last updated: October 10, 2026.")
                    .font(.footnote)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding()
        }
        .navigationTitle("Privacy")
    }
}
