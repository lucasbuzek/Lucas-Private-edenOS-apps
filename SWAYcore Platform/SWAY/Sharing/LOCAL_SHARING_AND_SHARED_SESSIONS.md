# SWAY Local Sharing, Content Portability, Recording and Shared Sessions
**Recovered product requirements. Source files exist, physical functioning incomplete.**

## Accountless content sharing — Alpha-required
- User creates a Move, previews/edit counts, saves it locally, exports a versioned validated `.swaypack`, and sends it through the native iOS Share Sheet including iMessage, AirDrop or Files. Receiver can inspect, validate, import and use the same Move through Learn/Practice/Workout. No login or web backend required.
- Portable files must carry common movement definition, timing, poses/sequence, content/version metadata, compatibility and provenance; no second proprietary choreography schema. Detect corrupt/untrusted packs, missing rigs or unauthorized resources before import. Imports are reversible and never delete existing library entries silently.
- Licensed/protected Apple Music audio is **referenced** if permitted, never illegally embedded or rehosted. Local privacy/recording rules apply to all outbound files.
- Source references: `RecoveredFamily_20261003/Packages/SWAYcoreKit/Sources/SWAYcoreKit/SwayPack.swift`, current R2 `App/SWAY/Models/ProfileSharing.swift` and export/import code (inspect, do not assume PASS).

## Record Me / Record SWAY
- User expressly chooses camera/recording, output destination Photos or Files, and explicit Share Sheet.
- Camera frames must not be uploaded or kept simply for tracking. Declining permissions allows non-camera Learn/Follow-Along.
- ReplayKit/Photos/Share-related code and entitlements do not prove physical correct capture, save, permissions, or privacy. Keep quality gate UNKNOWN until iPhone/iPad observed.

## Consumer Shared Sessions
- **Consumer maximum: two participants.** Shared movement/song/count/beat reference and each participant's state use one choreography/timing truth. Optional local pairing/SharePlay/MultipeerConnectivity must be verified separately; platform entitlement/permission failures degrade to solo offline mode.
- Do not treat passive audience, downloaded choreography, or challenge leaderboard as additional live participant slots.
- Larger classes, teachers and studio students belong to the professional SWAYZ/Studio ecosystem. Shared session sync, controls, local-vs-cloud topology and participants' consent must be tested before advertising it as working.
- User data is private by default; no public account forced for local duo sessions.

## Official sharing/community extension
- When the official web backend is eventually implemented and accepted, explicit **Publish** may upload canonical packs, metadata/profile/public preview; private local **Share** continues working independently.
- Distinguish private device-to-device share, group challenge, public community publishing, and professional class distribution clearly in UI and permissions.
- Moderation, unpublish, licence/version checks and account privacy are prerequisites for open community uploads.

## Acceptance / regression gates
Create -> Save -> Export -> Send/Copy -> Import -> Preview -> Learn/Workout -> persistence round-trip; no loss of timing/joints, no unauthorized audio/identifying data; appropriate entitlement, offline and physical iPhone/iPad tests. Unknown until actual evidence. Source existence is not a pass.
