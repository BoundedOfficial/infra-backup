#!/usr/bin/env bash
set -euo pipefail

# === Configuration (non-secrets) ===
DB_CONTAINER="${DB_CONTAINER:-mautic-db-1}"
DB_NAME="${DB_NAME:-your_db_name}" #Replace with your credentials
DB_USER="${DB_USER:-your_db_user}" #Replace with your credentials

# Where to read the DB password from
DB_PASSWORD_FILE="${DB_PASSWORD_FILE:-/etc/secrets/mautic/mautic_db_password}" #Replace with the location of your password file

# Output locations
BACKUP_ROOT="${BACKUP_ROOT:-/var/backups/restic}"
DB_OUT_DIR="${DB_OUT_DIR:-${BACKUP_ROOT}/db}"

# Timestamp format safe for filenames
TS="$(date -u +'%Y-%m-%d_%H-%M-%S')"
OUT_FILE="${DB_OUT_DIR}/mautic_${TS}.sql.gz"

umask 077
mkdir -p "${DB_OUT_DIR}"

if [[ ! -r "${DB_PASSWORD_FILE}" ]]; then
  echo "ERROR: DB_PASSWORD_FILE not readable: ${DB_PASSWORD_FILE}" >&2
  exit 2
fi

DB_PASS="$(<"${DB_PASSWORD_FILE}")"
if [[ -z "${DB_PASS}" ]]; then
  echo "ERROR: DB password file is empty: ${DB_PASSWORD_FILE}" >&2
  exit 2
fi

# Dump from inside the container to stdout, gzip on host
# - --single-transaction for consistent snapshot (InnoDB)
# - --quick reduces memory usage
# - --routines --triggers if you use them (safe to include)
sudo -u YourUser docker exec -i "${DB_CONTAINER}" sh -lc \ #Replace with your service account user
  "mariadb-dump -u'${DB_USER}' -p\"${DB_PASS}\" \
    --single-transaction --quick --routines --triggers '${DB_NAME}'" \
  | gzip -c > "${OUT_FILE}"

# Simple integrity check: file exists and is non-empty
if [[ ! -s "${OUT_FILE}" ]]; then
  echo "ERROR: dump output file is empty: ${OUT_FILE}" >&2
  exit 3
fi

echo "OK: DB dump created: ${OUT_FILE}"
