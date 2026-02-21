@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0install_app.ps1" -CreateDesktopShortcut -CreateStartMenuShortcut
pause