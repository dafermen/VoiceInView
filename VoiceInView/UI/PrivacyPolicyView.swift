import SwiftUI

@MainActor
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy").font(.title.bold())
                Text("VoiceInView uses your microphone only when you choose to listen or practice pronunciation. English speech is processed on your device. VoiceInView does not upload microphone audio. Saving audio is initially off. Audio and background preferences are remembered for future sessions; recording starts only when you choose to listen or practice pronunciation. If enabled, audio stays on this iPhone until you export or delete it.")
                Text("Final captions, phrase bookmarks and optional audio are stored in a local recovery draft. After Stop, Save Session keeps it in the library; Discard deletes it. Unfinished drafts are available in Sessions after reopening. You can rename, export and delete sessions. Saved transcripts and recordings are excluded from device backup; deleting the app removes them.")
                Text("On-device English recognition must be available before listening. Depending on your iOS version and app build, prepare English Dictation in iPhone Settings or use the model installation option if shown. System model setup may need Internet; recognition is required to stay on your device.")
                Text("Export, Copy and Share are explicit actions. The destination you choose may sync or transmit the transcript, audio or subtitles according to its own privacy policy.")
                Text("Listening normally stops when you leave the app. If Continue in background is enabled, the microphone remains active until you pause or stop, or iOS interrupts it. VoiceInView captures the microphone, not the internal audio of other apps.")
                Text("VoiceInView includes no advertising, tracking, analytics or required account.")
                Text("Optional translation of saved text and confirmed live English captions uses Apple’s Translation framework on supported devices. Apple may ask to download language models; installed languages allow on-device translation. English, Spanish and Spanish edits are stored locally and removed when you delete the session. Apple may collect API usage and performance metrics, but not the original or translated content. Live Spanish preview stays in memory and is not automatically saved. Personal vocabulary is stored as a device preference and used as recognition hints and preferred translation terms; clearing its entries removes it. Device preference backups follow iOS settings. Study expressions and notes are stored with the session and deleted with it. Pronunciation practice records short temporary takes only when you tap its microphone. Takes stay on this iPhone, are excluded from backup, and are deleted when you retry, change the exercise, leave practice or enter the background. Abandoned takes are removed at the next app launch. Optional word recognition requires on-device support and is not pronunciation scoring. VoiceInView adds no third-party translation service.")
                Text("Last updated: October 11, 2026.")
                    .font(.footnote)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding()
        }
        .navigationTitle("Privacy")
    }
}
