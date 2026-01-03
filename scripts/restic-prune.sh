#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${ENV_FILE:-/etc/restic/env}"
if [[ ! -r "${ENV_FILE}" ]]; then
  echo "ERROR: Missing env file: ${ENV_FILE}" >&2
  exit 2
fi
# shellcheck disable=SC1090
source "${ENV_FILE}"

BACKUP_ROOT="${BACKUP_ROOT:-/var/backups/restic}"
LOG_DIR="${LOG_DIR:-${BACKUP_ROOT}/logs}"
LOG_FILE="${LOG_FILE:-${LOG_DIR}/restic-prune.log}"

umask 077
mkdir -p "${LOG_DIR}"

log() {
  echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*" | tee -a "${LOG_FILE}"
}

log "Starting retention + prune"

# Example retention policy:
# - keep 7 daily
# - keep 4 weekly
# - keep 6 monthly
# Adjust to your needs.
restic forget \
  --tag "boundedstudios" \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6 \
  --prune | tee -a "${LOG_FILE}"

log "Retention + prune completed"
