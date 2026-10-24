# BIFROST connection index

Canonical BIFROST source: `~/edenOS/Software Development/BIFROST/`

## Local project aliases

The `Connections/` directory contains symbolic links to canonical projects. These are navigation aliases only; they do not copy code or transfer project ownership.

- `Connections/HEIMDALL Assistant IOS` → `~/edenOS/Software Development/HEIMDALL Assistant IOS/`
- `Connections/RavenNest` → `~/edenOS/Software Development/Online Plugins & Connectors/RavenNest/`
- `Connections/WORKinCODEX` → `~/edenOS/Software Development/Online Plugins & Connectors/WORKinCODEX/`

HEIMDALL also exposes `Connections/BIFROST` → the canonical BIFROST root.

## Ownership and operating rules

- BIFROST owns connectivity/capability resolution and connective state.
- HEIMDALL owns voice interaction, Apple Shortcuts/App Intents and workspace presentation. BIFROST integration must remain optional and authenticated; HEIMDALL must continue to work independently.
- RavenNest owns the online routing/control plane. Cloudflare routes bounded, authenticated requests; capable authorized executors perform real work.
- WORKinCODEX owns its Codex handoff and executor integration. A link or adapter test is not proof that Codex is signed in or a cloud job has been submitted.
- These links are Finder/CLI navigation aids, not runtime connections, service activation, authentication, or execution proof.
- Do not start or enable RavenNest's optional Mac bridge automatically. Its default remains stopped/disabled and manual approval is required.
- Never duplicate another project's source under BIFROST or treat a linked project as BIFROST-owned.

## Verification

Confirm links with `ls -ld Connections/*` and `readlink`. Confirm destination paths exist before relying on them. Runtime integration requires separate authorization, health and end-to-end acceptance evidence.


## 2026-10-22 — BIFROST + HEIMDALL paired delivery and joint acceptance

Newest explicit Lucas instruction: “Bifrost / heimdall are a pair so they need to finished together”. This changes the active delivery milestone to the complete paired experience. It does not merge source masters, standalone domain ownership, permissions, credentials or application LKG.

- BIFROST CONNECT / KEEP / RESOLVE owns device/provider identity and connections, deterministic capability resolution/execution transports, deployment/bootstrap, own versioned MCP interfaces, optional headless runtime hosting and authenticated online reachability.
- HEIMDALL ORGANIZE & UNDERSTAND owns Workspace/composition semantics and the task-facing workspace, conversation/context links, app surfaces and user experience. Reuse existing native/web composition implementations and domain-owned app representations; BIFROST's admin screens do not replace HEIMDALL.
- Together: one coherent portal/workspace entry experience, app dock, selected launched app representation, chat and supported Siri/Shortcuts entry, explicit identity/context and permission state, durable task/result correlation, local/native-first workflows, native AI assistance and existing silentChatGPT rules. Domain apps retain their own data and execution ownership.
- Local first-setup milestone: macOS BIFROST explicitly opens an on-demand local new-device portal. Another device can open it without MCP, obtain an eligible platform installer or iOS browser/PWA setup, complete owner-authorized setup and enter its HEIMDALL workspace. Apple-to-Apple bootstrap must not require target RDC/MCP/BIFROST first. A page load or download is not an accepted installation; verify installed identity, health, permissions and recovery.
- iOS owner requirement: the combined useful control experience must work without a dedicated BIFROST/HEIMDALL native-app installation, using the supported browser/PWA + user-approved Shortcuts/Siri/a-Shell routes. Do not silently replace this requirement with a mandatory native WebKit wrapper. Browser profile isolation, provider command submission, callbacks and background behavior need real platform/provider tests; browser login is not arbitrary execution/API authority. A native client can remain an optional separately scoped enhancement.
- Multi-provider scope remains recovery/recreation/management/upgrades of Lucas's established provider setup; task-aware efficient routing through existing permitted provider/browser/native/tool interfaces; independently scoped app/deployment MCP identities; local deterministic paths work without MCP/AI/cloud. Retain selected conversation links/lists and start-new contexts without claiming unread private history is recovered.
- Optional online presence/routing/PWA deployment reuses the established RavenNest/Cloudflare owners and their approved isolation/account contracts; no new cloud publication or broad relay authority follows from this pairing statement.

Joint completion gate: new-device entry -> appropriate download/setup -> verified connection -> choose HEIMDALL workspace/provider identity -> run one actual deterministic native/local task and one supported authorized provider task -> return result to the originating workspace -> test offline/provider loss, denial, cancellation, reconnect, duplicate prevention and rollback. Include app-dock/representation operation, hosted-versus-standalone runtime ownership, iOS without dedicated app and actual MacBook Pro bootstrap. Neither side is reported finished for the requested combined milestone solely because its own source/tests/UI pass. Preserve useful independent standalone operation.

Recovery observed: standalone HEIMDALL physical master is `/Users/lucas/edenOS/Projects/HEIMDALL/`, via the existing Software Development compatibility symlink. It has Python/Web Core, Workspace/Custom App functions, `/api/bifrost/manifest`, and native SwiftUI/Spotlight/App Intents/Foundation Models source. Its PROJECT_STATE.txt records incomplete BIFROST integration, unverified native build/GUI and an existing build-auditor conflict with its protected user-selected physical path. Do not bypass that procedure or move the project. **HEIMDALL Assistant iOS is a separate project** at its distinct protected physical master; preserve its Git/LKG, Action Button and callback rules. Pairing standalone HEIMDALL with BIFROST does not silently merge or replace Assistant iOS.

This is an authoritative owner scope/delivery update and source recovery note. It is not an integration implementation, deployed portal, download package, installed Shortcut, accepted hosting protocol or finished pair. Current engineering work remains under ForgeMASTER; no HEIMDALL protected source, running service, provider identity or LKG was modified by this entry.
