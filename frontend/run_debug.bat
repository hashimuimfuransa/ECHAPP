@echo off
cd /d "D:\ECHAPP\frontend\build\windows\x64\runner\Release"
echo Starting Excellence Coaching Hub...
echo Current directory: %CD%
echo PATH: %PATH%
echo.

echo Running app with debug output...
echo ================================

excellence_coaching_hub.exe 2>&1 | findstr /V "DebugPrint"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo APP FAILED TO START
    echo Error code: %ERRORLEVEL%
    echo ========================================
    echo.
    echo Common solutions:
    echo 1. Make sure all required DLLs are present
    echo 2. Check Windows Event Viewer for detailed errors
    echo 3. Try running as administrator
    echo 4. Install Visual C++ Redistributables
    echo.
    pause
) else (
    echo App started successfully!
)

pause