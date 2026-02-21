@echo off
setlocal

:: Get the current directory (where this script is located)
set "INSTALLER_DIR=%~dp0"

:: Create desktop shortcut
echo Creating desktop shortcut...
powershell -Command ^
"$WScriptShell = New-Object -ComObject WScript.Shell; ^
$Shortcut = $WScriptShell.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\Install Excellence Coaching Hub.lnk'); ^
$Shortcut.TargetPath = '%INSTALLER_DIR%Install App.bat'; ^
$Shortcut.WorkingDirectory = '%INSTALLER_DIR%'; ^
$Shortcut.IconLocation = '%INSTALLER_DIR%assets\icon.png,0'; ^
$Shortcut.Description = 'Install Excellence Coaching Hub'; ^
$Shortcut.Save()"

echo Desktop shortcut created successfully!
echo You can now install the app by double-clicking the shortcut on your desktop.
pause