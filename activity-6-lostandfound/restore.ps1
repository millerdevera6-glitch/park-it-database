# ==============================================================================
# PUP-SPOT Campus Lost and Found System
# COMP 018 - Database Administration | Activity 6
# Script: restore.ps1 - Automated Database Restoration to Separate Test Target
# ==============================================================================

[CmdletBinding()]
param (
    [string]$TargetDatabase = "grp05_lostandfounddb_restore_test",
    [string]$DumpFile = "",
    [string]$HostName = "localhost",
    [int]$Port = 5432,
    [string]$Username = "postgres"
)

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "       PUP-SPOT DATABASE RESTORE AUTOMATION (ACTIVITY 6)         " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# SAFETY CHECK: Never allow restoring directly over the production database
if ($TargetDatabase -eq "grp05_lostandfounddb") {
    Write-Error "SAFETY VIOLATION: Restoring directly over the primary production database 'grp05_lostandfounddb' is strictly forbidden!"
    exit 1
}

# 1. Resolve Dump File
if ([string]::IsNullOrWhiteSpace($DumpFile)) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $BackupDir = Join-Path $ScriptDir "backup"
    
    # Locate most recent dump file or canonical dump
    $canonical = Join-Path $BackupDir "grp05_lostandfounddb_activity6.dump"
    if (Test-Path $canonical) {
        $DumpFile = $canonical
    } else {
        $recentDump = Get-ChildItem -Path $BackupDir -Filter "*.dump" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($recentDump) {
            $DumpFile = $recentDump.FullName
        }
    }
}

if (-not (Test-Path $DumpFile)) {
    Write-Error "Specified dump file does not exist: $DumpFile. Please run backup.ps1 first."
    exit 1
}

Write-Host "[+] Dump Source Archive: $DumpFile" -ForegroundColor Green
Write-Host "[*] Target Test Database: $TargetDatabase" -ForegroundColor Yellow

# 2. Locate PostgreSQL Binaries
$psqlPath = (Get-Command "psql" -ErrorAction SilentlyContinue)?.Source
$pgRestorePath = (Get-Command "pg_restore" -ErrorAction SilentlyContinue)?.Source
$createdbPath = (Get-Command "createdb" -ErrorAction SilentlyContinue)?.Source

if (-not $pgRestorePath) {
    $commonPaths = @(
        "C:\Program Files\PostgreSQL\18\bin",
        "C:\Program Files\PostgreSQL\17\bin",
        "C:\Program Files\PostgreSQL\16\bin",
        "C:\Program Files\PostgreSQL\15\bin"
    )
    foreach ($path in $commonPaths) {
        if (Test-Path (Join-Path $path "pg_restore.exe")) {
            $pgRestorePath = Join-Path $path "pg_restore.exe"
            $psqlPath = Join-Path $path "psql.exe"
            $createdbPath = Join-Path $path "createdb.exe"
            $env:Path = "$path;" + $env:Path
            break
        }
    }
}

if (-not (Test-Path $pgRestorePath)) {
    Write-Error "PostgreSQL 'pg_restore' utility could not be located."
    exit 1
}

# 3. Verify Target Database Existence
Write-Host "[*] Checking if target database '$TargetDatabase' exists on ${HostName}:${Port}..." -ForegroundColor White
$dbCheckQuery = "SELECT 1 FROM pg_database WHERE datname = '$TargetDatabase';"
$dbExistsOutput = & $psqlPath -U $Username -h $HostName -p $Port -t -A -c $dbCheckQuery 2>$null

if ($dbExistsOutput -match "1") {
    Write-Host "[!] Target test database '$TargetDatabase' already exists. Preserving database shell." -ForegroundColor Yellow
} else {
    Write-Host "[*] Target database '$TargetDatabase' does not exist. Creating via createdb..." -ForegroundColor White
    $createDbArgs = @(
        "-U", $Username,
        "-h", $HostName,
        "-p", $Port,
        $TargetDatabase
    )
    & $createdbPath $createDbArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create target database '$TargetDatabase'. Exit code: $LASTEXITCODE"
        exit $LASTEXITCODE
    }
    Write-Host "[+] Database '$TargetDatabase' created successfully." -ForegroundColor Green
}

# 4. Execute pg_restore
Write-Host "`n[*] Commencing pg_restore into '$TargetDatabase'..." -ForegroundColor Cyan
$restoreArgs = @(
    "-U", $Username,
    "-h", $HostName,
    "-p", $Port,
    "-d", $TargetDatabase,
    "-v",
    $DumpFile
)

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
& $pgRestorePath $restoreArgs 2>&1 | Out-Default
$restoreExitCode = $LASTEXITCODE
$stopwatch.Stop()

Write-Host "`n=================================================================" -ForegroundColor $(if ($restoreExitCode -eq 0) { "Green" } else { "Yellow" })
Write-Host "                RESTORATION EXECUTION COMPLETED                  " -ForegroundColor $(if ($restoreExitCode -eq 0) { "Green" } else { "Yellow" })
Write-Host "=================================================================" -ForegroundColor $(if ($restoreExitCode -eq 0) { "Green" } else { "Yellow" })
Write-Host "  Target Database: $TargetDatabase" -ForegroundColor White
Write-Host "  Duration:        $($stopwatch.Elapsed.TotalSeconds) seconds" -ForegroundColor White
Write-Host "  Exit Code:       $restoreExitCode" -ForegroundColor White

if ($restoreExitCode -eq 0) {
    Write-Host "[✓] Restoration succeeded with zero errors or warnings." -ForegroundColor Green
} else {
    Write-Warning "pg_restore finished with exit code $restoreExitCode. Please review output logs for details."
}

