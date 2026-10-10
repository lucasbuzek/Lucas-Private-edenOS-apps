# RavenNest ↔ BIFROST Headless — read-only bridge candidate

Status: LOCAL BRANCH, OFFLINE TESTED, NOT DEPLOYED (2026-10-09).

The existing outbound-only Raven node-state publisher has a bounded,
read-only BIFROST Headless observation. It queries Mac loopback at
http://127.0.0.1:8798, never a public IP, and reports:
- Headless RUNNING only after HTTP 200 and a genuine running state
- Codex task count when observed, otherwise UNKNOWN
- AI routing preference (not claimed as an executing provider)
- Headless-owned Caffeinate state
- AI Toolkit and Project Workspace imported/staged status only

Excludes session keys, filesystem paths, ZIP filenames, auth secrets,
and arbitrary commands. GET requests only, bounded at 16 KiB and timeout 2s.
Remote setup execution explicitly disabled.

Verified offline:
- Python bridge tests: 27 passed, including four probe tests
- Web Edge tests: 28 passed
- Cloud Worker tests: 3 passed

Not verified:
- Physical iPhone pairing, Cloudflare Access or per-device grants
- New remote actions, GitHub/Cloudflare deployment or mobile UI
- Setup installation execution or rollback

Before deployment: reconcile with Raven integration branch, re-run gates,
verify Access/permissions, then controlled bridge restart if authorized.
Local Headless API remains loopback-only.
