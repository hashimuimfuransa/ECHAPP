@echo off
setlocal enabledelayedexpansion

title Excellence Coaching Hub Installer
cls
echo ========================================
echo Excellence Coaching Hub Installer
echo ========================================
echo.

cd /d "%~dp0installer"

:: Check if Flutter is installed
echo Checking Flutter installation...
flutter --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: Flutter is not installed or not in PATH!
    echo Please install Flutter and make sure it's accessible from command line.
    echo Download Flutter from: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo Flutter found. Initializing installer...

:: Initialize Flutter project if needed
if not exist "lib\main.dart" (
    echo Creating Flutter project structure...
    flutter create . --platforms=windows
    if !ERRORLEVEL! NEQ 0 (
        echo Failed to create Flutter project!
        pause
        exit /b 1
    )
)

:: Get dependencies
echo Getting dependencies...
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo Failed to get dependencies!
    pause
    exit /b 1
)

:: Build and run the installer
echo Starting graphical installer...
echo This may take a few moments to initialize...
flutter run -d windows --debug