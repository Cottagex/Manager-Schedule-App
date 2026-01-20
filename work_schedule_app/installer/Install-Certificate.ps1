# Manager Schedule App - Certificate Installation Script
# Run this script ONCE as Administrator to trust the app's certificate
# After running, you can install the app without security warnings

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Manager Schedule App - Certificate Setup  " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "This script requires Administrator privileges." -ForegroundColor Yellow
    Write-Host "Restarting as Administrator..." -ForegroundColor Yellow
    Write-Host ""
    
    # Restart script as admin
    Start-Process PowerShell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# Find the certificate file
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$certPath = Join-Path $scriptDir "ManagerScheduleApp.cer"

if (-not (Test-Path $certPath)) {
    # Try looking in parent certs folder
    $certPath = Join-Path (Split-Path -Parent $scriptDir) "certs\ManagerScheduleApp.cer"
}

if (-not (Test-Path $certPath)) {
    Write-Host "ERROR: Certificate file not found!" -ForegroundColor Red
    Write-Host "Please make sure 'ManagerScheduleApp.cer' is in the same folder as this script." -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Found certificate: $certPath" -ForegroundColor Green
Write-Host ""

# Check if already installed
$existingCert = Get-ChildItem -Path Cert:\LocalMachine\TrustedPeople | Where-Object { $_.Subject -like "*Manager Schedule App*" }

if ($existingCert) {
    Write-Host "Certificate is already installed!" -ForegroundColor Green
    Write-Host "You can install Manager Schedule App without any warnings." -ForegroundColor Green
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 0
}

# Install the certificate
Write-Host "Installing certificate to Trusted People store..." -ForegroundColor Yellow

try {
    Import-Certificate -FilePath $certPath -CertStoreLocation Cert:\LocalMachine\TrustedPeople | Out-Null
    
    Write-Host ""
    Write-Host "SUCCESS! Certificate installed." -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now install Manager Schedule App without security warnings." -ForegroundColor Green
    Write-Host "Double-click the .msix file or .appinstaller file to install." -ForegroundColor Cyan
    Write-Host ""
} catch {
    Write-Host ""
    Write-Host "ERROR: Failed to install certificate!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
}

Read-Host "Press Enter to exit"
