# CURATOR v1.3.5 Full Project Backup

This directory contains a complete compressed backup of the current CURATOR v1.3.5 project package, including source, tests, manifests, profiles, contracts, provider documentation, installer/manager scripts, verification logs, SHA256SUMS and recovery/development records.

Backup source package: `CURATOR_Private_Custom_Lucas_v1.3.5-goal-pipeline-audit-repair-experimental.zip`

Original ZIP SHA-256: `03cd7978170c45c1cf6d6000b1592f912594404ed818456ab7fc9f7d5c42976e`

GitHub backup archive: `CURATOR_v1.3.5_FULL_BACKUP.tar.xz`

Archive SHA-256: `496dc92e30087c56cf652c2c67a829aae8149b7c317290cb09c56d3188859edd`

Archive entries reported before upload: 128.

## Restore
Run `chmod +x RESTORE.sh`, then `./RESTORE.sh`, then `tar -xJf CURATOR_v1.3.5_FULL_BACKUP.tar.xz`.

The archive is Base64-split because the connected GitHub write interface accepts UTF-8 text files. RESTORE.sh reconstructs the binary archive, verifies SHA-256, and verifies XZ integrity before extraction.

Evidence state is unchanged by backup: portable Swift tests PASS 40/40; macOS syntax parse PASS; native macOS/M1 runtime verification UNKNOWN; real professional-provider round trips UNKNOWN. This backup is preservation evidence, not a claim of native release verification.
