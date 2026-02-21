# Excellence Coaching Hub - Debug Installation Script
Write-Host "Building Excellence Coaching Hub (Debug Version)..." -ForegroundColor Green
cd "$PSScriptRoot"
flutter build windows --debug

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed!"
    exit 1
}

$InstallPath = "$env:LOCALAPPDATA\ExcellenceCoachingHub_Debug"
Write-Host "Installing to $InstallPath" -ForegroundColor Green

if (!(Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force
}

# Copy app files
$SourcePath = "$PSScriptRoot\build\windows\x64\runner\Debug\*"
Copy-Item -Path $SourcePath -Destination $InstallPath -Recurse -Force

# Create desktop shortcut
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$DesktopShortcut = "$DesktopPath\Excellence Coaching Hub (Debug).lnk"

$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($DesktopShortcut)
$Shortcut.TargetPath = "$InstallPath\excellence_coaching_hub.exe"
$Shortcut.Description = "Excellence Coaching Hub (Debug Version)"
$Shortcut.Save()

Write-Host "Installation completed successfully!" -ForegroundColor Green
Write-Host "Desktop shortcut created: $DesktopShortcut" -ForegroundColor Yellow
Write-Host "Installation path: $InstallPath" -ForegroundColor Yellow