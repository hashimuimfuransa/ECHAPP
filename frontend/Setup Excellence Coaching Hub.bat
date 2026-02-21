@echo off
title Installing Excellence Coaching Hub...

:: Run the invisible installer
powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0install_invisible.ps1"

:: Check if installation was successful
if %ERRORLEVEL% EQU 0 (
    :: Show success message
    powershell -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('Excellence Coaching Hub has been successfully installed!`n`nYou can now use the desktop shortcut to launch the application.', 'Installation Complete', 'OK', 'Information')"
) else (
    :: Show error message
    powershell -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('Installation failed. Please make sure Flutter is installed and try again.', 'Installation Failed', 'OK', 'Error')"
)

exit