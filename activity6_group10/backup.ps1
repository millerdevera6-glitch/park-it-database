<#
.SYNOPSIS
    Automated PostgreSQL Logical Backup Script for BoardTrack (COMP 018 Activity 6).
.DESCRIPTION
    Creates a compressed, custom-format (-Fc) logical backup of the specified PostgreSQL database
    using pg_dump, verifies file integrity, computes a SHA-256 cryptographic checksum, and inspects
    the archive Table of Contents (TOC) using pg_restore --list.
.PARAMETER DatabaseName
    The target database name (default: boardtrack_db).
.PARAMETER Username
    The PostgreSQL user executing the backup (default: postgres).
.PARAMETER HostName
    The database host (default: localhost).
.PARAMETER Port
    The database port (default: 5432).
.PARAMETER BackupDirectory
    Directory to store the backup archive outside git (default: $env:LOCALAPPDATA\PostgreSQL\Backups).
.PARAMETER PgBinPath
    Path to PostgreSQL client binaries.
#>

[CmdletBinding()]
param(
    [string]$DatabaseName = "boardtrack_db",
    [string]$Username = "postgres",
    [string]$HostName = "localhost",
    [int]$Port = 5432,
    [string]$BackupDirectory = "$env:LOCALAPPDATA\PostgreSQL\Backups",
    [string]$PgBinPath = "C:\Program Files\PostgreSQL\18\bin"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  BOARDTRACK DATABASE BACKUP UTILITY (COMP 018 ACTIVITY 6)" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

# 1. Resolve PostgreSQL binaries
$pgDump = Join-Path $PgBinPath "pg_dump.exe"
$pgRestore = Join-Path $PgBinPath "pg_restore.exe"
$psql = Join-Path $PgBinPath "psql.exe"

if (-not (Test-Path $pgDump)) {
    $found = Get-Command pg_dump -ErrorAction SilentlyContinue
    if ($found) {
        $pgDump = $found.Source
        $pgRestore = (Get-Command pg_restore -ErrorAction SilentlyContinue).Source
        $psql = (Get-Command psql -ErrorAction SilentlyContinue).Source
    } else {
        Write-Error "PostgreSQL client utilities (pg_dump) not found at '$PgBinPath' or in PATH."
        exit 1
    }
}

# 2. Ensure Backup Directory Exists (Outside Git Repository)
if (-not (Test-Path $BackupDirectory)) {
    New-Item -ItemType Directory -Path $BackupDirectory -Force | Out-Null
    Write-Host "[INFO] Created backup directory: $BackupDirectory" -ForegroundColor Green
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$dumpFileName = "boardtrack_activity6_${timestamp}.dump"
$dumpFilePath = Join-Path $BackupDirectory $dumpFileName
$symlinkOrCanonical = Join-Path $BackupDirectory "boardtrack_activity6.dump"

Write-Host "[INFO] Target Host:     $HostName:$Port" -ForegroundColor Gray
Write-Host "[INFO] Target Database: $DatabaseName" -ForegroundColor Gray
Write-Host "[INFO] Backup Format:   PostgreSQL Custom Archive (-Fc)" -ForegroundColor Gray
Write-Host "[INFO] Output Path:     $dumpFilePath" -ForegroundColor Gray

# 3. Verify Database Existence (DBA Safety Rule: Do not execute against missing database)
Write-Host "`n[CHECK] Verifying database existence on host..." -ForegroundColor Yellow
$checkDbCmd = "& '$psql' -U '$Username' -h '$HostName' -p $Port -d postgres -t -A -c `"SELECT 1 FROM pg_database WHERE datname='$DatabaseName';`""
try {
    $dbExists = (Invoke-Expression $checkDbCmd) -as [int]
} catch {
    Write-Warning "Failed to connect to PostgreSQL server on $HostName:$Port. Ensure server is running."
    Write-Warning $_.Exception.Message
    exit 1
}

if ($dbExists -ne 1) {
    Write-Host "[SAFETY HALT] Database '$DatabaseName' does not exist in PostgreSQL cluster." -ForegroundColor Red
    Write-Host "DBA Safety Directives strictly forbid auto-initializing or reseeding original production data." -ForegroundColor Yellow
    Write-Host "Halting backup execution. Please ensure '$DatabaseName' is deployed and populated before retrying." -ForegroundColor Yellow
    exit 2
}

# 4. Execute pg_dump with Custom Format (-Fc)
Write-Host "`n[EXEC] Executing pg_dump (-Fc)..." -ForegroundColor Yellow
$dumpArgs = @(
    "-U", $Username,
    "-h", $HostName,
    "-p", $Port,
    "-Fc",
    "-d", $DatabaseName,
    "-f", $dumpFilePath
)

$process = Start-Process -FilePath $pgDump -ArgumentList $dumpArgs -NoNewWindow -Wait -PassThru
if ($process.ExitCode -ne 0) {
    Write-Error "pg_dump failed with exit code $($process.ExitCode)."
    exit $process.ExitCode
}

# 5. Verify Backup File Creation & Checksum
if (-not (Test-Path $dumpFilePath)) {
    Write-Error "Backup file was not created at expected path: $dumpFilePath"
    exit 1
}

$fileItem = Get-Item $dumpFilePath
$fileSize = $fileItem.Length
$fileHash = (Get-FileHash -Path $dumpFilePath -Algorithm SHA256).Hash

Write-Host "`n[SUCCESS] Backup archive successfully created!" -ForegroundColor Green
Write-Host "  File Name:   $dumpFileName" -ForegroundColor White
Write-Host "  File Size:   $fileSize bytes" -ForegroundColor White
Write-Host "  SHA-256:     $fileHash" -ForegroundColor White
Write-Host "  Created At:  $($fileItem.CreationTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White

# Update canonical reference copy
Copy-Item -Path $dumpFilePath -Destination $symlinkOrCanonical -Force

# 6. Archive Inspection (pg_restore --list)
Write-Host "`n[INSPECT] Inspecting archive Table of Contents (pg_restore --list)..." -ForegroundColor Yellow
$tocOutput = & $pgRestore --list $dumpFilePath
$tocLines = $tocOutput | Measure-Object -Line

Write-Host "  TOC Entries: $($tocLines.Lines) catalog objects verified." -ForegroundColor Green
Write-Host "  Sample Archive Objects:" -ForegroundColor Gray
$tocOutput | Select-Object -First 15 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }

Write-Host "`n[COMPLETED] Backup and validation routine completed successfully." -ForegroundColor Cyan

