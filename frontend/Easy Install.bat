@echo off
:: Minimize command window visibility
if not DEFINED IS_MINIMIZED set IS_MINIMIZED=1 && start "" /min "%~dpnx0" %* && exit

title Excellence Coaching Hub - Easy Installer
color 0A
cls

echo.
echo  ╔══════════════════════════════════════════════════════════════╗
echo  ║              EXCELLENCE COACHING HUB INSTALLER              ║
echo  ╚══════════════════════════════════════════════════════════════╝
echo.
echo  This will install Excellence Coaching Hub on your computer.
echo  The application will be available from your desktop after installation.
echo.
echo  Press any key to begin installation...
pause >nul

cls
echo.
echo  Installing Excellence Coaching Hub...
echo  ======================================

:: Navigate to frontend directory
cd /d "%~dp0"

:: Run the debug installation (most stable)
echo Building application...
flutter build windows --debug

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Build failed!
    echo Please make sure Flutter is installed and in your PATH.
    echo.
    pause
    exit /b 1
)

:: Install to user's local app data
echo Installing to your computer...
set "INSTALL_PATH=%LOCALAPPDATA%\ExcellenceCoachingHub"

if not exist "%INSTALL_PATH%" mkdir "%INSTALL_PATH%"

:: Copy files
xcopy /E /Y "build\windows\x64\runner\Debug\*" "%INSTALL_PATH%\" >nul

:: Create desktop shortcut
echo Creating desktop shortcut...
powershell -Command "$WScriptShell = New-Object -ComObject WScript.Shell; $Shortcut = $WScriptShell.CreateShortcut('%USERPROFILE%\Desktop\Excellence Coaching Hub.lnk'); $Shortcut.TargetPath = '%INSTALL_PATH%\excellence_coaching_hub.exe'; $Shortcut.Description = 'Excellence Coaching Hub'; $Shortcut.Save()"

cls
echo.
echo  ╔══════════════════════════════════════════════════════════════╗
echo  ║                    INSTALLATION COMPLETE!                   ║
echo  ╚══════════════════════════════════════════════════════════════╝
echo.
echo  Excellence Coaching Hub has been successfully installed!
echo.
echo  You can now:
echo  • Click the desktop shortcut to launch the app
echo  • Find it in your Start Menu
echo  • Run it from: %INSTALL_PATH%
echo.
echo  Press any key to exit...
pause >nul