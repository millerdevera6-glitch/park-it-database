#!/usr/bin/env bash
# ==============================================================================
# COMP 018 – Database Administration | Activity 6
# Script: backup.sh
# Purpose: Create a PostgreSQL custom archive backup (-Fc) of ojt_managementdb,
#          calculate cryptographic SHA-256 checksum, record metadata, and
#          verify archive integrity using pg_restore --list.
# ==============================================================================

set -euo pipefail

# Configuration defaults (can be overridden via environment variables)
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-ojt_managementdb}"
DB_USER="${DB_USER:-postgres}"

# Output directory and file naming
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/backups"
TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
BACKUP_FILENAME="${BACKUP_FILENAME:-ojt_managementdb_activity6.dump}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILENAME}"
CHECKSUM_PATH="${BACKUP_PATH}.sha256"
METADATA_PATH="${BACKUP_PATH}.meta.txt"

# Ensure backup directory exists
mkdir -p "${BACKUP_DIR}"

echo "=============================================================================="
echo " Starting Database Backup Process"
echo " Database: ${DB_NAME}"
echo " Host:     ${DB_HOST}:${DB_PORT}"
echo " User:     ${DB_USER}"
echo " Format:   Custom Archive (-Fc)"
echo " Target:   ${BACKUP_PATH}"
echo " Started:  $(date +"%Y-%m-%d %H:%M:%S")"
echo "=============================================================================="

# Check for pg_dump availability
if ! command -v pg_dump &> /dev/null; then
    # Check standard Windows PostgreSQL binary paths if in Git Bash / MSYS
    if [ -f "/c/Program Files/PostgreSQL/18/bin/pg_dump.exe" ]; then
        export PATH="/c/Program Files/PostgreSQL/18/bin:${PATH}"
    elif [ -f "C:/Program Files/PostgreSQL/18/bin/pg_dump.exe" ]; then
        export PATH="C:/Program Files/PostgreSQL/18/bin:${PATH}"
    else
        echo "[-] ERROR: 'pg_dump' utility not found in PATH." >&2
        echo "    Please install PostgreSQL client tools or update your PATH." >&2
        exit 1
    fi
fi

# Step 1: Execute pg_dump with custom archive format (-Fc)
echo "[*] Step 1: Generating PostgreSQL custom dump..."
pg_dump \
    -h "${DB_HOST}" \
    -p "${DB_PORT}" \
    -U "${DB_USER}" \
    -d "${DB_NAME}" \
    -Fc \
    -v \
    -f "${BACKUP_PATH}"

if [ ! -f "${BACKUP_PATH}" ]; then
    echo "[-] ERROR: Backup file was not created." >&2
    exit 1
fi

# Step 2: Compute file size and timestamp
FILE_SIZE=$(wc -c < "${BACKUP_PATH}" | tr -d ' ')
echo "[+] Backup successfully created!"
echo "    File: ${BACKUP_FILENAME}"
echo "    Size: ${FILE_SIZE} bytes"

# Step 3: Compute SHA-256 checksum
echo "[*] Step 2: Computing SHA-256 cryptographic checksum..."
if command -v sha256sum &> /dev/null; then
    sha256sum "${BACKUP_PATH}" > "${CHECKSUM_PATH}"
elif command -v shasum &> /dev/null; then
    shasum -a 256 "${BACKUP_PATH}" > "${CHECKSUM_PATH}"
else
    # Fallback to certutil on Windows
    certutil -hashfile "${BACKUP_PATH}" SHA256 | grep -v "hash" | head -n 1 | tr -d ' ' > "${CHECKSUM_PATH}"
fi
CHECKSUM_VALUE=$(awk '{print $1}' "${CHECKSUM_PATH}")
echo "[+] SHA-256: ${CHECKSUM_VALUE}"

# Step 4: Verify archive Table of Contents using pg_restore --list
echo "[*] Step 3: Inspecting archive Table of Contents (pg_restore --list)..."
TOC_OUTPUT=$(pg_restore --list "${BACKUP_PATH}")
TOC_COUNT=$(echo "${TOC_OUTPUT}" | grep -v '^;' | grep -v '^$' | wc -l | tr -d ' ')

echo "[+] Archive TOC verified: ${TOC_COUNT} catalog items detected."

# Save metadata summary
cat <<EOF > "${METADATA_PATH}"
Database: ${DB_NAME}
Timestamp: $(date +"%Y-%m-%d %H:%M:%S")
Host: ${DB_HOST}:${DB_PORT}
User: ${DB_USER}
Format: PostgreSQL Custom Archive (-Fc)
Filename: ${BACKUP_FILENAME}
SizeBytes: ${FILE_SIZE}
SHA256: ${CHECKSUM_VALUE}
TOCCount: ${TOC_COUNT}
EOF

echo "=============================================================================="
echo " Backup operation completed successfully."
echo " Checksum file: ${CHECKSUM_PATH}"
echo " Metadata file: ${METADATA_PATH}"
echo "=============================================================================="

