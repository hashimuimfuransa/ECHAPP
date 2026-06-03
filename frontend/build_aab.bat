@echo off
:: Build Android App Bundle (AAB) for Play Store
:: This creates a signed release AAB

title Excellence Coaching Hub - AAB Builder
color 0A
cls

echo.
echo  ╔══════════════════════════════════════════════════════════════╗
echo  ║         BUILDING ANDROID APP BUNDLE (AAB)                 ║
echo  ╚══════════════════════════════════════════════════════════════╝
echo.

:: Navigate to frontend directory
cd /d "%~dp0"

echo Step 1: Cleaning previous builds...
flutter clean

echo.
echo Step 2: Getting dependencies...
flutter pub get

echo.
echo Step 3: Building Android App Bundle (Release)...
flutter build appbundle --release

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  ╔══════════════════════════════════════════════════════════════╗
    echo  ║                    BUILD FAILED!                            ║
    echo  ╚══════════════════════════════════════════════════════════════╝
    echo.
    echo Please check:
    echo - Flutter is installed and in PATH
    echo - Android SDK is properly configured
    echo - key.properties exists with valid signing config
    echo.
    pause
    exit /b 1
)

echo.
echo  ╔══════════════════════════════════════════════════════════════╗
echo  ║                 BUILD SUCCESSFUL!                           ║
echo  ╚══════════════════════════════════════════════════════════════╝
echo.
echo Your AAB file is located at:
echo build\app\outputs\bundle\release\app-release.aab
echo.
echo Next steps:
echo 1. Upload the AAB to Google Play Console
echo 2. Or run: flutter install to install locally
echo.
pause
