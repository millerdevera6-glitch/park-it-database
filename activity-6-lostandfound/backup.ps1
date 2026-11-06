# ==============================================================================
# PUP-SPOT Campus Lost and Found System
# COMP 018 - Database Administration | Activity 6
# Script: backup.ps1 - Automated Logical Database Backup
# ==============================================================================

[CmdletBinding()]
param (
    [string]$Database = "grp05_lostandfounddb",
    [string]$HostName = "localhost",
    [int]$Port = 5432,
    [string]$Username = "postgres",
    [string]$BackupDir = ""
)

# Set strict error handling
$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "       PUP-SPOT DATABASE BACKUP AUTOMATION (ACTIVITY 6)          " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Resolve Backup Output Directory
if ([string]::IsNullOrWhiteSpace($BackupDir)) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $BackupDir = Join-Path $ScriptDir "backup"
}

if (-not (Test-Path $BackupDir)) {
    Write-Host "[*] Creating backup directory at: $BackupDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

# 2. Locate PostgreSQL Binaries
$pgDumpPath = (Get-Command "pg_dump" -ErrorAction SilentlyContinue)?.Source

if (-not $pgDumpPath) {
    # Search common Windows PostgreSQL installation paths
    $commonPaths = @(
        "C:\Program Files\PostgreSQL\18\bin\pg_dump.exe",
        "C:\Program Files\PostgreSQL\17\bin\pg_dump.exe",
        "C:\Program Files\PostgreSQL\16\bin\pg_dump.exe",
        "C:\Program Files\PostgreSQL\15\bin\pg_dump.exe"
    )
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            $pgDumpPath = $path
            $binFolder = Split-Path -Parent $path
            $env:Path = "$binFolder;" + $env:Path
            break
        }
    }
}

if (-not $pgDumpPath) {
    Write-Error "PostgreSQL 'pg_dump' utility could not be located on PATH or standard directories. Please install PostgreSQL or configure PATH."
    exit 1
}

Write-Host "[+] Using pg_dump executable: $pgDumpPath" -ForegroundColor Green

# 3. Formulate Output Filename
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$DumpFilename = "${Database}_activity6_${Timestamp}.dump"
$CanonicalDumpFilename = "${Database}_activity6.dump"
$DumpFilePath = Join-Path $BackupDir $DumpFilename
$CanonicalDumpFilePath = Join-Path $BackupDir $CanonicalDumpFilename

Write-Host "[*] Source Database: $Database" -ForegroundColor White
Write-Host "[*] Host: ${HostName}:${Port}" -ForegroundColor White
Write-Host "[*] Target Archive: $DumpFilePath" -ForegroundColor White

# 4. Execute pg_dump with Custom Format (-Fc)
Write-Host "`n[*] Initiating pg_dump in Custom Archive format (-Fc)..." -ForegroundColor Yellow
$dumpArgs = @(
    "-U", $Username,
    "-h", $HostName,
    "-p", $Port,
    "-Fc",
    "-d", $Database,
    "-f", $DumpFilePath
)

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
& $pgDumpPath $dumpArgs
$exitCode = $LASTEXITCODE
$stopwatch.Stop()

if ($exitCode -ne 0 -or (-not (Test-Path $DumpFilePath))) {
    Write-Error "pg_dump failed with exit code $exitCode. Backup was NOT generated."
    exit $exitCode
}

# Also update or create the canonical named dump for consistent testing
Copy-Item -Path $DumpFilePath -Destination $CanonicalDumpFilePath -Force

# 5. Backup Verification and Manifest Computation
$fileItem = Get-Item $DumpFilePath
$fileSize = $fileItem.Length
$fileHash = Get-FileHash -Path $DumpFilePath -Algorithm SHA256

Write-Host "`n=================================================================" -ForegroundColor Green
Write-Host "               BACKUP CREATION COMPLETED SUCCESSFULLY             " -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
Write-Host "  File Name:      $DumpFilename" -ForegroundColor White
Write-Host "  File Size:      $fileSize bytes ($([math]::Round($fileSize / 1KB, 2)) KB)" -ForegroundColor White
Write-Host "  Creation Time:  $($fileItem.CreationTime)" -ForegroundColor White
Write-Host "  Duration:       $($stopwatch.Elapsed.TotalSeconds) seconds" -ForegroundColor White
Write-Host "  SHA-256 Hash:   $($fileHash.Hash)" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Green

# 6. Archive TOC Verification via pg_restore --list
$pgRestorePath = (Get-Command "pg_restore" -ErrorAction SilentlyContinue)?.Source
if (-not $pgRestorePath) {
    $binDir = Split-Path -Parent $pgDumpPath
    $pgRestorePath = Join-Path $binDir "pg_restore.exe"
}

if (Test-Path $pgRestorePath) {
    Write-Host "`n[*] Inspecting archive structure using pg_restore --list..." -ForegroundColor Cyan
    $tocLogPath = Join-Path $BackupDir "backup_toc_manifest.txt"
    & $pgRestorePath --list $DumpFilePath | Out-File -FilePath $tocLogPath -Encoding utf8
    $tocCount = (Get-Content $tocLogPath | Where-Object { $_ -match '^[0-9]+;' }).Count
    Write-Host "[+] Archive TOC parsed successfully: $tocCount objects found in archive." -ForegroundColor Green
    Write-Host "[+] Detailed TOC manifest saved to: $tocLogPath" -ForegroundColor White
}

Write-Host "`n[✓] Phase 3 Backup process complete." -ForegroundColor Green

