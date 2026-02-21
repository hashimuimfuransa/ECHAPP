@echo off
cd /d "D:\ECHAPP\frontend"

echo === Creating Minimal Working App ===

REM Backup current pubspec.yaml
echo Backing up current pubspec.yaml...
copy pubspec.yaml pubspec.yaml.backup >nul

REM Replace with minimal version
echo Replacing with minimal pubspec...
copy pubspec_minimal.yaml pubspec.yaml >nul

REM Clean build
echo Cleaning build...
flutter clean >nul 2>&1

REM Get dependencies
echo Getting minimal dependencies...
flutter pub get

REM Build Windows app
echo Building minimal Windows app...
flutter build windows --release

REM Check if build succeeded
if exist "build\windows\x64\runner\Release\minimal_test_app.exe" (
    echo.
    echo *** SUCCESS! ***
    echo Minimal app built successfully!
    echo Location: build\windows\x64\runner\Release\minimal_test_app.exe
    echo.
    echo Testing the app...
    cd build\windows\x64\runner\Release
    start minimal_test_app.exe
    cd /d "D:\ECHAPP\frontend"
) else (
    echo.
    echo *** BUILD FAILED ***
    echo Could not create executable
)

REM Restore original pubspec.yaml
echo Restoring original pubspec.yaml...
copy pubspec.yaml.backup pubspec.yaml >nul
del pubspec.yaml.backup >nul

echo.
echo Process completed!
pause