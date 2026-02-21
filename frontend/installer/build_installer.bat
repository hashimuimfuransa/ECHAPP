@echo off
echo Building Excellence Coaching Hub Installer...
cd /d "%~dp0"

echo Initializing Flutter project...
flutter create . --platforms=windows
if %ERRORLEVEL% NEQ 0 (
    echo Failed to create Flutter project!
    pause
    exit /b 1
)

echo Getting dependencies...
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo Failed to get dependencies!
    pause
    exit /b 1
)

echo Building Windows installer...
flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo Failed to build installer!
    pause
    exit /b 1
)

echo Creating installer package...
if not exist "dist" mkdir "dist"
xcopy /E /Y "build\windows\x64\runner\Release\*" "dist\"

echo Installer built successfully!
echo Installer location: %~dp0dist\
pause