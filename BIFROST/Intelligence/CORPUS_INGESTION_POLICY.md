# BIFROST Intelligence — ingestion and model-training authorization policy (project-specific)
2026-10-19. This is a design/implementation contract scoped to BIFROST Intelligence, not independent AppDev governance.

## Strictly distinct operations
DISCOVER is a bounded path listing.
INVENTORY reads file metadata/hashes of explicitly nominated project artifacts, emits source references and a classification only.
INDEX reads approved text into private local search storage; requires permission_to_index and project-owner authorization.
RETRIEVE exposes just the permitted query-relevant slices at runtime subject to caller identity/ACL.
TRAIN produces derived model adapter/weights; requires independent permission_to_train, dataset version/rights, privacy review and evaluation.
SHARE or UPLOAD requires separate consent, destination authorization and documented network boundary.
No mode is automatically upgraded to the next. A metadata inventory count is not a training/ingestion count.

## Default source classes
- FIRST_PARTY_CANON: live BIFROST decisions/workflows and verified source docs. Candidate for scoped indexing once content/security review passes; never blindly treat historical prose as active law.
- LIVE_SHARED_RULE: live #common AppDev rules are referenced, not copied into a shadow governance corpus. Canon authority remains external; review for retrieval snapshots with revision discipline.
- SPECIALIST_CONTRACT: actual HEIMDALL iOS Council behavior, AI TOOLKIT capabilities, LECTOR book schema. Candidate for source-backed architectural context; not an authorization to consume unrelated app databases.
- OWN_LIBRARY_METADATA: titles, authors, progress and personal annotations accessible through LECTOR/Calibre only under owner permission and user-selected scopes. Read-only discovery is not confirmation of full-text rights.
- LICENSED_BOOK_TEXT: full ebook/audiobook/documents — pending actual license/rights review; default exclude from model training.
- PRIVATE_PERSONAL / THIRD_PARTY / FAMILY / BUSINESS / FINANCIAL / HEALTH: metadata, corpus indexing, training and remote transfer all denied by default pending per-data-owner consent, scope, rights and retention.
- CHATGPT_EXPORT: EXPLICITLY DEFERRED until secure parser and training/retrieval workflow are demonstrated. User will request export later.
- SECRET_OR_CREDENTIAL: permanently exclude credential values from all model training and retrieval. Protect live connector secrets separately.

## Local data boundaries
Default fail closed. Do not follow symlinks or recursively sweep user home/Projects; do not copy arbitrary hidden files, .env, keys, tokens, logs or caches. No egress or background sync. All native specialist applications remain independently functional; use authorized export/capability contracts, not scraping private databases.
Use record provenance with content SHA256, purpose, approved owner, software/source version and exact permission source. Use minimum-size excerpts/chunks, filtered text, retention policy, and source-revocation mechanisms.
A PII tool may aid review but cannot fully verify data suitability. Copyright, licenses and privacy are separate from filesystem access.

## Current recorded authorizations
User authorized BIFROST/JARVIS researchfull and preparation of ingestion/training preproduction materials. User did not authorize requesting a new ChatGPT export yet, unrestricted copying of family/account records, silent mass ingestion of all files, new paid APIs, model downloads or current-device training.
Live HEIMDALL Council is entertainment only when invoked; default BIFROST personality is focused and capable, not unsolicited insults/roasts.
Completion gate: user-approved source groups + verified rights/consent + tested parsing and filtering + reproducible local store + measured baseline model + reliable deletion/reindex before bulk indexing; independent training gate afterward.
