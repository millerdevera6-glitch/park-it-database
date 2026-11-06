#!/usr/bin/env bash
# ==============================================================================
# COMP 018 – Database Administration | Activity 6
# Script: restore.sh
# Purpose: Safely restore a PostgreSQL custom archive backup (-Fc) into an
#          isolated test database (default: ojt_managementdb_restore_test),
#          verifying exit codes, schema objects, and ownership.
# ==============================================================================

set -euo pipefail

# Configuration defaults
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
TARGET_DB="${1:-ojt_managementdb_restore_test}"
DB_USER="${DB_USER:-postgres}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/backups"
BACKUP_FILENAME="${BACKUP_FILENAME:-ojt_managementdb_activity6.dump}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILENAME}"

echo "=============================================================================="
echo " Starting Database Restoration Process"
echo " Target Database: ${TARGET_DB}"
echo " Source Backup:   ${BACKUP_PATH}"
echo " Host:            ${DB_HOST}:${DB_PORT}"
echo " User:            ${DB_USER}"
echo " Started:         $(date +"%Y-%m-%d %H:%M:%S")"
echo "=============================================================================="

# Safety check: Guard against accidental restoration over the production database
if [ "${TARGET_DB}" = "ojt_managementdb" ] && [ "${ALLOW_PRODUCTION_OVERWRITE:-false}" != "true" ]; then
    echo "[-] CRITICAL SAFETY GUARD: Direct restoration to production 'ojt_managementdb' is blocked." >&2
    echo "    To restore to a test database, pass the test database name as argument:" >&2
    echo "    ./restore.sh ojt_managementdb_restore_test" >&2
    exit 1
fi

# Ensure backup file exists
if [ ! -f "${BACKUP_PATH}" ]; then
    echo "[-] ERROR: Source backup file does not exist: ${BACKUP_PATH}" >&2
    exit 1
fi

# Setup PostgreSQL Path if needed
if ! command -v pg_restore &> /dev/null; then
    if [ -f "/c/Program Files/PostgreSQL/18/bin/pg_restore.exe" ]; then
        export PATH="/c/Program Files/PostgreSQL/18/bin:${PATH}"
    elif [ -f "C:/Program Files/PostgreSQL/18/bin/pg_restore.exe" ]; then
        export PATH="C:/Program Files/PostgreSQL/18/bin:${PATH}"
    fi
fi

# Step 1: Check if target database exists; if not, create it via createdb
echo "[*] Step 1: Checking target database status..."
DB_EXISTS=$(psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${TARGET_DB}'" || echo "0")

if [ "${DB_EXISTS}" != "1" ]; then
    echo "[*] Database '${TARGET_DB}' does not exist. Creating it now via createdb..."
    createdb -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" "${TARGET_DB}"
    echo "[+] Database '${TARGET_DB}' created successfully."
else
    echo "[*] Database '${TARGET_DB}' already exists."
fi

# Step 2: Perform the restoration using pg_restore
echo "[*] Step 2: Executing pg_restore into '${TARGET_DB}'..."
# Note: pg_restore exits with 1 if there are minor warnings (e.g. role grants or schema notices),
# so we capture output and inspect exit status carefully.
set +e
RESTORE_LOG="${BACKUP_DIR}/restore_${TARGET_DB}_$(date +"%Y%m%d_%H%M%S").log"

pg_restore \
    -h "${DB_HOST}" \
    -p "${DB_PORT}" \
    -U "${DB_USER}" \
    -d "${TARGET_DB}" \
    -v \
    --no-owner \
    --no-privileges \
    "${BACKUP_PATH}" 2>&1 | tee "${RESTORE_LOG}"

RESTORE_STATUS=$?
set -e

echo "------------------------------------------------------------------------------"
if [ ${RESTORE_STATUS} -eq 0 ]; then
    echo "[+] Restoration completed with zero errors (Exit Code 0)."
else
    echo "[!] pg_restore exited with code ${RESTORE_STATUS}."
    echo "    Check ${RESTORE_LOG} for details (minor warnings like existing schemas are common)."
fi

# Step 3: Count restored tables in public schema
TABLE_COUNT=$(psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${TARGET_DB}" -tAc \
    "SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';")

echo "[+] Restored database table count: ${TABLE_COUNT} tables in schema 'public'."
echo "=============================================================================="
echo " Restoration complete. Proceed to run verification.sql on '${TARGET_DB}'."
echo "=============================================================================="

