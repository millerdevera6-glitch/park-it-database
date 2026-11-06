<#
.SYNOPSIS
    Automated PostgreSQL custom-format backup script for BWIS Campus Canteen Pre-Order & Queue Management System.
.DESCRIPTION
    Performs logical backup of the specified database using pg_dump in PostgreSQL Custom Archive format (-Fc).
    Validates output file existence, calculates SHA-256 hash, and verifies archive readability using pg_restore --list.
.PARAMETER DbName
    Target database name. Defaults to 'canteendb'.
.PARAMETER DbHost
    PostgreSQL server hostname/IP. Defaults to '127.0.0.1'.
.PARAMETER DbPort
    PostgreSQL server port. Defaults to '5432'.
.PARAMETER DbUser
    PostgreSQL user account with backup/maintenance privileges. Defaults to 'postgres'.
.PARAMETER BackupDir
    Destination directory located strictly outside the Git repository.
.EXAMPLE
    .\backup.ps1 -DbName "canteendb" -BackupDir "C:\backups"
#>
[CmdletBinding()]
param(
    [string]$DbName = "canteendb",
    [string]$DbHost = "127.0.0.1",
    [string]$DbPort = "5432",
    [string]$DbUser = "postgres",
    [string]$BackupDir = "$env:USERPROFILE\.postgresql_backups"
)

$ErrorActionPreference = "Stop"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " BWIS IT Solutions - Database Backup Utility (COMP 018 Act 6)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# Locate pg_dump
$pgDump = Get-Command pg_dump -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1
if (-not $pgDump) {
    $standardPath = "C:\Program Files\PostgreSQL\18\bin\pg_dump.exe"
    if (Test-Path $standardPath) { $pgDump = $standardPath }
    else {
        throw "pg_dump executable not found on PATH or in C:\Program Files\PostgreSQL\18\bin."
    }
}

# Locate pg_restore
$pgRestore = Get-Command pg_restore -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1
if (-not $pgRestore) {
    $standardPath = "C:\Program Files\PostgreSQL\18\bin\pg_restore.exe"
    if (Test-Path $standardPath) { $pgRestore = $standardPath }
    else {
        throw "pg_restore executable not found on PATH or in C:\Program Files\PostgreSQL\18\bin."
    }
}

# Ensure Backup Directory exists and is outside Git repo
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

$repoRoot = (Resolve-Path "$PSScriptRoot\..").Path
$backupDirResolved = (Resolve-Path $BackupDir).Path
if ($backupDirResolved.StartsWith($repoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "SAFETY VIOLATION: BackupDir ($backupDirResolved) is inside the Git repository ($repoRoot). Choose an external location."
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$dumpFileName = "${DbName}_${timestamp}.dump"
$dumpFilePath = Join-Path $backupDirResolved $dumpFileName

Write-Host "Target Database : $DbName" -ForegroundColor Yellow
Write-Host "Host:Port       : ${DbHost}:${DbPort}" -ForegroundColor Yellow
Write-Host "Backup User     : $DbUser" -ForegroundColor Yellow
Write-Host "Destination     : $dumpFilePath" -ForegroundColor Yellow
Write-Host "Executing pg_dump (Custom Format -Fc)..." -NoNewline

$sw = [System.Diagnostics.Stopwatch]::StartNew()
& $pgDump -U $DbUser -h $DbHost -p $DbPort -Fc -d $DbName -f $dumpFilePath
$exitCode = $LASTEXITCODE
$sw.Stop()

if ($exitCode -ne 0 -or -not (Test-Path $dumpFilePath)) {
    throw "pg_dump failed with exit code $exitCode."
}
Write-Host " DONE ($($sw.ElapsedMilliseconds) ms)" -ForegroundColor Green

$item = Get-Item $dumpFilePath
$fileSize = $item.Length
$sha256 = (Get-FileHash -Path $dumpFilePath -Algorithm SHA256).Hash

Write-Host "`nBackup Metadata:" -ForegroundColor Cyan
Write-Host "  File Name : $dumpFileName"
Write-Host "  File Size : $fileSize bytes ($([Math]::Round($fileSize / 1KB, 2)) KB)"
Write-Host "  SHA-256   : $sha256"
Write-Host "  Timestamp : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"

Write-Host "`nVerifying Archive Integrity with pg_restore --list..." -ForegroundColor Yellow
$tocOutput = & $pgRestore --list $dumpFilePath 2>&1
$restoreExitCode = $LASTEXITCODE

if ($restoreExitCode -ne 0) {
    throw "pg_restore --list verification failed on archive $dumpFilePath."
}

$tocEntries = ($tocOutput | Where-Object { $_ -match '^\d+;' }).Count
Write-Host "Archive Integrity Verified: TOC contains $tocEntries entries." -ForegroundColor Green

[PSCustomObject]@{
    Status       = "SUCCESS"
    Database     = $DbName
    BackupFile   = $dumpFilePath
    FileSizeBytes= $fileSize
    SHA256       = $sha256
    TOCEntries   = $tocEntries
    DurationMs   = $sw.ElapsedMilliseconds
}

