# BrewPOS Activity 6 - PostgreSQL Restore Script
# Run from PowerShell.
# This script restores only into a separate test database.

$PgBin = "C:\Program Files\PostgreSQL\14\bin"
$BackupFile = "C:\DB_Backups\BrewPOS\grp_brewposdb_2026-11-06.dump"
$TargetDatabase = "grp_brewposdb_restore_test"
$OriginalDatabase = "grp_brewposdb"

# Safety check: never restore into the original database.
if ($TargetDatabase -eq $OriginalDatabase) {
    Write-Error "Refusing to restore into the original database."
    exit 1
}

# Check that the backup file exists.
if (!(Test-Path $BackupFile)) {
    Write-Error "Backup archive not found: $BackupFile"
    exit 1
}

# Check that the target database exists.
$exists = & "$PgBin\psql.exe" -U postgres -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$TargetDatabase';"

if ($exists -notmatch "1") {
    Write-Error "Target database does not exist. Create an empty test database first."
    exit 1
}

Write-Host "Restoring backup into $TargetDatabase ..."

# Restore without changing ownership or applying archived ACLs.
& "$PgBin\pg_restore.exe" -U postgres -d $TargetDatabase --no-owner --no-acl $BackupFile

if ($LASTEXITCODE -ne 0) {
    Write-Error "Restore failed. Exit code: $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "Restore command completed successfully."
Write-Host "Run verification.sql to check the restored database."