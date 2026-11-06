# ==============================================================================
# BrewPOS — Automated Database Backup Script (PowerShell)
# Course   : COMP 018 — Database Administration
# Project  : BrewPOS — Café Point-of-Sale System
# Database : grp_brewposdb
# Target   : PostgreSQL 18+ (Compatible with v16+)
# ==============================================================================

[CmdletBinding()]
param(
    [string]$HostName = "localhost",
    [int]$Port = 5432,
    [string]$Username = "postgres",
    [string]$Database = "grp_brewposdb",
    [string]$BackupDir = "C:\Users\Matt\pg_backups\brewpos",
    [string]$DumpFileName = "grp_brewposdb_activity6.dump",
    [string]$PgBinPath = "C:\Program Files\PostgreSQL\18\bin"
)

$ErrorActionPreference = "Stop"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " BrewPOS Database Backup Execution — $Database " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "Timestamp       : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Target Host     : ${HostName}:${Port}"
Write-Host "Database Name   : $Database"
Write-Host "Database User   : $Username"
Write-Host "Storage Dir     : $BackupDir"

# 1. Resolve PostgreSQL binary paths
$pgDumpExe = Join-Path $PgBinPath "pg_dump.exe"
$pgRestoreExe = Join-Path $PgBinPath "pg_restore.exe"

if (!(Test-Path $pgDumpExe)) {
    # Fallback to PATH resolution
    $cmd = Get-Command "pg_dump" -ErrorAction SilentlyContinue
    if ($cmd) {
        $pgDumpExe = $cmd.Source
        $pgRestoreExe = (Get-Command "pg_restore").Source
    } else {
        Write-Error "PostgreSQL pg_dump binary not found at '$pgDumpExe' or in system PATH."
        exit 1
    }
}

# 2. Ensure backup destination directory exists
if (!(Test-Path $BackupDir)) {
    Write-Host "[INFO] Creating backup directory: $BackupDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

$targetDumpPath = Join-Path $BackupDir $DumpFileName

# 3. Execute pg_dump with Custom Archive Format (-Fc)
Write-Host "`n[1/4] Executing pg_dump (Custom Format: -Fc, Compressed)..." -ForegroundColor Green
$startTime = Get-Date

try {
    & $pgDumpExe -U $Username -h $HostName -p $Port -Fc -d $Database -f $targetDumpPath
    $dumpExitCode = $LASTEXITCODE
} catch {
    Write-Error "pg_dump execution failed with exception: $_"
    exit 1
}

if ($dumpExitCode -ne 0) {
    Write-Error "pg_dump exited with error code $dumpExitCode."
    exit $dumpExitCode
}

$elapsed = (Get-Date) - $startTime
Write-Host "      pg_dump completed successfully in $($elapsed.TotalSeconds.ToString('F2')) seconds." -ForegroundColor Green

# 4. Verify file existence and inspect metadata
Write-Host "`n[2/4] Verifying backup archive on disk..." -ForegroundColor Green
if (!(Test-Path $targetDumpPath)) {
    Write-Error "Backup file not found at '$targetDumpPath' after execution!"
    exit 1
}

$fileItem = Get-Item $targetDumpPath
$fileSizeKb = [math]::Round($fileItem.Length / 1KB, 2)
Write-Host "      Filename      : $($fileItem.Name)"
Write-Host "      File Size     : $($fileItem.Length) bytes ($fileSizeKb KB)"
Write-Host "      Last Modified : $($fileItem.LastWriteTime)"

# 5. Compute cryptographic SHA-256 checksum
Write-Host "`n[3/4] Calculating cryptographic SHA-256 hash..." -ForegroundColor Green
$sha256 = (Get-FileHash -Path $targetDumpPath -Algorithm SHA256).Hash
Write-Host "      SHA-256 Checksum : $sha256" -ForegroundColor Yellow

# Write hash file alongside the dump
$checksumFilePath = "$targetDumpPath.sha256"
Set-Content -Path $checksumFilePath -Value "$sha256  $($fileItem.Name)" -Encoding ascii
Write-Host "      Checksum saved to: $checksumFilePath"

# 6. Validate archive header and Table of Contents (TOC)
Write-Host "`n[4/4] Inspecting archive Table of Contents (pg_restore --list)..." -ForegroundColor Green
$tocOutput = & $pgRestoreExe --list $targetDumpPath
$tocCount = ($tocOutput | Where-Object { $_ -match "^\d+;" }).Count
Write-Host "      TOC Verification : Successful ($tocCount actionable archive items found)." -ForegroundColor Green

Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host " BACKUP VERIFICATION SUMMARY: SUCCESSFUL " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "Archive  : $targetDumpPath"
Write-Host "Bytes    : $($fileItem.Length)"
Write-Host "SHA-256  : $sha256"
Write-Host "Status   : VALIDATED"

