@echo off
:: Minimize the command window
if not DEFINED IS_MINIMIZED set IS_MINIMIZED=1 && start "" /min "%~dpnx0" %* && exit

:: Change to the frontend directory
cd /d "%~dp0"

:: Launch the PowerShell installer script
powershell -ExecutionPolicy Bypass -File "%~dp0launch_installer.ps1" -Verbose

:: Keep window open if there was an error
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Installer encountered an error. Press any key to close...
    pause >nul
)