# Excellence Coaching Hub - Installation Script
# This script installs the app and creates desktop/start menu shortcuts

param(
    [string]$InstallPath = "$env:LOCALAPPDATA\ExcellenceCoachingHub",
    [switch]$CreateDesktopShortcut,
    [switch]$CreateStartMenuShortcut
)

# Function to create shortcut
function Create-Shortcut {
    param(
        [string]$TargetPath,
        [string]$ShortcutPath,
        [string]$Description,
        [string]$IconLocation
    )
    
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $TargetPath
    $Shortcut.Description = $Description
    if ($IconLocation) {
        $Shortcut.IconLocation = $IconLocation
    }
    $Shortcut.Save()
}

# Build the app first
Write-Host "Building Excellence Coaching Hub..." -ForegroundColor Green
cd "$PSScriptRoot"
flutter build windows --release

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed!"
    exit 1
}

# Create installation directory
Write-Host "Installing to $InstallPath" -ForegroundColor Green
if (!(Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force
}

# Copy app files
$SourcePath = "$PSScriptRoot\build\windows\x64\runner\Release\*"
Copy-Item -Path $SourcePath -Destination $InstallPath -Recurse -Force

# Create desktop shortcut
if ($CreateDesktopShortcut -or !$CreateStartMenuShortcut) {
    $DesktopPath = [Environment]::GetFolderPath("Desktop")
    $DesktopShortcut = "$DesktopPath\Excellence Coaching Hub.lnk"
    Create-Shortcut -TargetPath "$InstallPath\excellence_coaching_hub.exe" -ShortcutPath $DesktopShortcut -Description "Excellence Coaching Hub"
    Write-Host "Desktop shortcut created: $DesktopShortcut" -ForegroundColor Green
}

# Create Start Menu shortcut
if ($CreateStartMenuShortcut -or !$CreateDesktopShortcut) {
    $StartMenuPath = [Environment]::GetFolderPath("Programs")
    $AppStartMenuPath = "$StartMenuPath\Excellence Coaching Hub"
    
    if (!(Test-Path $AppStartMenuPath)) {
        New-Item -ItemType Directory -Path $AppStartMenuPath -Force
    }
    
    $StartMenuShortcut = "$AppStartMenuPath\Excellence Coaching Hub.lnk"
    Create-Shortcut -TargetPath "$InstallPath\excellence_coaching_hub.exe" -ShortcutPath $StartMenuShortcut -Description "Excellence Coaching Hub"
    Write-Host "Start Menu shortcut created: $StartMenuShortcut" -ForegroundColor Green
}

# Create uninstall script
$UninstallScript = @"
# Excellence Coaching Hub - Uninstall Script
Remove-Item -Path "$InstallPath" -Recurse -Force
Remove-Item -Path "$DesktopPath\Excellence Coaching Hub.lnk" -ErrorAction SilentlyContinue
Remove-Item -Path "$StartMenuPath\Excellence Coaching Hub" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Excellence Coaching Hub has been uninstalled." -ForegroundColor Green
"@
$UninstallScript | Out-File -FilePath "$InstallPath\uninstall.ps1" -Encoding UTF8

Write-Host "Installation completed successfully!" -ForegroundColor Green
Write-Host "App installed to: $InstallPath" -ForegroundColor Yellow
Write-Host "To uninstall, run: $InstallPath\uninstall.ps1" -ForegroundColor Yellow