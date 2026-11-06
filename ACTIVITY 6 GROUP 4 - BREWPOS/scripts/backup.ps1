# BrewPOS Activity 6 - PostgreSQL Backup Script
# Run from PowerShell.
# Password is requested interactively by pg_dump.

$PgBin = "C:\Program Files\PostgreSQL\14\bin"
$BackupDir = "C:\DB_Backups\BrewPOS"
$Database = "grp_brewposdb"
$Timestamp = Get-Date -Format "yyyy-MM-dd"
$BackupFile = Join-Path $BackupDir "${Database}_${Timestamp}.dump"

# Ensure backup directory exists.
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

# Create custom-format backup.
& "$PgBin\pg_dump.exe" -U postgres -d $Database -F c -f $BackupFile

if ($LASTEXITCODE -ne 0) {
    Write-Error "Backup failed. Exit code: $LASTEXITCODE"
    exit $LASTEXITCODE
}

# Display backup information.
Get-Item $BackupFile | Select-Object Name, Length, LastWriteTime

# Calculate SHA-256 checksum.
Get-FileHash $BackupFile -Algorithm SHA256

# Inspect archive contents.
& "$PgBin\pg_restore.exe" --list $BackupFile

if ($LASTEXITCODE -ne 0) {
    Write-Error "Archive inspection failed."
    exit $LASTEXITCODE
}

Write-Host "Backup and archive inspection completed successfully."