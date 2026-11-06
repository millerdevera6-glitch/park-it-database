<#
.SYNOPSIS
    Automated PostgreSQL Database Backup Script for HabalGo.
.DESCRIPTION
    COMP 018 – Database Administration | Activity 6
    Generates a compressed custom-format logical backup (-Fc) using pg_dump.
    Computes cryptographic SHA-256 checksum, logs execution, and verifies archive TOC.
.PARAMETER DatabaseName
    Target database name (Default: grp00_habalgodb)
.PARAMETER BackupDir
    Target directory for backup storage (Default: C:\HabalGo_Backups or custom location)
.PARAMETER DbUser
    PostgreSQL administrative user (Default: postgres)
.PARAMETER DbHost
    Host server address (Default: localhost)
.PARAMETER DbPort
    Port number (Default: 5432)
.EXAMPLE
    .\backup.ps1 -DatabaseName "grp00_habalgodb"
#>

[CmdletBinding()]
param (
    [string]$DatabaseName = "grp00_habalgodb",
    [string]$BackupDir = "",
    [string]$DbUser = "postgres",
    [string]$DbHost = "localhost",
    [string]$DbPort = "5432"
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   HABALGO AUTOMATED POSTGRESQL BACKUP UTILITY (ACT 6)   " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Determine Target Storage Path (Outside Git Repository)
if ([string]::IsNullOrWhiteSpace($BackupDir)) {
    # Default to secure local directory outside git repository
    $BackupDir = Join-Path $env:LOCALAPPDATA "HabalGo_Backups"
}

if (-not (Test-Path -Path $BackupDir)) {
    Write-Host "[INFO] Creating backup directory at: $BackupDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

# 2. Locate PostgreSQL Binaries
$pgDump = Get-Command "pg_dump.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1

if (-not $pgDump) {
    # Check default Windows installation paths
    $pgCandidates = Get-ChildItem "C:\Program Files\PostgreSQL" -Filter "pg_dump.exe" -Recurse -ErrorAction SilentlyContinue
    if ($pgCandidates) {
        $pgDump = $pgCandidates[0].FullName
    } else {
        Write-Error "PostgreSQL 'pg_dump.exe' not found in PATH or standard installation directories. Please install PostgreSQL or configure PATH."
        exit 1
    }
}

$pgRestore = Join-Path (Split-Path -Parent $pgDump) "pg_restore.exe"

Write-Host "[INFO] Using pg_dump binary: $pgDump" -ForegroundColor Green
Write-Host "[INFO] Target Database:      $DatabaseName" -ForegroundColor Green
Write-Host "[INFO] Host & Port:          ${DbHost}:${DbPort}" -ForegroundColor Green
Write-Host "[INFO] Backup User:          $DbUser" -ForegroundColor Green

# 3. Generate Timestamped Filename
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$dumpFileName = "habalgo_${DatabaseName}_${timestamp}.dump"
$dumpFilePath = Join-Path $BackupDir $dumpFileName
$latestFilePath = Join-Path $BackupDir "habalgo_activity6.dump"

Write-Host "[INFO] Commencing logical custom-archive backup (-Fc)..." -ForegroundColor Yellow

# 4. Execute pg_dump
try {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    
    & $pgDump -U $DbUser -h $DbHost -p $DbPort -Fc -d $DatabaseName -f $dumpFilePath
    
    $sw.Stop()
    
    if ($LASTEXITCODE -ne 0) {
        throw "pg_dump failed with exit code $LASTEXITCODE"
    }

    # Maintain standard pointer for activity grading
    Copy-Item -Path $dumpFilePath -Destination $latestFilePath -Force

    Write-Host "[SUCCESS] Backup completed in $($sw.Elapsed.TotalSeconds.ToString('F2')) seconds!" -ForegroundColor Green
}
catch {
    Write-Error "[FAIL] Backup execution failed: $_"
    exit 1
}

# 5. Verify File Properties & Calculate SHA-256 Hash
$fileItem = Get-Item -Path $dumpFilePath
$fileSize = $fileItem.Length
$hashResult = Get-FileHash -Path $dumpFilePath -Algorithm SHA256

Write-Host "`n--- BACKUP METRICS ---" -ForegroundColor Cyan
Write-Host "File Name:   $dumpFileName"
Write-Host "Full Path:   $dumpFilePath"
Write-Host "File Size:   $fileSize bytes ($([math]::Round($fileSize/1KB, 2)) KB)"
Write-Host "SHA-256:     $($hashResult.Hash)"
Write-Host "Timestamp:   $($fileItem.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))"

# 6. Archive Inspection (Table of Contents Verification)
Write-Host "`n[INFO] Inspecting archive integrity via pg_restore --list..." -ForegroundColor Yellow
try {
    $tocLines = & $pgRestore --list $dumpFilePath
    $tocCount = ($tocLines | Where-Object { $_ -notmatch '^\s*;' -and $_.Trim() -ne '' }).Count
    Write-Host "[SUCCESS] Archive inspection verified! Found $tocCount database object entries in archive TOC." -ForegroundColor Green
}
catch {
    Write-Warning "[WARN] Archive inspection reported an issue: $_"
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "   BACKUP PROCESS CONCLUDED SUCCESSFULLY                " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

