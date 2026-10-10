# Audio and subtitle workflow

Before Start, choose Audio and Background in Captions or use Aa/Settings. Both preferences initially default off and are remembered across sessions and app relaunches. Recording follows the audio choice at Start; changes while listening apply to the next session. Background can be changed during capture. A recovery draft always stores final captions and any optional recording; Stop then Save publishes it, while confirmed Discard deletes it. A red Recording label appears while audio saving is active, including fullscreen. Stop before reviewing saved audio.

Sessions > open session > Audio & subtitles provides playback, ±10-second seeking, position slider, captions on/off and fullscreen rotation. M4A can be shared alone or together with corrected TXT and SRT/VTT. Native sharing provides Save to Files. Existing TXT/PDF review/export remains available. Delete audio keeps transcript, edits, bookmarks and subtitle timing; Delete session also deletes its audio.

Subtitles align to this session's audio, with pauses removed. Native recognition timing is retained; changed text is estimated inside the paragraph's saved range. Old sessions without recorded timing do not offer subtitle export. App switching mixes with other apps when allowed by iOS; it does not capture internal audio. The source must be audible to the microphone, so headphones will not work for transcribing another app.

## Required real-device checks
- Start with both options off: no recording file; background stops listening.
- Enable Save audio: speak, pause for ten seconds, resume, speak again, Stop. Replay around the boundary; pause time is omitted and subtitles stay aligned. Test across at least two recognition rotations.
- Correct a word, reopen Audio & subtitles; preview and export corrected TXT, SRT and VTT alongside M4A. Compare playback in an external compatible player.
- Enable Continue in background, start listening, switch to a video app using the speaker, then lock/unlock. Verify microphone indicator, final text, timing and explicit Stop. Repeat with a meeting app and check that calls/interruption surface a stopped state. No universal source-app compatibility is assumed.
- Delete audio and verify text/subtitle retention; delete session and verify file removal. Relaunch to confirm persistence.
- Verify long sessions, low storage, route changes, phone calls, airplane mode, device protection/backup and battery use on actual hardware.

Local tests cover recording/decoding, M4A conversion, sample clock, rotation/resume offsets, migrations, deletion, subtitle formatting and UI playback/export. Hardware recognition, long-session timing and source-app coexistence remain device validation tasks.
