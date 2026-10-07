EITRIMB CAPABILITY PROVIDER DISCOVERY — v1.0

PURPOSE
Make plugin/App/connector discovery a governed fallback and acceleration mechanism for any software-development workflow problem.

TRIGGER
A meaningful execution problem or capability gap exists and an external provider could materially help.

PIPELINE
DIAGNOSE → IDENTIFY CAPABILITY → CHECK LOCAL/NATIVE → CHECK INSTALLED/CONNECTED → SEARCH AVAILABLE PROVIDERS → EVALUATE → OFFER INSTALL/CONNECT → HUMAN DECISION → ADAPT → EXECUTE → VERIFY → RECORD.

HUMAN AUTHORIZATION
Installation, connection, authentication and permission grants always require explicit human action. EITRI offers; Lucas chooses.

PROVIDER EVALUATION
Consider capability fit, project fit, duplication, permissions, privacy/security boundary, connectivity, platform/environment, cost/complexity when known, evidence strength, recoverability, vendor lock-in and fallback.

CAPABILITY REGISTRY FIELDS
capability_id
provider
provider_class: LOCAL|NATIVE|APP|PLUGIN|CLOUD
platform_environment
availability: AVAILABLE|DEGRADED|OFFLINE|UNKNOWN
authorization_state
connectivity_requirement
cost_class
permissions_scope
evidence_strength
fallback_provider
last_verified

FAILURE BEHAVIOR
Declining or losing a plugin does not automatically block a project. Re-route through local/native, existing provider, alternate provider or reduced-capability safe execution when possible.

NON-GOALS
Do not install plugins speculatively.
Do not collect overlapping providers without a concrete need.
Do not replace established project architecture solely because a plugin exists.
Do not mark provider output VERIFIED without the project's normal verification.
