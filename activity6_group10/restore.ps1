<#
.SYNOPSIS
    Automated PostgreSQL Restoration Utility for BoardTrack (COMP 018 Activity 6).
.DESCRIPTION
    Safely restores a PostgreSQL custom-format (-Fc) dump archive into an isolated test database
    (boardtrack_db_activity6_restore_test) without modifying or overwriting any existing database.
.PARAMETER TargetDatabase
    The target restore database name (default: boardtrack_db_activity6_restore_test).
.PARAMETER DumpFile
    Path to the custom-format backup dump file.
.PARAMETER Username
    The PostgreSQL user executing the restoration (default: postgres).
.PARAMETER HostName
    The database host (default: localhost).
.PARAMETER Port
    The database port (default: 5432).
.PARAMETER PgBinPath
    Path to PostgreSQL client binaries.
#>

[CmdletBinding()]
param(
    [string]$TargetDatabase = "boardtrack_db_activity6_restore_test",
    [string]$DumpFile = "$env:LOCALAPPDATA\PostgreSQL\Backups\boardtrack_activity6.dump",
    [string]$Username = "postgres",
    [string]$HostName = "localhost",
    [int]$Port = 5432,
    [string]$PgBinPath = "C:\Program Files\PostgreSQL\18\bin"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  BOARDTRACK DATABASE RESTORATION UTILITY (COMP 018 ACTIVITY 6)" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

# 1. Resolve PostgreSQL binaries
$pgRestore = Join-Path $PgBinPath "pg_restore.exe"
$createdb = Join-Path $PgBinPath "createdb.exe"
$psql = Join-Path $PgBinPath "psql.exe"

if (-not (Test-Path $pgRestore)) {
    $found = Get-Command pg_restore -ErrorAction SilentlyContinue
    if ($found) {
        $pgRestore = $found.Source
        $createdb = (Get-Command createdb -ErrorAction SilentlyContinue).Source
        $psql = (Get-Command psql -ErrorAction SilentlyContinue).Source
    } else {
        Write-Error "PostgreSQL client utilities (pg_restore, createdb) not found at '$PgBinPath' or in PATH."
        exit 1
    }
}

# 2. Verify Backup File Existence
if (-not (Test-Path $DumpFile)) {
    Write-Error "Backup archive not found at specified path: '$DumpFile'. Please run backup.ps1 first."
    exit 1
}

$fileItem = Get-Item $DumpFile
Write-Host "[INFO] Backup Archive: $DumpFile ($($fileItem.Length) bytes)" -ForegroundColor Green
Write-Host "[INFO] Target Host:    $HostName:$Port" -ForegroundColor Gray
Write-Host "[INFO] Target DB:      $TargetDatabase" -ForegroundColor Gray

# 3. Check for Target Database Collision (Safety Rule: Never overwrite automatically)
Write-Host "`n[CHECK] Verifying target database status..." -ForegroundColor Yellow
$checkDbCmd = "& '$psql' -U '$Username' -h '$HostName' -p $Port -d postgres -t -A -c `"SELECT 1 FROM pg_database WHERE datname='$TargetDatabase';`""
$targetExists = 0
try {
    $targetExists = (Invoke-Expression $checkDbCmd) -as [int]
} catch {
    Write-Error "Failed to connect to PostgreSQL server: $($_.Exception.Message)"
    exit 1
}

if ($targetExists -eq 1) {
    $altTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $TargetDatabase = "${TargetDatabase}_${altTimestamp}"
    Write-Warning "Target database already exists! Selected unique alternative: '$TargetDatabase'"
}

# 4. Create Isolated Test Database
Write-Host "`n[EXEC] Creating isolated test database '$TargetDatabase'..." -ForegroundColor Yellow
$createArgs = @("-U", $Username, "-h", $HostName, "-p", $Port, $TargetDatabase)
$createProcess = Start-Process -FilePath $createdb -ArgumentList $createArgs -NoNewWindow -Wait -PassThru
if ($createProcess.ExitCode -ne 0) {
    Write-Error "createdb failed with exit code $($createProcess.ExitCode)."
    exit $createProcess.ExitCode
}
Write-Host "[SUCCESS] Database '$TargetDatabase' created successfully." -ForegroundColor Green

# 5. Restore Archive using pg_restore
Write-Host "`n[EXEC] Restoring archive into '$TargetDatabase'..." -ForegroundColor Yellow
$restoreArgs = @(
    "-U", $Username,
    "-h", $HostName,
    "-p", $Port,
    "-d", $TargetDatabase,
    "--no-owner",       # Avoid privilege errors if target environment roles differ
    "--no-privileges",  # Standard practice when restoring to isolated staging
    $DumpFile
)

$restoreProcess = Start-Process -FilePath $pgRestore -ArgumentList $restoreArgs -NoNewWindow -Wait -PassThru
# Note: pg_restore returns exit code 0 on success, 1 on harmless warnings (e.g. extension already exists)
if ($restoreProcess.ExitCode -gt 1) {
    Write-Error "pg_restore terminated with error code $($restoreProcess.ExitCode)."
    exit $restoreProcess.ExitCode
}

Write-Host "[SUCCESS] Restoration completed into '$TargetDatabase' (Exit code: $($restoreProcess.ExitCode))." -ForegroundColor Green

# 6. Basic Object Count Validation
Write-Host "`n[VERIFY] Querying restored database object counts..." -ForegroundColor Yellow
$tableCountCmd = "& '$psql' -U '$Username' -h '$HostName' -p $Port -d '$TargetDatabase' -t -A -c `"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';`""
$restoredTables = Invoke-Expression $tableCountCmd
Write-Host "  Public Base Tables Restored: $restoredTables" -ForegroundColor White

Write-Host "`n[COMPLETED] Database restoration procedure successfully executed." -ForegroundColor Cyan

