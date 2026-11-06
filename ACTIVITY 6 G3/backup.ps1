# ==============================================================================
# COMP 018 – Database Administration | Activity 6
# Script: backup.ps1
# Purpose: Create a PostgreSQL custom archive backup (-Fc) of ojt_managementdb,
#          calculate cryptographic SHA-256 checksum, record metadata, and
#          verify archive integrity using pg_restore --list on Windows PowerShell.
# ==============================================================================

[CmdletBinding()]
param(
    [string]$DbHost = "localhost",
    [string]$DbPort = "5432",
    [string]$DbName = "ojt_managementdb",
    [string]$DbUser = "postgres",
    [string]$BackupFilename = "ojt_managementdb_activity6.dump"
)

$ErrorActionPreference = "Stop"

# Setup PostgreSQL Path if needed
$PgBinPath = "C:\Program Files\PostgreSQL\18\bin"
if (Test-Path $PgBinPath) {
    if ($env:Path -notlike "*$PgBinPath*") {
        $env:Path = "$PgBinPath;$env:Path"
    }
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackupDir = Join-Path $ScriptDir "backups"
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

$BackupPath = Join-Path $BackupDir $BackupFilename
$ChecksumPath = "$BackupPath.sha256"
$MetadataPath = "$BackupPath.meta.txt"

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host " Starting Database Backup Process (PowerShell)" -ForegroundColor Cyan
Write-Host " Database: $DbName"
Write-Host " Host:     ${DbHost}:${DbPort}"
Write-Host " User:     $DbUser"
Write-Host " Format:   Custom Archive (-Fc)"
Write-Host " Target:   $BackupPath"
Write-Host " Started:  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "==============================================================================" -ForegroundColor Cyan

# Step 1: Execute pg_dump
Write-Host "[*] Step 1: Generating PostgreSQL custom dump..." -ForegroundColor Yellow
$pgDump = Get-Command "pg_dump.exe" -ErrorAction SilentlyContinue
if (-not $pgDump) {
    throw "pg_dump.exe not found in PATH or standard directory ($PgBinPath)."
}

& pg_dump.exe -h $DbHost -p $DbPort -U $DbUser -d $DbName -Fc -v -f $BackupPath

if (-not (Test-Path $BackupPath)) {
    throw "Backup failed: $BackupPath was not created."
}

# Step 2: File size & SHA-256
$fileItem = Get-Item $BackupPath
$fileSize = $fileItem.Length
Write-Host "[+] Backup file created: $($fileItem.Name) ($fileSize bytes)" -ForegroundColor Green

Write-Host "[*] Step 2: Computing SHA-256 cryptographic checksum..." -ForegroundColor Yellow
$hashResult = (Get-FileHash -Path $BackupPath -Algorithm SHA256).Hash.ToLower()
"$hashResult  $($fileItem.Name)" | Out-File -FilePath $ChecksumPath -Encoding utf8
Write-Host "[+] SHA-256: $hashResult" -ForegroundColor Green

# Step 3: Archive inspection
Write-Host "[*] Step 3: Inspecting archive Table of Contents (pg_restore --list)..." -ForegroundColor Yellow
$toc = & pg_restore.exe --list $BackupPath
$tocCount = ($toc | Where-Object { $_ -notmatch '^;' -and $_.Trim() -ne '' }).Count
Write-Host "[+] Archive TOC verified: $tocCount catalog entries found." -ForegroundColor Green

# Save metadata
@"
Database: $DbName
Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Host: ${DbHost}:${DbPort}
User: $DbUser
Format: PostgreSQL Custom Archive (-Fc)
Filename: $($fileItem.Name)
SizeBytes: $fileSize
SHA256: $hashResult
TOCCount: $tocCount
"@ | Out-File -FilePath $MetadataPath -Encoding utf8

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host " Backup operation completed successfully." -ForegroundColor Green
Write-Host " Checksum file: $ChecksumPath"
Write-Host " Metadata file: $MetadataPath"
Write-Host "==============================================================================" -ForegroundColor Cyan

