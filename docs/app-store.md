# App Store planning
Phase 1 is not submission ready. Apple review requirements checked on 2026-10-07:
https://developer.apple.com/app-store/review/guidelines/

Architecture implications: minimize collected data, explain sensitive access, maintain accurate behavior/metadata, and provide a privacy policy reflecting actual data flows. Review section 5.1 again before release.
Pending: final bundle identifier/team, licensing decision, app icon, support/privacy URLs, privacy manifest/API inventory, App Privacy answers, supported-device validation, accessibility review and release build.
Do not claim guaranteed accuracy or compatibility; iOS 26 alone is not proof of speech support.
An initial model download must be explained without describing online setup as offline transcription.
No account, analytics, tracking, advertisements or cloud transcription.
The home shell alone is not sufficient for App Store submission. Full release checklist belongs to Phase 9.

Phase 1 declares microphone usage in Debug/Release and requests consent only for explicit listening. It captures transient audio for volume monitoring without files, network or tracking. No background capability is enabled.
The first-run permission text must remain accurate as transcription is added. Device restrictions can block access; do not represent denied access as ready.
The release privacy/API manifest audit remains pending and should cover the actual SDK used for distribution.