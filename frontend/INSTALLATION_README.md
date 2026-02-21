# Excellence Coaching Hub Installation

## Modern Installation Wizard

This repository includes a modern, graphical installer for Excellence Coaching Hub that provides a user-friendly installation experience similar to professional software installers.

## Features

- **Modern UI**: Clean, professional interface with step-by-step installation
- **Progress Tracking**: Visual progress indicators throughout the installation
- **License Agreement**: Built-in EULA acceptance
- **Customizable Installation Path**: Choose where to install the application
- **Automatic Shortcuts**: Creates desktop and start menu shortcuts
- **Error Handling**: Graceful error handling with user-friendly messages

## Installation Methods

### Method 1: Graphical Installer (Recommended)
1. Double-click `run_installer.bat` in the frontend folder
2. Follow the on-screen instructions
3. The installer will guide you through the entire process

### Method 2: Quick Installation
1. Double-click `install_debug.bat` for immediate installation
2. Creates desktop shortcut automatically
3. Uses debug build (more stable for Windows)

### Method 3: Manual Installation
1. Run `flutter build windows --release`
2. Copy the build output to your desired location
3. Create shortcuts manually

## Installer Steps

1. **Welcome Screen** - Introduction to the application
2. **License Agreement** - End User License Agreement
3. **Installation Location** - Choose installation directory
4. **Ready to Install** - Installation summary
5. **Installing** - Progress tracking during installation
6. **Complete** - Success confirmation and launch options

## Technical Details

- Built with Flutter for cross-platform compatibility
- Uses Windows-specific APIs for shortcut creation
- Handles file copying and directory management
- Provides detailed logging and error reporting

## Requirements

- Windows 10/11
- Flutter SDK installed and in PATH
- Visual Studio with C++ build tools
- Internet connection for initial build

## Troubleshooting

If the installer fails:
1. Ensure Flutter is properly installed
2. Check that all dependencies are available
3. Run as administrator if needed
4. Check Windows Event Viewer for detailed error logs

## Files Included

- `installer/` - Flutter installer project
- `run_installer.bat` - Launcher for the graphical installer
- `install_debug.bat` - Quick installation script
- `install_app.ps1` - PowerShell installation script
- `build_installer.bat` - Build script for the installer