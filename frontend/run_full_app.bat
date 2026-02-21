@echo off
cd /d "D:\ECHAPP\frontend"

echo === Excellence Coaching Hub - Release Build Runner ===
echo.

REM Check if the executable exists
if exist "build\windows\x64\runner\Release\excellence_coaching_hub.exe" (
    echo Found executable: excellence_coaching_hub.exe
    echo Size: 
    for %%A in ("build\windows\x64\runner\Release\excellence_coaching_hub.exe") do echo %%~zA bytes
    echo.
    
    echo Starting Excellence Coaching Hub...
    echo ====================================
    
    cd "build\windows\x64\runner\Release"
    start excellence_coaching_hub.exe
    cd /d "D:\ECHAPP\frontend"
    
    echo App started successfully!
    echo.
    echo If the app doesn't appear:
    echo 1. Check Windows Task Manager for the process
    echo 2. Try running as Administrator
    echo 3. Check Windows Event Viewer for errors
    echo 4. Ensure all required DLLs are present
    
) else (
    echo ERROR: excellence_coaching_hub.exe not found!
    echo.
    echo Please build the app first:
    echo flutter build windows --release
    echo.
    echo Or check if the build is still in progress
)

echo.
pause