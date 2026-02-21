# Excellence Coaching Hub - Silent Installer
# This script runs completely invisibly

# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# Define installation paths
$InstallPath = "$env:LOCALAPPDATA\ExcellenceCoachingHub"
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$DesktopShortcut = "$DesktopPath\Excellence Coaching Hub.lnk"

try {
    # Build the debug version (most stable)
    $Process = Start-Process -FilePath "flutter" -ArgumentList "build", "windows", "--debug" -Wait -PassThru -NoNewWindow
    
    if ($Process.ExitCode -ne 0) {
        # Build failed - exit silently
        exit 1
    }
    
    # Create installation directory
    if (!(Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    }
    
    # Copy application files
    $SourcePath = "$ScriptDir\build\windows\x64\runner\Debug\*"
    Copy-Item -Path $SourcePath -Destination $InstallPath -Recurse -Force
    
    # Create desktop shortcut
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($DesktopShortcut)
    $Shortcut.TargetPath = "$InstallPath\excellence_coaching_hub.exe"
    $Shortcut.Description = "Excellence Coaching Hub"
    $Shortcut.Save()
    
    # Installation successful - exit silently
    exit 0
    
} catch {
    # Any error - exit silently
    exit 1
}