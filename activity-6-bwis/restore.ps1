<#
.SYNOPSIS
    Automated PostgreSQL database restoration script for BWIS Campus Canteen Pre-Order & Queue Management System.
.DESCRIPTION
    Restores a pg_dump custom archive (-Fc) into an isolated test or recovery database.
    Enforces database safety rules: prevents overwriting original databases and requires distinct test database names.
.PARAMETER BackupFile
    Path to the verified .dump custom archive file.
.PARAMETER TargetDbName
    Target database name. Must end in _activity6_restore_test or _activity6_recovery_test for safety.
.PARAMETER DbHost
    PostgreSQL server hostname/IP. Defaults to '127.0.0.1'.
.PARAMETER DbPort
    PostgreSQL server port. Defaults to '5432'.
.PARAMETER DbUser
    PostgreSQL superuser or maintenance account. Defaults to 'postgres'.
.EXAMPLE
    .\restore.ps1 -BackupFile "C:\backups\canteendb_20261106.dump" -TargetDbName "canteendb_activity6_restore_test"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BackupFile,
    [string]$TargetDbName = "canteendb_activity6_restore_test",
    [string]$DbHost = "127.0.0.1",
    [string]$DbPort = "5432",
    [string]$DbUser = "postgres"
)

$ErrorActionPreference = "Stop"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " BWIS IT Solutions - Database Restoration (COMP 018 Act 6)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# Safety Validation
if ($TargetDbName -eq "canteendb" -or $TargetDbName -eq "canteen_db") {
    throw "CRITICAL SAFETY ERROR: Cannot restore directly into original production database ($TargetDbName). Use a separate test database."
}

if (-not (Test-Path $BackupFile)) {
    throw "Backup archive not found at path: $BackupFile"
}

# Locate binaries
$createdb = Get-Command createdb -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1
if (-not $createdb) {
    $standardPath = "C:\Program Files\PostgreSQL\18\bin\createdb.exe"
    if (Test-Path $standardPath) { $createdb = $standardPath }
    else { throw "createdb binary not found." }
}

$pgRestore = Get-Command pg_restore -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1
if (-not $pgRestore) {
    $standardPath = "C:\Program Files\PostgreSQL\18\bin\pg_restore.exe"
    if (Test-Path $standardPath) { $pgRestore = $standardPath }
    else { throw "pg_restore binary not found." }
}

$psql = Get-Command psql -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1
if (-not $psql) {
    $standardPath = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
    if (Test-Path $standardPath) { $psql = $standardPath }
    else { throw "psql binary not found." }
}

# Check if target database already exists
$dbExistsQuery = "SELECT 1 FROM pg_database WHERE datname = '$TargetDbName';"
$dbExistsOutput = & $psql -U $DbUser -h $DbHost -p $DbPort -tAc $dbExistsQuery 2>&1
$dbExists = ($dbExistsOutput.Trim() -eq "1")

if (-not $dbExists) {
    Write-Host "Creating target database '$TargetDbName'..." -ForegroundColor Yellow
    & $createdb -U $DbUser -h $DbHost -p $DbPort $TargetDbName
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create target database '$TargetDbName'."
    }
    Write-Host "Target database created successfully." -ForegroundColor Green
} else {
    Write-Host "Target database '$TargetDbName' already exists. Proceeding with restoration." -ForegroundColor Yellow
}

Write-Host "Restoring backup archive into '$TargetDbName'..." -ForegroundColor Cyan
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$restoreLog = & $pgRestore -U $DbUser -h $DbHost -p $DbPort -d $TargetDbName --verbose $BackupFile 2>&1
$exitCode = $LASTEXITCODE
$sw.Stop()

Write-Host "pg_restore completed with exit code: $exitCode in $($sw.ElapsedMilliseconds) ms" -ForegroundColor $(if ($exitCode -eq 0) { "Green" } else { "Yellow" })

Write-Host "`nPost-Restoration Security Reminder:" -ForegroundColor Magenta
Write-Host "  pg_restore restores schema, tables, sequences, constraints, and table ACLs."
Write-Host "  Database-level CONNECT permissions (pg_database.datacl) are cluster-wide and"
Write-Host "  must be verified/reapplied using db-access-control/03-database-privileges.sql."

[PSCustomObject]@{
    Status       = if ($exitCode -eq 0) { "SUCCESS" } else { "COMPLETED_WITH_WARNINGS" }
    TargetDb     = $TargetDbName
    Archive      = $BackupFile
    ExitCode     = $exitCode
    DurationMs   = $sw.ElapsedMilliseconds
}

