# PowerShell script to switch between Store and GitHub release configurations
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("store", "github")]
    [string]$Target
)

$pubspecPath = "pubspec.yaml"
$content = Get-Content $pubspecPath -Raw

if ($Target -eq "store") {
    Write-Host "Switching to Microsoft Store configuration..." -ForegroundColor Cyan
    
    # Comment out certificate_path and add store: true
    $content = $content -replace '(\s+)certificate_path: certs/ManagerScheduleApp.pfx', '$1# certificate_path: certs/ManagerScheduleApp.pfx  # Commented for Store build'
    $content = $content -replace '# store: true', 'store: true'
    
    if ($content -notmatch 'store: true') {
        $content = $content -replace '(capabilities: internetClient)', "store: true`n  `$1"
    }
    
    Write-Host "Done! Ready for Microsoft Store build." -ForegroundColor Green
}
elseif ($Target -eq "github") {
    Write-Host "Switching to GitHub release configuration..." -ForegroundColor Cyan
    
    # Uncomment certificate_path and remove/comment store: true
    $content = $content -replace '(\s+)# certificate_path: certs/ManagerScheduleApp.pfx.*', '$1certificate_path: certs/ManagerScheduleApp.pfx'
    $content = $content -replace '(\s+)store: true', '$1# store: true'
    
    Write-Host "Done! Ready for GitHub release build." -ForegroundColor Green
}

Set-Content $pubspecPath $content -NoNewline

Write-Host "`nCurrent msix_config:" -ForegroundColor Yellow
Select-String -Path $pubspecPath -Pattern "msix_config" -Context 0,15
