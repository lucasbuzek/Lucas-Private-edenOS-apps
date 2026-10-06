CAMEL — Cargo, Assets, Movement, Execution & Logistics — v0.3.1
PROMPT & IDENTITY PACKAGE
Owner: Lucas Buzek
Project: EDEN / AppDev
Status: Experimental / TINY-LEAN development

PURPOSE
This package defines CAMEL as an EDEN logistics application and provides reusable launch prompts for CAMEL and its specialist subordinate components.

CAMEL is the logistics-domain authority. It coordinates cargo, assets, movements, dispatch, fleet, tracking and field execution while cooperating with other EDEN applications instead of recreating their capabilities.

CONTENTS
- CAMEL_About_EN.txt — CAMEL identity, responsibilities and subordinate structure.
- CAMEL_About_SK.txt — Slovak version.
- prompts/CAMEL_MASTER_PROMPT.txt — master launch/continuation prompt.
- prompts/CARAVAN_PROMPT.txt — dispatch/movements/jobs/routes.
- prompts/DROVER_PROMPT.txt — fleet/resources/maintenance.
- prompts/CARGO_PROMPT.txt — cargo/loads/consignments/capacity.
- prompts/WAYMARK_PROMPT.txt — tracking/ETA/geofences/exceptions.
- prompts/WAYFARER_PROMPT.txt — driver/field execution.
- prompts/CAMEL_PROMPTS_SK.txt — Slovak quick-reference versions of the prompts.

QUICK START
Load CAMEL_MASTER_PROMPT.txt when beginning or continuing CAMEL work. Call a subordinate prompt when deep specialist focus is needed. CAMEL remains the master logistics authority and coordinates subordinate outputs.

ARCHITECTURAL RULE
IMPLEMENT / INTEGRATE EXISTING CAPABILITY BEFORE RECREATING IT.

CAMEL cooperates especially with HERMES (opportunities/tenders), MONETA (financial truth), ORACLE (quantitative analysis), THEMIS (legal/compliance), CONDUCTOR (all AI/orchestration), BIFROST (identity/content/provenance/interoperability), and HEIMDALL (Workspaces).
