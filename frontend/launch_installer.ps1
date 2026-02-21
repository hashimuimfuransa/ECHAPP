# Excellence Coaching Hub Graphical Installer Launcher
# This script launches the Flutter-based installer with a proper GUI

param(
    [switch]$Verbose
)

function Write-Status {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] ERROR: $Message" -ForegroundColor Red
}

# Change to installer directory
$InstallerPath = Join-Path $PSScriptRoot "installer"
Set-Location $InstallerPath

Write-Status "Starting Excellence Coaching Hub Installer..."

# Check if Flutter is installed
Write-Status "Checking Flutter installation..."
try {
    $FlutterVersion = flutter --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter not found"
    }
    Write-Status "Flutter installation found"
} catch {
    Write-Error "Flutter is not installed or not in PATH"
    Write-Host "Please install Flutter from: https://flutter.dev/docs/get-started/install" -ForegroundColor Yellow
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Initialize Flutter project if needed
if (!(Test-Path "lib\main.dart")) {
    Write-Status "Creating Flutter project structure..."
    flutter create . --platforms=windows
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create Flutter project"
        exit 1
    }
}

# Get dependencies
Write-Status "Getting dependencies..."
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to get dependencies"
    exit 1
}

# Run the installer
Write-Status "Launching graphical installer..."
Write-Host "The installer window will appear shortly..." -ForegroundColor Yellow

# Run in debug mode (more stable on Windows)
flutter run -d windows --debug

# Keep window open if there was an error
if ($LASTEXITCODE -ne 0) {
    Write-Error "Installer exited with error code: $LASTEXITCODE"
    Write-Host "Press any key to close..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}