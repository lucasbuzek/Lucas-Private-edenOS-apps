# Claude Rebuild Handoff — SWAYcore Studio Management

## Identity/boundary
Professional dance-studio BUSINESS/OPERATIONS product, distinct from SWAYZ. Historical visual label was “SWAYcore Studio Instructor”; current user clarification is Studio Management. Family shorthand: INSTRUCT · MANAGE · GROW · SUCCEED. Recovered description: “Professional studio environment for instructors and studio management.”

SWAYZ owns choreography/dance-instructor authoring. Studio Management owns studio operations. Do not merge them.

## Recovered management scope
Established earlier discussion: schedules/calendar; instructors/staff; members/students; memberships; attendance; class rosters; billing/payments; basic finance; administration. Professional ecosystem remains separate from consumer Dance & Fitness.

## Coherent workflows
Implement the recovered scope as coherent operations: today's classes/actionable exceptions; create/edit schedule and recurring classes; assign instructor; capacity/roster; enroll/remove members/students; attendance/check-in/history; staff assignments; membership status/lifecycle; billing/invoice/payment state/outstanding items; basic administrative/finance summaries and durable records. Visual references showed analytics-like panels, but exact KPIs were not recovered—do not invent “canonical” metrics.

A minimal coherent data model may include Studio, Staff/Instructor, Student/Member, Class, Schedule, Enrollment/Roster, Attendance, Membership/Plan, Charge/Invoice/Payment and administrative notes. Treat this schema as implementation structure, not recovered canon if a current Project Bible defines differently.

## SWAY integration
May link people/classes/content and launch/reference SWAYZ choreography/teaching material, but does not copy the movement engine into management code. Business records remain a separate domain.

## UI/UIX
Professional, fast and calm. Adaptive iPad/macOS split views, calendar/roster/detail patterns, keyboard/pointer support where native. Do not use consumer workout UI as dashboard; do not turn every function into giant cards. Established final mockups override inferred layout.

## Platforms/build-host
All builder/orchestration scripts RUN ON macOS. Lucas is not expected to build on Windows or Linux.
- iPadOS/macOS: native build from macOS/Xcode.
- Windows/Linux remain previously requested Studio output targets, but no final cross-platform framework/toolchain was recovered. Do not invent one as canon. Select a macOS-hosted cross-platform route only after proving it can generate maintainable target artifacts. If final signing/packaging truly requires another OS, report that exact limitation rather than pretending success.

## Local-first/data
Core studio operations should remain locally usable/offline where practical. Exact cloud/account/multi-user sync authority was not recovered in this pass; do not fabricate it. Use durable migrations/backups and never commit secrets.

## Acceptance
From clean data: create class/schedule, assign instructor, enroll members, manage roster, record attendance, manage membership, record billing/payment, inspect basic admin/finance summary, quit/relaunch and retain correct state. Production UI on required Apple targets. SWAYZ remains distinct.

## macOS one-click builder
`.command` checks Homebrew; ensure_formula/ensure_cask; fetch only missing declared dependencies; Xcode preflight; build native iPadOS/macOS; run data/migration/workflow tests; package exact tested outputs. For Windows/Linux outputs, first prove chosen macOS-hosted cross-platform route. Never require Lucas to manually build on those OSes as normal workflow.
