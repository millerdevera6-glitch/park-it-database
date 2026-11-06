# ==============================================================================
# COMP 018 – Database Administration | Activity 6
# Script: restore.ps1
# Purpose: Safely restore a PostgreSQL custom archive backup (-Fc) into an
#          isolated test database (default: ojt_managementdb_restore_test) on Windows.
# ==============================================================================

[CmdletBinding()]
param(
    [string]$DbHost = "localhost",
    [string]$DbPort = "5432",
    [string]$TargetDb = "ojt_managementdb_restore_test",
    [string]$DbUser = "postgres",
    [string]$BackupFilename = "ojt_managementdb_activity6.dump"
)

$ErrorActionPreference = "Stop"

# Setup PostgreSQL Path
$PgBinPath = "C:\Program Files\PostgreSQL\18\bin"
if (Test-Path $PgBinPath) {
    if ($env:Path -notlike "*$PgBinPath*") {
        $env:Path = "$PgBinPath;$env:Path"
    }
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackupDir = Join-Path $ScriptDir "backups"
$BackupPath = Join-Path $BackupDir $BackupFilename

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host " Starting Database Restoration Process (PowerShell)" -ForegroundColor Cyan
Write-Host " Target Database: $TargetDb"
Write-Host " Source Backup:   $BackupPath"
Write-Host " Host:            ${DbHost}:${DbPort}"
Write-Host " User:            $DbUser"
Write-Host " Started:         $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "==============================================================================" -ForegroundColor Cyan

# Safety guard
if ($TargetDb -eq "ojt_managementdb" -and $env:ALLOW_PRODUCTION_OVERWRITE -ne "true") {
    throw "CRITICAL SAFETY GUARD: Direct restore to production 'ojt_managementdb' is blocked."
}

if (-not (Test-Path $BackupPath)) {
    throw "Source backup file not found: $BackupPath"
}

# Step 1: Check if target database exists
Write-Host "[*] Step 1: Checking target database status..." -ForegroundColor Yellow
$checkSql = "SELECT 1 FROM pg_database WHERE datname='$TargetDb';"
$dbExists = & psql.exe -h $DbHost -p $DbPort -U $DbUser -d postgres -tAc $checkSql 2>$null

if ($dbExists.Trim() -ne "1") {
    Write-Host "[*] Database '$TargetDb' does not exist. Creating via createdb.exe..." -ForegroundColor Yellow
    & createdb.exe -h $DbHost -p $DbPort -U $DbUser $TargetDb
    Write-Host "[+] Database '$TargetDb' created successfully." -ForegroundColor Green
} else {
    Write-Host "[*] Database '$TargetDb' exists."
}

# Step 2: Restore using pg_restore
Write-Host "[*] Step 2: Executing pg_restore into '$TargetDb'..." -ForegroundColor Yellow
$restoreLog = Join-Path $BackupDir "restore_${TargetDb}_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

& pg_restore.exe -h $DbHost -p $DbPort -U $DbUser -d $TargetDb -v --no-owner --no-privileges $BackupPath 2>&1 | Tee-Object -FilePath $restoreLog

# Step 3: Count restored tables
$countSql = "SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';"
$tableCount = & psql.exe -h $DbHost -p $DbPort -U $DbUser -d $TargetDb -tAc $countSql

Write-Host "------------------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "[+] Restored database table count: $tableCount tables in schema 'public'." -ForegroundColor Green
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host " Restoration complete. Proceed to run verification.sql on '$TargetDb'." -ForegroundColor Green

