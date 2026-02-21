@echo off
echo Building Excellence Coaching Hub (Debug Version)...
cd /d "%~dp0"
flutter build windows --debug

if %ERRORLEVEL% NEQ 0 (
    echo Build failed!
    pause
    exit /b 1
)

echo Installing to %LOCALAPPDATA%\ExcellenceCoachingHub_Debug...
if not exist "%LOCALAPPDATA%\ExcellenceCoachingHub_Debug" mkdir "%LOCALAPPDATA%\ExcellenceCoachingHub_Debug"

xcopy /E /Y "build\windows\x64\runner\Debug\*" "%LOCALAPPDATA%\ExcellenceCoachingHub_Debug\"

echo Creating desktop shortcut...
powershell -Command "$WScriptShell = New-Object -ComObject WScript.Shell; $Shortcut = $WScriptShell.CreateShortcut('%USERPROFILE%\Desktop\Excellence Coaching Hub (Debug).lnk'); $Shortcut.TargetPath = '%LOCALAPPDATA%\ExcellenceCoachingHub_Debug\excellence_coaching_hub.exe'; $Shortcut.Save()"

echo Installation completed!
echo You can now run the app from your desktop shortcut.
pause