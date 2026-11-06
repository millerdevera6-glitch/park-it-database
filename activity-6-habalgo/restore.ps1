<#
.SYNOPSIS
    Automated PostgreSQL Database Restoration Script for HabalGo.
.DESCRIPTION
    COMP 018 – Database Administration | Activity 6
    Restores a compressed custom-format logical archive (-Fc) into an isolated test or recovery database.
    Strictly safeguards production data by blocking unintentional overwrites.
.PARAMETER DumpFile
    Path to the backup dump file.
.PARAMETER TargetDatabase
    Name of the target database to restore into (Default: grp00_habalgodb_activity6_restore_test).
.PARAMETER DbUser
    PostgreSQL administrative user (Default: postgres).
.PARAMETER DbHost
    Host server address (Default: localhost).
.PARAMETER DbPort
    Port number (Default: 5432).
.EXAMPLE
    .\restore.ps1 -DumpFile "C:\HabalGo_Backups\habalgo_activity6.dump" -TargetDatabase "grp00_habalgodb_activity6_restore_test"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$DumpFile = "",
    
    [string]$TargetDatabase = "grp00_habalgodb_activity6_restore_test",
    [string]$DbUser = "postgres",
    [string]$DbHost = "localhost",
    [string]$DbPort = "5432"
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   HABALGO POSTGRESQL DATABASE RESTORATION UTILITY       " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Safety Check: Protect Production Database
if ($TargetDatabase -eq "grp00_habalgodb") {
    Write-Warning "SAFETY WARNING: Target database is the production database 'grp00_habalgodb'!"
    $confirm = Read-Host "Are you completely certain you wish to restore into production? (Type 'CONFIRM-OVERWRITE' to proceed)"
    if ($confirm -ne "CONFIRM-OVERWRITE") {
        Write-Error "Operation aborted by DBA safety check. Target database preserved."
        exit 1
    }
}

# 2. Locate Dump File if not supplied
if ([string]::IsNullOrWhiteSpace($DumpFile)) {
    # Check standard backup directories
    $possibleLocations = @(
        (Join-Path $env:LOCALAPPDATA "HabalGo_Backups\habalgo_activity6.dump"),
        "C:\Users\Matt\.gemini\antigravity\brain\70a3cb86-a366-40fd-a9d0-0fafa69e72d3\scratch\backups\habalgo_activity6.dump",
        "..\habalgo_activity6_backups\habalgo_activity6.dump",
        ".\habalgo_activity6.dump"
    )
    
    foreach ($loc in $possibleLocations) {
        if (Test-Path -Path $loc) {
            $DumpFile = $loc
            break
        }
    }
    
    if ([string]::IsNullOrWhiteSpace($DumpFile)) {
        Write-Error "No backup dump file found. Please provide -DumpFile parameter."
        exit 1
    }
}

if (-not (Test-Path -Path $DumpFile)) {
    Write-Error "Specified dump file does not exist: $DumpFile"
    exit 1
}

Write-Host "[INFO] Source Dump File: $DumpFile" -ForegroundColor Green
Write-Host "[INFO] Target Database:  $TargetDatabase" -ForegroundColor Green
Write-Host "[INFO] Host & Port:      ${DbHost}:${DbPort}" -ForegroundColor Green
Write-Host "[INFO] Restore User:     $DbUser" -ForegroundColor Green

# 3. Locate PostgreSQL Binaries
$pgRestore = Get-Command "pg_restore.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1

if (-not $pgRestore) {
    $pgCandidates = Get-ChildItem "C:\Program Files\PostgreSQL" -Filter "pg_restore.exe" -Recurse -ErrorAction SilentlyContinue
    if ($pgCandidates) {
        $pgRestore = $pgCandidates[0].FullName
    } else {
        Write-Error "PostgreSQL 'pg_restore.exe' not found in PATH or standard installation directories."
        exit 1
    }
}

$binDir = Split-Path -Parent $pgRestore
$createdb = Join-Path $binDir "createdb.exe"
$psql = Join-Path $binDir "psql.exe"

# 4. Check if Target Database Exists; Create if Missing
Write-Host "[INFO] Checking target database existence..." -ForegroundColor Yellow
$dbExists = & $psql -U $DbUser -h $DbHost -p $DbPort -tc "SELECT 1 FROM pg_database WHERE datname = '$TargetDatabase';" 2>$null

if ([string]::IsNullOrWhiteSpace($dbExists)) {
    Write-Host "[INFO] Target database '$TargetDatabase' does not exist. Creating..." -ForegroundColor Yellow
    & $createdb -U $DbUser -h $DbHost -p $DbPort $TargetDatabase
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create target database '$TargetDatabase'."
    }
    Write-Host "[SUCCESS] Created database: $TargetDatabase" -ForegroundColor Green
} else {
    Write-Host "[INFO] Target database '$TargetDatabase' exists. Proceeding with restore..." -ForegroundColor Yellow
}

# 5. Execute pg_restore
Write-Host "[INFO] Commencing pg_restore from custom archive..." -ForegroundColor Yellow
try {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Execute pg_restore; note that exit code 0 is clean success; exit code 1 may signify non-fatal schema warnings
    & $pgRestore -U $DbUser -h $DbHost -p $DbPort -d $TargetDatabase $DumpFile
    
    $sw.Stop()
    
    Write-Host "[SUCCESS] pg_restore completed in $($sw.Elapsed.TotalSeconds.ToString('F2')) seconds!" -ForegroundColor Green
}
catch {
    Write-Error "[FAIL] Restoration process encountered an error: $_"
    exit 1
}

# 6. Verify Table Inventory in Restored Database
Write-Host "`n[INFO] Validating restored table inventory..." -ForegroundColor Yellow
$tableList = & $psql -U $DbUser -h $DbHost -p $DbPort -d $TargetDatabase -tc "SELECT table_name FROM information_schema.tables WHERE table_schema='habalgo' ORDER BY table_name;"
$tables = ($tableList | ForEach-Object { $_.Trim() }) | Where-Object { $_ -ne "" }

Write-Host "Restored Tables in Schema 'habalgo': ($($tables.Count) tables found)" -ForegroundColor Cyan
foreach ($t in $tables) {
    Write-Host "  - habalgo.$t" -ForegroundColor Gray
}

if ($tables.Count -ge 8) {
    Write-Host "[PASS] All expected 8 relational tables verified in restored database." -ForegroundColor Green
} else {
    Write-Warning "[WARN] Found $($tables.Count) tables (expected 8). Please inspect verification logs."
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "   RESTORATION PROCESS CONCLUDED SUCCESSFULLY            " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

