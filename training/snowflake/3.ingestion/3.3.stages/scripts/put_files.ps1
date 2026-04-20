#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$FilesDir   = Resolve-Path (Join-Path $ScriptDir "..\..\3.1.files")

$Stage      = "@RAW_DEV.SQL_SERVER.LANDING"
$Connection = "ingestion"

Write-Host "Uploading files from: $FilesDir"
Write-Host "Target stage: $Stage"
Write-Host "---"

$csvFiles = Get-ChildItem -Path $FilesDir -Filter "*.csv"

if ($csvFiles.Count -eq 0) {
    Write-Error "No CSV files found in $FilesDir"
    exit 1
}

foreach ($file in $csvFiles) {
    Write-Host "Uploading $($file.Name) ..."
    uv run snow sql `
        -q "PUT file://$($file.FullName) $Stage AUTO_COMPRESS=FALSE OVERWRITE=TRUE;" `
        -c $Connection
}

Write-Host "---"
Write-Host "Done."
