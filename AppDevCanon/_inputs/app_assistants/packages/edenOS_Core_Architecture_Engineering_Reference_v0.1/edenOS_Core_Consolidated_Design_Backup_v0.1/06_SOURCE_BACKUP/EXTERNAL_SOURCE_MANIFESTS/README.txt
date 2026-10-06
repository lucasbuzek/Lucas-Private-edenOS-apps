EXTERNAL SOURCE BACKUP STRATEGY

This package intentionally does not embed huge third-party repositories. Instead it contains:
1. canonical project URLs and design notes;
2. a machine-readable source manifest;
3. a reproducible backup script that clones/downloads the selected upstream repositories;
4. license/provenance policy.

Run 09_RECOVERY/backup_external_sources.sh on a machine with git/network access to create a dated local source mirror. After download, preserve the generated commit manifest with the archive so the exact source state is recoverable.
