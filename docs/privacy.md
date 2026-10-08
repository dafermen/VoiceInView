# Privacy principles
## Current Phase 1 behavior
Microphone access is requested only after Start Listening. NSMicrophoneUsageDescription explains monitoring nearby speech while listening and that audio is not saved/uploaded.
AVAudioEngine receives transient PCM audio and computes a volume value. Buffers are not retained by application code and no audio files or transcripts are written.
Only relative volume values cross into the bounded presentation stream. No network requests, accounts, analytics, tracking, advertising or cloud service are added.
Stop, background and audio failures/interruption end capture. No background audio capability or automatic restart.
The input meter is not transcription. No speech-recognition permission is requested in this phase.

Denied access may also reflect device restrictions; a Settings link is offered, but restrictions might prevent changes.
Future on-device language setup may need Internet; disclose installation separately from offline captioning.
Phase 4 may persist transcripts locally with deletion; backup/file protection must be reviewed then.
Any online AI is a separate future opt-in with explicit action and a secure backend; never ship backend secrets.
Reassess required-reason APIs, privacy manifests and App Privacy answers against actual code/dependencies before release. A release privacy review and published policy remain pending.
