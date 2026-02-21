@echo off
cd /d "D:\ECHAPP\frontend\build\windows\x64\runner\Release"

echo === Excellence Coaching Hub - Dependency Check ===
echo Current directory: %CD%
echo.

echo Checking for required DLLs...
if exist "flutter_windows.dll" (
    echo ✓ flutter_windows.dll found
) else (
    echo ✗ flutter_windows.dll missing
)

if exist "audioplayers_windows_plugin.dll" (
    echo ✓ audioplayers_windows_plugin.dll found
) else (
    echo ✗ audioplayers_windows_plugin.dll missing
)

echo.
echo Setting up environment...
set PATH=%CD%;%PATH%

echo Starting app with full error output...
echo ========================================
echo.

excellence_coaching_hub.exe

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo APP CRASHED WITH ERROR CODE: %ERRORLEVEL%
    echo ========================================
    echo.
    echo Common solutions:
    echo 1. Install Visual C++ Redistributables (x64)
    echo 2. Run as Administrator
    echo 3. Check Windows Defender/antivirus settings
    echo 4. Try compatibility mode (Windows 10)
    echo.
) else (
    echo App started successfully!
)

pause