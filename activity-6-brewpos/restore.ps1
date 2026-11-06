# ==============================================================================
# BrewPOS — Automated Database Restoration Script (PowerShell)
# Course   : COMP 018 — Database Administration
# Project  : BrewPOS — Café Point-of-Sale System
# Target   : PostgreSQL 18+ (Compatible with v16+)
# ==============================================================================

[CmdletBinding()]
param(
    [string]$HostName = "localhost",
    [int]$Port = 5432,
    [string]$Username = "postgres",
    [string]$TargetDatabase = "grp_brewposdb_restore_test",
    [string]$BackupFile = "C:\Users\Matt\pg_backups\brewpos\grp_brewposdb_activity6.dump",
    [string]$PgBinPath = "C:\Program Files\PostgreSQL\18\bin",
    [switch]$AllowExisting = $false
)

$ErrorActionPreference = "Stop"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " BrewPOS Database Restoration Execution — $TargetDatabase " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "Timestamp         : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Target Host       : ${HostName}:${Port}"
Write-Host "Database User     : $Username"
Write-Host "Target Database   : $TargetDatabase"
Write-Host "Source Dump File  : $BackupFile"

# 1. Resolve PostgreSQL binary paths
$psqlExe = Join-Path $PgBinPath "psql.exe"
$createdbExe = Join-Path $PgBinPath "createdb.exe"
$pgRestoreExe = Join-Path $PgBinPath "pg_restore.exe"

if (!(Test-Path $pgRestoreExe)) {
    $cmd = Get-Command "pg_restore" -ErrorAction SilentlyContinue
    if ($cmd) {
        $pgRestoreExe = $cmd.Source
        $createdbExe = (Get-Command "createdb").Source
        $psqlExe = (Get-Command "psql").Source
    } else {
        Write-Error "PostgreSQL tools not found at '$PgBinPath' or in system PATH."
        exit 1
    }
}

# 2. Verify source backup file exists
if (!(Test-Path $BackupFile)) {
    Write-Error "Source backup archive not found at '$BackupFile'!"
    exit 1
}

$fileItem = Get-Item $BackupFile
Write-Host "[INFO] Source archive size: $($fileItem.Length) bytes ($([math]::Round($fileItem.Length / 1KB, 2)) KB)"

# 3. Guard against accidental overwriting of existing databases
Write-Host "`n[1/3] Checking if target database '$TargetDatabase' exists..." -ForegroundColor Green
$dbExists = & $psqlExe -U $Username -h $HostName -p $Port -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$TargetDatabase';"
if ($dbExists.Trim() -eq "1") {
    if (!$AllowExisting) {
        Write-Error "[SAFETY ABORT] Database '$TargetDatabase' already exists! Automatic overwrite/drop is strictly prohibited to protect data integrity. Please choose a unique target database name or verify manually."
        exit 1
    } else {
        Write-Host "      Target database exists. Proceeding with caution (-AllowExisting specified)." -ForegroundColor Yellow
    }
} else {
    Write-Host "      Database does not exist. Safe to create." -ForegroundColor Green
    Write-Host "`n[2/3] Creating target database '$TargetDatabase'..." -ForegroundColor Green
    & $createdbExe -U $Username -h $HostName -p $Port $TargetDatabase
    if ($LASTEXITCODE -ne 0) {
        Write-Error "createdb failed with exit code $LASTEXITCODE."
        exit $LASTEXITCODE
    }
    Write-Host "      Database '$TargetDatabase' created successfully." -ForegroundColor Green
}

# 4. Execute pg_restore
Write-Host "`n[3/3] Executing pg_restore from custom-format archive..." -ForegroundColor Green
$startTime = Get-Date

try {
    & $pgRestoreExe -U $Username -h $HostName -p $Port -d $TargetDatabase --verbose $BackupFile 2>&1
    $restoreExitCode = $LASTEXITCODE
} catch {
    Write-Error "pg_restore failed with exception: $_"
    exit 1
}

$elapsed = (Get-Date) - $startTime
Write-Host "      pg_restore completed in $($elapsed.TotalSeconds.ToString('F2')) seconds."

if ($restoreExitCode -ne 0) {
    Write-Warning "pg_restore finished with exit code $restoreExitCode. Please inspect restoration warnings/errors above."
    exit $restoreExitCode
}

Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host " RESTORATION SUCCESSFUL — TARGET: $TargetDatabase " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "Next Step: Execute verification suite (verification.sql) against $TargetDatabase."

