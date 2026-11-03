# AppleRAVEN — cloud-native iCloud Drive + Photos

**Status: source package prepared, not account-connected or accepted.** The public edge is already deployed on Cloudflare; this private engine is additional, not a replacement. Strict $0 only where existing free compute is available.

## Provenance and real features

- iCloud Drive: [robworks-code/icloud-mcp](https://github.com/robworks-code/icloud-mcp), MIT, Python 3.12, remote cloud file list/info/search/read/download/upload/write/mkdir/rename/move/trash/restore. Session in /config/session; no local Mac sync required.
- iCloud Photos: [MephistoJB/iCloud-Photos-mcp](https://github.com/MephistoJB/iCloud-Photos-mcp), MIT, Python 3.10+, direct iCloud Photos web API: libraries, albums, metadata, bounded search and preview. Writing/deletion OFF. Original media export is not provided by this MCP; optional [rclone iCloud Photos](https://rclone.org/iclouddrive/) supports read-only original downloads.
- The user's [JoshuaRileyDev/mac-apps-launcher](https://github.com/JoshuaRileyDev/mac-apps-launcher) lives in the existing Mac installer registry, not the cloud service.
- Upstream Apple web APIs are unofficial, and can change; **Apple sign-in does not authorize personal iCloud Drive/Photos via Apple CloudKit**. Credentials and 2FA are entered interactively on the trusted private cloud node, never as MCP tool args.
- [Cloudflare Workers VPC](https://developers.cloudflare.com/workers-vpc/api/) is free *while beta* and lets the owner Worker call private ports through a tunnel without a public hostname. The cloud compute node itself still needs Linux + Docker + a persistent disk. Oracle is optional.

## Deployment order (private Linux VM; no public inbound ports)

**One-command private node setup:** `bash install-cloud.sh` checks Docker, builds providers, prompts for the account identifier and then performs two interactive Apple 2FA logins on the private VM terminal. The steps below also document a manual setup and private tunnel wiring.

1. Obtain this folder from the existing PRIVATE AppleRAVEN candidate repository. Review upstream source and licenses, then choose and pin upstream Git commit refs as Docker build args for repeatable production builds.
2. Copy `.env.example` to `.env`, set your Apple Account identifier; set `chmod 600 .env`. **Do not put passwords, 2FA codes, login cookies or tokens in Git.**
3. Run `docker compose -f compose.yaml build`, then authenticate both providers on the host's terminal:
   - Drive: `docker compose -f compose.yaml run --rm --entrypoint /opt/icloud-mcp/.venv/bin/icloud-mcp drive login`
   - Photos: `docker compose -f compose.yaml run --rm --entrypoint sh photos -c 'icloud auth login --username "$ICLOUD_USERNAME" --session-dir "$ICLOUD_SESSION_DIR"'`
   - Complete Apple 2FA on a trusted device, review Apple trusted-device/ADP web access consent as appropriate. Login sessions live in restricted Docker volumes, not in Cloudflare.
4. `docker compose -f compose.yaml up -d`; use the node's own loopback `http://127.0.0.1:8301/health` for Photos service liveness. This is **not** iCloud authentication confirmation: use MCP `doctor` and `icloud_status` for cloud sessions.
5. Install an outbound-only **named Cloudflare Tunnel** on the same Linux VM, connected to the existing `ravensnest` Cloudflare account. Do not set a public hostname or publish these private services.
6. In **Cloudflare Workers VPC** create two HTTP VPC Services on that tunnel, pointed to `127.0.0.1:8301` (Photos) and `127.0.0.1:8302` (Drive); bind them to the existing `appleraven-private` owner Worker under `ICLOUD_PHOTOS_VPC` and `ICLOUD_DRIVE_VPC`. This requires the cloud federation source update and Worker redeployment. The current production Worker is NOT yet connected to these bindings.
7. After exact owner Access authorization, call `appleraven.cloud.catalog` to discover namespaced `icloud.photos.*` and `icloud.drive.*` tools. First acceptance tests read `doctor`, `icloud_status`, list a Drive folder, list Photos albums, retrieve one preview **with both Macs offline**. Only after that enable any authorized writes in a separately reviewed change.
8. Optional full photo/video MEDIA downloads (direct from iCloud, no Mac): run `docker compose --profile photo-media run --rm photo_media config` and configure an `icloudphotos` remote of type `iclouddrive`, service `photos`; complete Apple 2FA inside the cloud console. Review available libraries with `docker compose --profile photo-media run --rm photo_media lsd icloudphotos:`. To download an explicitly chosen file or album to the private named `icloud_photo_exports` volume, preview `docker compose --profile photo-media run --rm photo_media copy 'icloudphotos:PrimarySync/Favorites/IMG_0001.HEIC' /exports --dry-run` before rerunning without `--dry-run`. Avoid unbounded full-library downloads. These rclone operations are **CLI only**, not exposed through the ChatGPT MCP until a constrained rclone MCP adapter is reviewed. The rclone trust token expires after roughly 30 days and its config contains sensitive Apple account authentication state.

### Security boundaries and recovery

Never forward Apple password or 2FA via ChatGPT. The owner Worker uses signed Cloudflare Access JWT; the private VPC binds only specific services; Docker ports are host-loopback only. Keep Photos deletion disabled. Limit MCP file contents and photo metadata returned to model. Revoke session cookies and stop containers if the VM is compromised. Apple may expire login sessions; the engine must surface a re-authentication state rather than silently claim to be online.

### Cloud-first acceptance status

- Deployed: AppleRAVEN Cloudflare owner/device Workers, Pages bootstrap.
- Prepared here: Docker packaging and source adapters for direct Apple cloud services.
- Pending live execution: cloud node installation, Cloudflare VPC bindings, signed Worker update, interactive Apple 2FA, real Drive/Photos smoke tests.
- Later: cross-platform presentation app. **No Oracle requirement.**
