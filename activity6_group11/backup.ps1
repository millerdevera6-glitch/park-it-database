<#
.SYNOPSIS
    Automated PostgreSQL Database Backup Script for BoardTrack.
.DESCRIPTION
    Executes a consistent, compressed logical backup of the BoardTrack PostgreSQL
    database using pg_dump custom archive format (-Fc). Computes cryptographic
    checksums and validates archive integrity via pg_restore --list.
.PARAMETER Database
    Target PostgreSQL database name (Default: boardtrack_db).
.PARAMETER Username
    PostgreSQL user account for execution (Default: postgres).
.PARAMETER Host
    Database server hostname (Default: localhost).
.PARAMETER Port
    Database server port (Default: 5432).
.PARAMETER BackupDir
    Destination directory for backup archives (Default: .\backups).
.EXAMPLE
    .\backup.ps1 -Database boardtrack_db -Username postgres
#>

[CmdletBinding()]
param(
    [string]$Database = "boardtrack_db",
    [string]$Username = "postgres",
    [string]$HostName = "localhost",
    [int]$Port = 5432,
    [string]$BackupDir = "backups"
)

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " BoardTrack Database Backup Procedure (COMP 018 Activity 6)" -ForegroundColor Cyan
Write-Host " Target Database: $Database" -ForegroundColor Cyan
Write-Host " Host: ${HostName}:${Port}" -ForegroundColor Cyan
Write-Host " User: $Username" -ForegroundColor Cyan
Write-Host " Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
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
    if (Test-Path (Join-Path $path "pg_dump.exe")) {
        $pgBin = $path
        break
    }
}

if (-not $pgBin) {
    $cmd = Get-Command "pg_dump" -ErrorAction SilentlyContinue
    if ($cmd) {
        $pgBin = Split-Path $cmd.Source
    }
}

if (-not $pgBin) {
    Write-Error "CRITICAL: PostgreSQL binaries (pg_dump.exe) were not found. Ensure PostgreSQL is installed."
    exit 1
}

$pgDump = Join-Path $pgBin "pg_dump.exe"
$pgRestore = Join-Path $pgBin "pg_restore.exe"
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

# 3. Verify Target Database Existence
Write-Host "[3/6] Verifying presence of target database '$Database'..." -ForegroundColor Yellow
$checkSql = "SELECT 1 FROM pg_database WHERE datname = '$Database';"
$dbExistsOutput = & $psql -U $Username -h $HostName -p $Port -d postgres -t -c $checkSql 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Warning "Failed to query catalog to verify database existence. Error: $dbExistsOutput"
    Write-Error "Authentication or permission check failed. Aborting."
    exit 1
}

if (-not ($dbExistsOutput.Trim() -eq "1")) {
    Write-Warning "================================================================="
    Write-Warning " STOP-CONDITION TRIGGERED: DATABASE DOES NOT EXIST ON CLUSTER"
    Write-Warning " Database '$Database' was not found on the PostgreSQL server."
    Write-Warning " Per COMP 018 Safety Rule 3: 'Never initialize or reseed the original database'"
    Write-Warning " and Phase 3: 'If it does not exist, stop database execution. Do not initialize or recreate it.'"
    Write-Warning " Halting backup execution to prevent unvetted database creation."
    Write-Warning "================================================================="
    exit 2
}

Write-Host "      Target database '$Database' confirmed on cluster." -ForegroundColor Green

# 4. Prepare Destination Storage Directory
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$dumpFileName = "boardtrack_${Database}_${timestamp}.dump"
$dumpFilePath = Join-Path $BackupDir $dumpFileName

# 5. Execute Logical Backup using Custom Archive Format (-Fc)
Write-Host "[4/6] Executing pg_dump custom archive backup (-Fc)..." -ForegroundColor Yellow
Write-Host "      Command: pg_dump -U $Username -h $HostName -p $Port -Fc -d $Database -f `"$dumpFilePath`""
& $pgDump -U $Username -h $HostName -p $Port -Fc -d $Database -f $dumpFilePath

if ($LASTEXITCODE -ne 0) {
    Write-Error "CRITICAL: pg_dump failed with exit code $LASTEXITCODE."
    exit 1
}

$fileItem = Get-Item $dumpFilePath
Write-Host "      Backup generated successfully." -ForegroundColor Green
Write-Host "      File: $($fileItem.FullName)" -ForegroundColor Green
Write-Host "      Size: $($fileItem.Length) bytes ($([Math]::Round($fileItem.Length / 1KB, 2)) KB)" -ForegroundColor Green

# 6. Integrity Verification: SHA-256 Checksum & TOC Inspection
Write-Host "[5/6] Calculating cryptographic SHA-256 hash..." -ForegroundColor Yellow
$hashResult = Get-FileHash -Path $dumpFilePath -Algorithm SHA256
$sha256 = $hashResult.Hash
Write-Host "      SHA-256: $sha256" -ForegroundColor Green

# Save checksum file alongside dump
$checksumFile = "$dumpFilePath.sha256"
"$sha256  $dumpFileName" | Set-Content -Path $checksumFile -Encoding ASCII

Write-Host "[6/6] Inspecting archive Table of Contents (pg_restore --list)..." -ForegroundColor Yellow
$tocOutput = & $pgRestore --list $dumpFilePath
if ($LASTEXITCODE -ne 0) {
    Write-Error "CRITICAL: Archive inspection failed. The dump file may be corrupted."
    exit 1
}

$tocSummaryFile = "$dumpFilePath.toc.txt"
$tocOutput | Set-Content -Path $tocSummaryFile

Write-Host "      TOC parsed successfully ($($tocOutput.Count) archive items recorded)." -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " Backup Process Completed Successfully!" -ForegroundColor Cyan
Write-Host " Dump File:     $dumpFilePath" -ForegroundColor Cyan
Write-Host " Checksum File: $checksumFile" -ForegroundColor Cyan
Write-Host " TOC File:      $tocSummaryFile" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

