# Build MSIX for Microsoft Store submission
# This script creates an unsigned MSIX package that Microsoft will sign

Write-Host "Building ScheduleHQ for Microsoft Store..." -ForegroundColor Cyan

# Backup original pubspec.yaml
Copy-Item "pubspec.yaml" "pubspec_backup.yaml" -Force

# Use Store configuration
Copy-Item "pubspec_store.yaml" "pubspec.yaml" -Force

try {
    # Set CMake policy for Firebase compatibility
    $env:CMAKE_POLICY_VERSION_MINIMUM = "3.5"
    
    # Clean and get dependencies
    Write-Host "Getting dependencies..." -ForegroundColor Yellow
    flutter pub get
    
    # Build the MSIX for Store (no certificate needed - Microsoft signs it)
    Write-Host "Building MSIX for Store..." -ForegroundColor Yellow
    dart run msix:create
    
    # Create store output folder
    $storeDir = "installer\store"
    if (!(Test-Path $storeDir)) {
        New-Item -ItemType Directory -Path $storeDir | Out-Null
    }
    
    # Copy the MSIX to store folder
    Copy-Item "build\windows\x64\runner\Release\work_schedule_app.msix" "$storeDir\ScheduleHQ.msix" -Force
    
    Write-Host ""
    Write-Host "SUCCESS! Store MSIX created at: $storeDir\ScheduleHQ.msix" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Go to Partner Center: https://partner.microsoft.com/dashboard" -ForegroundColor White
    Write-Host "2. Select your app 'ScheduleHQ'" -ForegroundColor White
    Write-Host "3. Go to 'Product management' > 'Package'" -ForegroundColor White
    Write-Host "4. Upload the MSIX file from: $storeDir\ScheduleHQ.msix" -ForegroundColor White
}
finally {
    # Restore original pubspec.yaml
    Copy-Item "pubspec_backup.yaml" "pubspec.yaml" -Force
    Remove-Item "pubspec_backup.yaml" -Force
    
    # Re-get dependencies with original pubspec
    flutter pub get | Out-Null
}
