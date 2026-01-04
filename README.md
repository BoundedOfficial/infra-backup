Production-ready backup and disaster recovery stack for a self-hosted VPS.

Uses Restic with client-side encryption and Backblaze B2 object storage.
Database dumps and infrastructure configuration are backed up using
custom Bash automation and systemd scheduling.

All identifiers, credentials, and infrastructure-specific values have
been sanitized to avoid leaking production details.

------------------------------------------------------------------------

## 📁 Directory Structure

```
/
├── scripts/
│   ├── mariadb-dump.sh
│   ├── restic-backup.sh
│   └── restic-prune.sh
└── systemd/
    ├── restic-backup.service
    ├── restic-backup.timer
    ├── restic-prune.service
    └── restic-prune.timer
```

- **scripts/** — Bash automation for database dumps, Restic backups,
  and retention pruning.
- **systemd/** — systemd service and timer units used for scheduling,
  logging, and failure reporting.

------------------------------------------------------------------------

## 🏗️ Stack Components

### **Restic**

- Client-side encrypted backups (AES-256-GCM)
- Snapshot-based backup model with deduplication
- Explicit retention and pruning via `restic forget`
- Repository stored in Backblaze B2

### **Backblaze B2**

- Usage-based object storage (no fixed monthly cost)
- Application key scoped to a single bucket
- Receives only encrypted data (zero-trust storage model)

### **MariaDB (containerized)**

- Backups executed from inside the database container via `docker exec`
- Uses a non-root database user
- Consistent dumps via `--single-transaction`
- Output compressed and staged locally before upload

### **Bash Automation**

- Database dump script:
  - Reads credentials from host-mounted secret files
  - Writes timestamped, compressed dumps
- Backup orchestration script:
  - Triggers database dump
  - Runs Restic backup
  - Handles logging and failure conditions
- Prune script:
  - Enforces retention policies
  - Explicitly removes unneeded snapshots

### **systemd**

- Services used instead of cron for reliability and observability
- Timers define backup and prune schedules
- All logs available via `journalctl`

------------------------------------------------------------------------

## 🔧 Configuration Notes

### Secrets

- Secrets are stored on the host and injected at runtime
- No credentials are committed to the repository
- Restic and storage credentials are loaded from an environment file
- Database credentials are read from mounted files

### Backup Scope

Only irreplaceable data is backed up:
- MariaDB database dumps
- Docker Compose and infrastructure configuration

Docker volumes, images, and containers are intentionally excluded, as
they are reproducible from configuration.

### Retention

- Retention policies are applied explicitly via `restic forget`
- Pruning is run separately from backups to reduce risk
- No automatic or implicit deletion of data

------------------------------------------------------------------------

## 🔒 Security Considerations

**Backups are protected by:**
- Client-side encryption before upload
- Least-privilege credentials
- Scoped object storage access
- Explicit retention and pruning

**Secrets are not present in:**
- Repository files
- Git history
- Docker Compose files
- `docker inspect` output

**Secrets are accessible to:**
- The backup process at runtime
- Root users on the host
- Administrators with Docker access

Access to the host and Docker daemon must be restricted accordingly.

