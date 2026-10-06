# silentChatGPT — UNIVERSAL APPDEV CANON

Status: AUTHORITATIVE UNIVERSAL APPDEV RULE
Applies to: AppDev Private/Custom Apple-capable applications and any project that explicitly declares silentChatGPT support.

## 1. Canonical name

The canonical capability name is:

silentChatGPT

Use this exact concept name in AppDev Bibles, project documentation, capability manifests and handoffs.

## 2. Purpose

silentChatGPT is a background escalation mechanism for difficult reasoning tasks when the application's deterministic engines and local/native Apple intelligence are insufficient.

It follows the same operational principle as Siri / Apple Intelligence escalating a difficult request to the configured ChatGPT extension:

local/native capability first -> escalate only when needed -> receive result -> originating application continues.

silentChatGPT is NOT the application's primary intelligence layer.

## 3. Independence

Every application that implements silentChatGPT must remain independently complete.

The application owns:
- its own domain logic;
- its own deterministic engines;
- its own local/native AI integration;
- its own escalation decision;
- its own privacy/context reduction;
- its own App Intents / Shortcuts integration where applicable;
- its own validation;
- its own provenance;
- its own UI and result handling.

The application MUST NOT require HEIMDALL, BIFROST, CONDUCTOR or another EDEN application in order to use silentChatGPT.

Higher-level EDEN applications may separately call the application's exposed capabilities, or may use their own silentChatGPT/provider path.

## 4. Apple operational mechanism

For Private/Custom Apple builds, the preferred supported route is Apple system integration, not a simulated OpenAI API.

Canonical flow:

USER / APP UI / SIRI / APP INTENT / SHORTCUT
  -> originating application
  -> deterministic application capability
  -> Apple local/native intelligence when adequate
  -> escalation required?
       no  -> continue locally
       yes -> Apple System Intelligence / Shortcuts Use Model
              -> configured Extension Model / ChatGPT
              -> structured/text result
  -> originating application validates/interprets result
  -> deterministic application capability executes or records authoritative state
  -> result returns to originating surface

The exact public Apple API/surface may evolve by OS version. Implement with supported Apple mechanisms available on the target system.

## 5. Shortcuts / Use Model

A supported implementation path to verify is:

Shortcuts Use Model -> configured Extension Model -> ChatGPT

This path is suitable for bounded text/structured escalation.

Do NOT misrepresent Apple's configured ChatGPT extension as an unrestricted OpenAI API.

Do NOT assume a consumer ChatGPT subscription grants arbitrary API access.

Do NOT embed the ChatGPT website or require a separate ChatGPT UI.

## 6. Local multimodal preprocessing

Images, screenshots, photos, documents and PDFs are processed locally first where practical.

Canonical path:

asset
-> native acquisition
-> Vision / OCR / VisionKit / document parsing / native model processing
-> preserve relevant text, tables, sections, layout, objects and metadata
-> extract the minimum relevant textual/structured context
-> silentChatGPT escalation only if needed
-> result

Raw attachments are NOT silently transmitted in the normal path.

Raw attachment transmission is an exceptional explicit path subject to platform confirmation/permission behavior and project-specific authorization.

## 7. Minimal-context invariant

silentChatGPT sends the smallest sufficient problem.

Prefer:
- exact question/objective;
- relevant extracted text;
- normalized structured data;
- evidence IDs/references;
- local attempt summary;
- unresolved contradiction;
- required output schema.

Do not send:
- entire user databases;
- unrelated portfolio/account data;
- unrelated files;
- arbitrary screenshots;
- credentials;
- secrets;
- whole conversation history

unless a project-specific explicit requirement and user-authorized path makes that data genuinely necessary.

## 8. Authority boundary

silentChatGPT output is reasoning/interpretation input, not authoritative application state.

It may produce:
- interpretation;
- proposed resolution;
- evidence assessment;
- summary;
- research direction;
- scenario reasoning;
- thesis challenge;
- structured candidate output.

It MUST NOT directly mutate authoritative domain state merely because a model produced an answer.

The originating application validates and applies results through deterministic/domain rules.

## 9. Escalation conditions

Typical reasons to escalate:
- local model cannot complete reliably;
- multi-source contradiction remains unresolved;
- difficult synthesis exceeds local model capability;
- context/reasoning depth exceeds local practical limits;
- repeated local attempt fails with a changed method;
- project-specific Expert/Deep task requires stronger reasoning.

Do not escalate merely because ChatGPT is available.

## 10. Provider transparency

Silent means no unnecessary separate provider UI or ceremony.

It does NOT mean:
- undisclosed cloud transmission;
- bypassing Apple confirmations;
- hidden consequential actions;
- pretending provider failures did not occur.

Projects should expose appropriate provider/privacy controls and meaningful failures.

## 11. Failure / fallback

If silentChatGPT is unavailable:
- continue all possible deterministic/local work;
- use another configured authorized provider if project canon permits;
- checkpoint resumable work where applicable;
- expose exact unresolved state if no valid path remains.

Never fabricate completion.

## 12. App Intent / Siri relationship

Applications may expose their own App Intents and App Shortcuts so Siri can invoke them directly.

Siri may:
- call the app directly;
- use its own Apple Intelligence/ChatGPT escalation;
- invoke an app intent whose internal execution later uses silentChatGPT.

These are compatible paths.

The application does not require Siri to use silentChatGPT.

## 13. Private vs Official

Private/Custom Apple profiles may enable silentChatGPT by default or as a preferred escalation path.

Official portable apps must not become dependent on ChatGPT unless the specific Project Bible explicitly establishes that dependency.

Official apps should retain provider abstraction where appropriate.

## 14. Verification

A claimed silentChatGPT implementation should verify, as applicable:
- real App Intent/Shortcut invocation;
- local-first handling;
- bounded text/structured escalation;
- configured ChatGPT Extension Model path;
- return to originating application/surface;
- raw attachments remain local in the normal path;
- result validation before authoritative state mutation;
- graceful provider failure;
- no fake API assumptions.

Compilation alone is not verification.

## 15. Universal invariant

silentChatGPT = LOCAL/NATIVE FIRST + APP-OWNED ESCALATION DECISION + APPLE-SUPPORTED CHATGPT EXTENSION HANDOFF + MINIMUM NECESSARY CONTEXT + RESULT RETURNS TO ORIGINATING APP + DETERMINISTIC VALIDATION.

No HEIMDALL/BIFROST/CONDUCTOR dependency is implied.
