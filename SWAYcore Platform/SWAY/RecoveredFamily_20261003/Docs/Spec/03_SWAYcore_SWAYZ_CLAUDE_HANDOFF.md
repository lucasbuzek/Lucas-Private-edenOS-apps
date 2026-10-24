# Claude Rebuild Handoff — SWAYcore SWAYZ

## Identity
Professional DANCE INSTRUCTOR / CHOREOGRAPHY product. Family identity: CREATE · CHOREOGRAPH · TEACH · INSPIRE. SWAYZ is NOT Studio Management.

The original concept was tied in project discussion to the Patrick Swayze / Dirty Dancing dance-instructor archetype: confident human teaching, demonstration, partnership and choreography. This is inspiration, not permission to copy Patrick Swayze's likeness or copyrighted Dirty Dancing characters/assets.

Recovered visual direction included a Patrick-Swayze/Dirty-Dancing-style human instructor feel, dark violet/pink/cyan stage, graphical move cards/previews and hierarchy COACH -> move/count/progress -> next move. Final established SWAYcore mockups override older exploratory visuals.

## Purpose/functions
Professional instructor uses the SAME SWAYcore movement model to author and teach dance. Required recovered/high-confidence functions: movement authoring; count-level pose/state edit/preview; combinations/sequences/routines; transitions; side/mirroring; choreography timeline; music/count synchronization; cue placement; production articulated instructor demonstration; rehearsal/practice at controlled tempo; Create Move camera/pose capture; local library/save/version; portable export/import/share; authored content consumable by SWAYcore Learn/Practice/Workout without conversion to a second choreography schema.

Formations/performer placement may be represented as choreography metadata where supported by the common model. Do not invent a separate movement engine.

Detailed lesson/student-assignment database workflows were not fully recovered as canon in this pass. Do not fabricate them as established functionality. Keep Studio business operations out of SWAYZ.

## UX
Professional visual choreography-first UI. Primary stage/canvas shows articulated instructor and current choreography. Counts/timeline direct manipulation. Music waveform/beat/phrase available when useful, not dominant. iPad uses larger canvas/timeline rather than extra dashboard cards. No developer diagnostics in production.

## Core integration
Consume common normalized pose, Movement Definition, timing/music grid, rigs, cue semantics, tracking/matching and portable content. Round-trip fixture: author -> save -> export -> import -> consumer Learn/Practice runtime -> identical counts/poses/timing.

## Characters/offline
Use common production rig; no raster dancers as production. Instructor identity/presentation is separate from motion truth. Authoring/library/rehearsal/export useful offline; camera capture on-device where practical.

## Acceptance
Instructor can author a move, define/inspect counts, compose choreography, synchronize to music/counts, preview with production articulated character, save, export, re-import and consume identical data in learner/runtime. No duplicate movement engine and no PNG production fallback.

## macOS one-click builder
All building runs on macOS. Provide `.command` with Homebrew check plus ensure_formula/ensure_cask; fetch only missing declared tools; Xcode preflight; Blender preflight/asset validation where required; build/test native Apple target(s) established by project; package exact source/assets/tests. Do not require Windows/Linux build hosts.
