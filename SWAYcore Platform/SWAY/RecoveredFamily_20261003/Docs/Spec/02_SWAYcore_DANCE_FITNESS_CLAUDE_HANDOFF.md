# Claude Rebuild Handoff — SWAYcore Dance & Fitness

## Product
Native iOS+iPadOS consumer dance learning/fitness app. Loop: WATCH -> COPY -> MATCH -> COMBO -> SCORE -> UNLOCK -> DANCE. Primary navigation: HOME · MOVES · BEATS · PROFILE. Create, Learn and Tracking are workflows, not permanent developer navigation.

## Coaches
All five must be ready in final architecture/assets: Lucia, Nandi, Thabo, Zuri, Kyle. Shared movement truth/common rig; appearance/personality/voice may differ. COACH=guidance target; YOU=tracked learner; YOUR DANCER=customizable graphical user avatar. No per-coach choreography engines.

## Content
Recovered history reached ~26 bundled moves; do not regress to demo content. Move -> Variation -> Combination -> Routine -> Workout -> Challenge -> Program. Mastery: Discovered -> Learning -> Familiar -> Mastered. Complexity: Simple -> Easy -> Moderate -> Complex -> Expert, separate from intensity/accessibility.

Experiences: Quick Dance, Dance, Learn Moves, Party, Challenge, Freestyle, Daily Dance, Endurance, Low Impact, Adaptive Workout. Reconcile historical presentation concepts Balanced, Just Dance, Mirror, Fitness, Learn, Minimal rather than deleting them.

## Learn
Move selection; counts 1–8; selected count deterministically displays that pose/state; instruction matches pose; Play/Resume; Pause freezes count+character. Practice tempo is user-controlled, no arbitrary auto-speed-up. Tempo -> beat -> count -> COACH movement on one practice clock.

## Beats/music
Generated/offline SWAY Beats; imported/local music; Apple Music/MusicKit; Shazam recognition/sync where useful; playlists/song selection; Automatic/In Order/Shuffle. Recovered styles: Simple, Pop, House, Hip-Hop, Disco, Latin, Afro, Percussion, Rock, Minimal. Analyze tempo+phase/grid+downbeats/bar/phrase. Move boundaries align musically. Half-time allowed while synchronized.

## Tracking
Six-action calibration: STEP INTO VIEW -> WAVE LEFT -> WAVE RIGHT -> LIFT LEFT FOOT -> LIFT RIGHT FOOT -> JUMP -> READY TO SWAY.
Tracking lifecycle: select workout -> Tracking -> permission/session -> body acquisition -> calibration -> READY -> countdown -> workout. Before READY: no workout timeline, choreography, timer, scoring, motivational speech or move progression. Follow-Along: Setup -> Countdown -> Workout.

One performance space. Camera is input, not permanent side-by-side window. Tracking loss: workout continues, YOU confidence fades, REPOSITION/STEP INTO VIEW appears, reacquisition restores YOU.

## YOU / avatar
Raw Vision skeleton is diagnostic only. Camera -> Vision joints -> normalized pose -> compatible graphical rig -> translucent graphical YOU over COACH -> comparison/scoring. YOUR DANCER is baseline and must go beyond the broken/basic Skin/Hair/Outfit-only state: large adaptive preview, real visible options only, production assets, movement/tracking compatibility.

## Voice/cues
One CoachCue drives visual wording, spoken wording, timing, priority, coach personality. Speech may be conversational but same meaning. No calibration chatter. Evidence-dependent praise cannot be timer-fired. Voice Off/Minimal/Normal/Detailed; natural non-overlapping Apple speech.

## Create/share/record/progress
Create Move: capture/create -> movement definition -> edit -> count/pose preview -> save -> Library -> Learn/use -> combine -> share. `.swaypack` export/import/validation + native Share Sheet; no account/server required; licensed music referenced, not illegally embedded. Record Me/Record SWAY -> appropriate audio -> Photos/Files -> Share Sheet, unverified until physically demonstrated. Results/scoring/mastery/streaks/rewards/unlocks/next actions reflect real learning.

## Health/accessibility/offline
Recover HealthKit permissions/workout/settings/error states. Apple Watch remains broader roadmap unless promoted by authority. VoiceOver, Dynamic Type, contrast, reduced motion, touch targets, labels/errors, Low Impact, Adaptive Workout. Offline: bundled moves, Beats, characters, Learn, Follow-Along, local persistence, appropriate tracking, swaypack.

## Final UI/UIX
Mockups are authority. HOME: strong entry, large coach, Start/Resume, useful progress. MOVES: visual library/demonstration/Learn-Practice-Create. LEARN: coach dominates, 1–8, tempo, play/pause. BEATS: consumer music/rhythm. SETUP: workout -> music -> options -> Tracking/Follow-Along -> Start. CALIBRATION uses workout stage and owns it until READY. WORKOUT is cleanest: large coach, graphical YOU overlay, current move/count/NEXT readable at distance, minimal progress, obvious Pause. RESULTS: result/score/mastery/next. PROFILE: YOUR DANCER/history/integrations/settings. iPad portrait+landscape use space for scale/hierarchy, not dashboard clutter.

## Production Blender
No PNG/cutout fallback. Common humanoid skeleton for five coaches+YOUR DANCER; clean topology; skinning/deformation; production materials/textures; facial/head customization support; validated clips/export; scalable native runtime. Build 153 only proved primitive SWAYHumanoid-v1 with 23 joints and proof clips (idle, march, step-touch, grapevine, knee-lift, squat, side-lunge, jumping-jack, body-roll, pivot-turn), not final character quality.

## Recovery anchors
Build 143 graphical/runtime reference. Build 147 protected tracking reference. Build 148 physically rejected. Build 153 recovery/LKG package evidence only: pipeline/build/install/launch evidence, incomplete physical feature-flow verification and primitive characters. Never rebuild only from latest broken build.

## Physical journey
Fresh install -> onboarding -> Home -> Moves -> Learn/counts/tempo -> Beats/music analysis -> YOUR DANCER -> Create -> swaypack export/import -> Follow-Along -> Tracking -> calibration -> READY -> countdown -> synchronized music/coach/count/text/speech/YOU/scoring -> loss/reacquisition -> pause/resume -> recording -> results/mastery -> Profile -> Health/settings -> relaunch/persistence -> offline. Repeat iPhone, iPad portrait, iPad landscape.

## macOS one-click builder
Deliver executable SWAYcore one-click `.command`: preflight project/LKG; check Homebrew and ensure_formula/ensure_cask; fetch only missing declared dependencies; check Xcode (do not silently install); check compatible Blender; build/validate production 3D assets; run source/tests; build generic iOS/iPadOS; package exact candidate; only then say CONNECT AND UNLOCK IPHONE/IPAD NOW when physical evidence is next. Verify executable bit, ZIP CRC/hash, source/assets/build identity. Compilation/install/launch are not feature acceptance.
