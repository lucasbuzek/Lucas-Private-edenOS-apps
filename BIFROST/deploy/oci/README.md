# BIFROSTbridge OCI deployment candidate — 2026-11-02

**Source of truth:** The existing BIFROST core and headless code in this repository. This is a packaging adapter for `headless/mcp_remote.py`, **not** a new BIFROST core, dispatcher, gateway, or CONDUCTOR runtime.

## Status and environment

- OCI: `bifrost-zero-bootstrap`, Ubuntu 24.04 x86-64, Always Free, 1 GB RAM.
- Existing Docker router `bifrost-mcp-router` stays untouched on `127.0.0.1:8780`; its current routes serve workAIcloud, LucasFirst and ForgeDuino.
- Existing broken `mcp-gateway` (nonexistent npm `@modelcontextprotocol/server-sse`) stays stopped and recoverable.
- Tailscale on OCI is enrolled in the RAVENsNEST tailnet. Do not publish the MCP service on the VM's public IP.
- Separate Cloudflare `bifrost-control-staging` Worker and D1 are **not** an OAuth issuer or remote MCP. They currently report `deviceExecutionAvailable:false`.
- These Docker files are **SOURCE_COMMITTED only** until a real OCI build/test/launch receipt exists.

## Dry-run verification before deployment

From a checkout of **this candidate branch**:

```sh
cd BIFROST
docker build --target test -f deploy/oci/Dockerfile .
```

This executes the existing security and actual SDK HTTP boundary test suites with fixture identities. It is not equivalent to live OAuth or ChatGPT acceptance.

## Required owner-controlled configuration

A trusted **real** OAuth issuer and its HTTPS RFC 7662 introspection service must be provisioned outside this container. Client registration, consent UI, real owner `sub` IDs, HTTPS resource URL ending in `/mcp`, scopes and token revocation must be verified first. The current `BIFROST_ADMIN_TOKEN` Cloudflare Worker secret does not satisfy this.

Set in an owner-controlled, uncommitted deployment environment:
- `BIFROST_MCP_ISSUER_URL`, `BIFROST_MCP_INTROSPECTION_URL`, `BIFROST_MCP_RESOURCE_URL`
- `BIFROST_MCP_OAUTH_CLIENT_ID`
- `BIFROST_MCP_ALLOWED_SUBJECTS` (nonempty JSON array of **verified** issuer `sub` identifiers)
- `BIFROST_MCP_SECRET_FILE_HOST` (existing regular, non-symlink client-secret file, mode 0600)
- `BIFROST_MCP_UID` and `BIFROST_MCP_GID` (unprivileged host UID/GID that can read the secret)

Never commit the private file, identity tokens, provider keys, production `.env`, or chat transcripts. Do not create a dummy issuer, accept wildcard subjects, or use a placeholder URL to bypass the guard.

## Local-only startup gate

After the issuer is configured, a real TLS reverse proxy with explicit Host/Origin, resource, auth-header and forwarding rules must be present **before** allowing remote clients. The Compose service uses host networking but the Python app binds only to `127.0.0.1:8799`; the existing router on 8780 is not rewritten.

```sh
cd BIFROST/deploy/oci
docker compose config --quiet
docker compose build
docker compose up -d
```

Leave `restart: "no"` until successful issuer/transport security tests. Only after tests consider `unless-stopped` and startup-on-reboot.

## Acceptance and evidence gates

1. `docker build --target test` passes; actual image and digest recorded; no non-free resources.
2. Real owner OAuth `sub` and `bifrost:read` token work; wrong issuer, owner, audience, client, scope, expired/revoked token fail.
3. HTTPS MCP `server/discover`, `tools/list`, `bifrost.system.platform.read` return **actual OCI/Linux host** evidence, with no shell/file-write capability.
4. ChatGPT web **and** ChatGPT iOS configured against the real endpoint with successful tool invocation. A local test alone is insufficient.
5. Device capability grants, heartbeats and receipts must be implemented and tested separately through the original BIFROST dispatcher; neither `cloud_control_staging` nor this single read-only MCP tool is a device executor.
6. Connectors, provider federation, memory/projects/tasks/schedules, retries, backup/recovery, family isolation and native device clients are separate owner-approved acceptance gates.

No LKG promotion, public route, paid provider, user grant or production release is authorized by this candidate.
