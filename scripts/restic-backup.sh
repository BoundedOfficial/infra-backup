#!/usr/bin/env bash
set -euo pipefail

# Load Restic+B2 configuration
ENV_FILE="${ENV_FILE:-/etc/restic/env}"
if [[ ! -r "${ENV_FILE}" ]]; then
  echo "ERROR: Missing env file: ${ENV_FILE}" >&2
  exit 2
fi
# shellcheck disable=SC1090
source "${ENV_FILE}"

BACKUP_ROOT="${BACKUP_ROOT:-/var/backups/restic}"
LOG_DIR="${LOG_DIR:-${BACKUP_ROOT}/logs}"
LOG_FILE="${LOG_FILE:-${LOG_DIR}/restic-backup.log}"

umask 077
mkdir -p "${BACKUP_ROOT}" "${LOG_DIR}"

log() {
  echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*" | tee -a "${LOG_FILE}"
}

log "Starting backup run"

# 1) Create DB dump
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log "Creating MariaDB dump"
"${SCRIPT_DIR}/mariadb-dump.sh" | tee -a "${LOG_FILE}"

# 2) Backup selected paths
# Keep scope tight: only /var/backups/restic and /stacks (configs)
# Add/remove paths as needed, but avoid backing up docker volumes if you rebuild them.
PATHS_TO_BACKUP=(
  "/var/backups/restic"
  "/stacks"
)

log "Running restic backup"
restic backup \
  --tag "boundedstudios" \
  --tag "webserver" \
  "${PATHS_TO_BACKUP[@]}" | tee -a "${LOG_FILE}"

log "Backup completed successfully"