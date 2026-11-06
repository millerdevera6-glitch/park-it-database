<#
.SYNOPSIS
    Automated PostgreSQL Database Restoration Script for BoardTrack.
.DESCRIPTION
    Restores a BoardTrack custom archive backup (-Fc) into an isolated test database
    (boardtrack_db_activity6_restore_test) to preserve the original database state.
.PARAMETER TargetDatabase
    Name of test database to create and restore into (Default: boardtrack_db_activity6_restore_test).
.PARAMETER DumpFile
    Path to pg_dump custom archive file (Default: .\backups\boardtrack_activity6.dump).
.PARAMETER Username
    PostgreSQL administrative user account (Default: postgres).
.PARAMETER Host
    Database server hostname (Default: localhost).
.PARAMETER Port
    Database server port (Default: 5432).
.EXAMPLE
    .\restore.ps1 -TargetDatabase boardtrack_db_activity6_restore_test -DumpFile .\backups\boardtrack_activity6.dump
#>

[CmdletBinding()]
param(
    [string]$TargetDatabase = "boardtrack_db_activity6_restore_test",
    [string]$DumpFile = "backups\boardtrack_activity6.dump",
    [string]$Username = "postgres",
    [string]$HostName = "localhost",
    [int]$Port = 5432
)

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " BoardTrack Database Restoration Procedure (COMP 018 Activity 6)" -ForegroundColor Cyan
Write-Host " Target Test Database: $TargetDatabase" -ForegroundColor Cyan
Write-Host " Source Dump File:     $DumpFile" -ForegroundColor Cyan
Write-Host " Host:                 ${HostName}:${Port}" -ForegroundColor Cyan
Write-Host " User:                 $Username" -ForegroundColor Cyan
Write-Host " Timestamp:            $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Locate PostgreSQL Binaries
$pgBinPaths = @(
    "C:\Program Files\PostgreSQL\18\bin",
    "C:\Program Files\PostgreSQL\17\bin",
    "C:\Program Files\PostgreSQL\16\bin",
    "C:\Program Files\PostgreSQL\15\bin"
)

$pgBin = $null
foreach ($path in $pgBinPaths) {
    if (Test-Path (Join-Path $path "pg_restore.exe")) {
        $pgBin = $path
        break
    }
}

if (-not $pgBin) {
    $cmd = Get-Command "pg_restore" -ErrorAction SilentlyContinue
    if ($cmd) {
        $pgBin = Split-Path $cmd.Source
    }
}

if (-not $pgBin) {
    Write-Error "CRITICAL: PostgreSQL binaries (pg_restore.exe) were not found."
    exit 1
}

$pgRestore = Join-Path $pgBin "pg_restore.exe"
$createdb = Join-Path $pgBin "createdb.exe"
$psql = Join-Path $pgBin "psql.exe"
$pgIsReady = Join-Path $pgBin "pg_isready.exe"

Write-Host "[1/6] Verified PostgreSQL binaries located at: $pgBin" -ForegroundColor Green

# 2. Verify Database Server Readiness
Write-Host "[2/6] Checking database server connectivity on ${HostName}:${Port}..." -ForegroundColor Yellow
& $pgIsReady -h $HostName -p $Port | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "CRITICAL: PostgreSQL server is not accepting connections on ${HostName}:${Port}."
    exit 1
}
Write-Host "      PostgreSQL service is active and responsive." -ForegroundColor Green

# 3. Check Prerequisite: Source Dump File Existence
Write-Host "[3/6] Verifying presence of backup dump file: '$DumpFile'..." -ForegroundColor Yellow
if (-not (Test-Path $DumpFile)) {
    Write-Warning "================================================================="
    Write-Warning " PREREQUISITE MISSING: BACKUP DUMP FILE NOT FOUND"
    Write-Warning " Dump file '$DumpFile' does not exist."
    Write-Warning " Cause: Phase 3 halted backup extraction because target database 'boardtrack_db'"
    Write-Warning " was unprovisioned on the live cluster (in accordance with Safety Rule 3)."
    Write-Warning " Cannot restore a non-existent backup file into '$TargetDatabase'."
    Write-Warning " Halting restoration procedure safely."
    Write-Warning "================================================================="
    exit 3
}

$fileItem = Get-Item $DumpFile
Write-Host "      Found dump file ($($fileItem.Length) bytes)." -ForegroundColor Green

# 4. Target Database Existence Guard
Write-Host "[4/6] Verifying that target database '$TargetDatabase' does not collide..." -ForegroundColor Yellow
$checkTargetSql = "SELECT 1 FROM pg_database WHERE datname = '$TargetDatabase';"
$targetExists = & $psql -U $Username -h $HostName -p $Port -d postgres -t -c $checkTargetSql 2>&1

if ($targetExists.Trim() -eq "1") {
    Write-Warning "================================================================="
    Write-Warning " COLLISION GUARD TRIGGERED: TARGET DATABASE ALREADY EXISTS"
    Write-Warning " Target database '$TargetDatabase' already exists on the cluster."
    Write-Warning " Per COMP 018 Safety Rule 2: 'Never overwrite or reset an existing database automatically.'"
    Write-Warning " Aborting operation. Choose a unique target database name or review manually."
    Write-Warning "================================================================="
    exit 4
}
Write-Host "      Target database '$TargetDatabase' name is available." -ForegroundColor Green

# 5. Create Target Test Database
Write-Host "[5/6] Creating isolated test database '$TargetDatabase'..." -ForegroundColor Yellow
Write-Host "      Command: createdb -U $Username -h $HostName -p $Port $TargetDatabase"
& $createdb -U $Username -h $HostName -p $Port $TargetDatabase

if ($LASTEXITCODE -ne 0) {
    Write-Error "CRITICAL: createdb failed to create database '$TargetDatabase'."
    exit 1
}
Write-Host "      Test database '$TargetDatabase' created successfully." -ForegroundColor Green

# 6. Execute Restoration using pg_restore
Write-Host "[6/6] Executing pg_restore into '$TargetDatabase'..." -ForegroundColor Yellow
Write-Host "      Command: pg_restore -U $Username -h $HostName -p $Port -d $TargetDatabase -v `"$DumpFile`""
$restoreLog = & $pgRestore -U $Username -h $HostName -p $Port -d $TargetDatabase -v $DumpFile 2>&1

$restoreLogFile = "restore_${TargetDatabase}_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$restoreLog | Set-Content -Path $restoreLogFile

Write-Host "      pg_restore completed with exit code: $LASTEXITCODE" -ForegroundColor Green
Write-Host "      Restoration execution log written to: $restoreLogFile" -ForegroundColor Green

if ($LASTEXITCODE -ne 0) {
    Write-Warning "pg_restore reported warnings or non-critical errors. Review $restoreLogFile for details."
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " Restoration Process Completed!" -ForegroundColor Cyan
Write-Host " Target Database: $TargetDatabase" -ForegroundColor Cyan
Write-Host " Log File:       $restoreLogFile" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

