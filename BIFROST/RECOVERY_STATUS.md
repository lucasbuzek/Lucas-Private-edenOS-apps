# BIFROST recovery status

Status date: 2026-10-02

## Authority recovered

- Global rules: `~/edenOS/Projects/#appDev Bible/APPDEV_BIBLE.txt` and its
  canonical companion files.
- Project-specific architecture and milestone in the initiating recovery
  instruction: BIFROST is the shared host/runtime infrastructure when selected
  and compatible; Apps retain domain logic, data, product identity, and a
  standalone headless runtime. Delegation is reversible. Existing compatible
  Apps must be adoptable without destructive reinstall, state loss, or
  simultaneous duplicate services. BIFROST is optional.
- The global role definition is BIFROST: CONNECT · KEEP · RESOLVE at system
  level, including devices, connections, capability resolution, and connective
  persistent state.

## Missing authority

There is no `Project Bibles/BIFROST.txt` in the authoritative Project Bibles
directory. No BIFROST-specific historical conversation, requirements ledger,
release register, or other authority was present in the authorized material
inspected. No project-specific detail beyond the architecture above is inferred
here. This file is a new recovery record, not a recovered Bible.

## Source and provenance

The canonical workspace contains `BIFROST.xcodeproj`, `project.yml`, and Swift
files under `Sources/`. These are genuine pre-existing source artifacts. Their
origin, prior release status, and historical acceptance are unverified. The
workspace has no `.git` repository, so no source history or LKG can be
established from Git. No tested or released LKG was demonstrated.

Classification: **partial-source recovery**. Existing source is a macOS SwiftUI
app with code for Bonjour discovery, a Keep Awake control, capability
enumeration, JANITOR launcher controls, EDEN app discovery/opening, and a
Remote Desktop Commander process wrapper. See
`IMPLEMENTATION_INVENTORY.md` for per-file classification and behavioral
limits. An initial sandboxed macOS build on 2026-10-01 failed while loading the
SwiftUI `State` macro plugin after `sandbox_apply: Operation not permitted`.
Escalated builds on 2026-10-02 succeeded. One justified source repair now
surfaces Shortcuts query errors and observes the capability registry so refresh
results can update the view. The current Debug `.app` has a valid Info.plist
(`plutil -lint` passed), and the rebuilt app process started and exited on
SIGTERM. This establishes **BUILT** and **PROCESS-LAUNCH CHECKED**, not
interactive feature verification or release.

## Candidate and next gate

The workspace is the current candidate. No LKG is known. Before the source
repair, a snapshot was created at
`/private/tmp/BIFROST-recovery-baseline-2026-10-02.zip` and verified with
`unzip -t`. It preserves the pre-edit source/candidate boundary and is not a
historical LKG. `RUNTIME_DELEGATION_CONTRACT.md` records required behavior and
unrecovered details; it is a new engineering record, not recovered source or
historical contract evidence. Existing sources do not implement runtime
delegation/adoption. The next product gate is an implemented App adapter and
BIFROST host that exercise exclusive handoff and standalone fallback on macOS.

The current Debug app archive is
`/private/tmp/BIFROST-macos-debug-current-candidate.zip`; `unzip -t` found no
archive errors. It is a verified archive of the build output, not a signed
distributable or released package. Safe local checks confirmed the two
source-referenced JANITOR `--version` commands, `caffeinate`, AppleScript, and
the built app process start/exit. `/usr/bin/shortcuts list` failed in this
environment; the UI now exposes that status, though GUI controls were not
visually inspected. The Xcode project has no test target, so product tests were
not run. No Bonjour discovery results or Remote Desktop Commander readiness
were verified. No regression suite or comparison to a demonstrated LKG is
available.
