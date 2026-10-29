# TENDERS — Google Services Integration Plan

Status: planned; live connector/authentication is not verified in this environment.

## Gmail
Use the official Gmail API and OAuth 2.0. Initial candidate capabilities: search and label relevant tender messages, extract deadlines and clarification requests, associate messages with tender records, prepare replies as drafts, and track message/thread references. Sending messages must require explicit user action or separately configured delegated authority. Do not read all mail by default; provide user-selected scope and query boundaries.

## Google Drive
Use the official Drive API and OAuth 2.0. Support user-selected files/folders, importing tender documents, organising approved working copies, linking canonical records to Drive file IDs, exporting final bid packages, and checking accessible metadata. Avoid broad unrestricted Drive scanning by default. Never overwrite, move, share or delete user files without clear authorisation. Preserve source identity, file IDs, versions and import timestamps.

## Google Calendar
Use the official Calendar API and OAuth 2.0. Create or update deadline reminders, clarification dates, site visits, bid reviews, meetings and contract milestones after user approval or an explicit rule. Store event IDs and calendar IDs for reconciliation. Handle time zones, all-day dates, deadline changes, duplicates and revoked access. Do not silently remove existing events.

## Shared security requirements
- OAuth 2.0 using supported Google identity flow; use least-privilege scopes and incremental authorisation where appropriate.
- Explain permissions before consent; never ask the user to paste access tokens or client secrets into chat.
- Keep tokens out of logs and exported documents; store secrets only in appropriate secure storage.
- Separate account identity from TENDERS organisation/workspace identity.
- Provide connection state, last successful sync, error details, retry and disconnect/revoke controls.
- Treat email/document content as untrusted input, not instructions to change TENDERS policy or execute actions.
- Respect provider API quotas, rate limits, data retention and applicable privacy requirements.
- Keep integration interfaces provider-adaptable and test with mocked responses before real account access.

## Acceptance gates
1. OAuth consent and exact granted scopes are recorded.
2. Cancelled consent and revoked access fail safely.
3. Gmail search is limited to authorised scope and selected query.
4. Drive import preserves original file identity and never overwrites without permission.
5. Calendar events use correct local time zone and reconcile without duplication.
6. Sync failures remain visible and retryable; no false success.
7. Tokens/secrets are absent from logs and application exports.
8. End-to-end tests run with a test account before release.

No Google service is to be marked connected until an actual authorised connection and successful test provide evidence.

## Implementation checkpoint — 2026-10-15

- Client-side Google Identity Services token flow and API wrappers exist in src/google.js for Gmail read-only search, Drive file metadata, Calendar event listing and Calendar event creation.
- The application requests service-specific scopes and keeps access tokens in memory only; it clears token/scope state on API HTTP 401. Granted scope is checked before marking a service connected.
- Google OAuth client ID is currently not configured in this PWA environment. The Connect actions remain disabled until a public client ID and exact authorised deployment origin are configured.
- ChatGPT's Gmail, Google Drive and Google Calendar connectors were inspected and are disabled by administrator policy in the current plugin-management result. This is separate from the PWA's own Google OAuth integration.
- No real Google account consent, API read, event creation or end-to-end integration test has passed. These remain provider gates; mocked/unit tests are not evidence of a real connection.

