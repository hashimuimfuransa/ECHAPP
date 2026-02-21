# Detailed app runner with error diagnostics
Set-Location "D:\ECHAPP\frontend\build\windows\x64\runner\Release"

Write-Host "=== Excellence Coaching Hub Diagnostic Runner ===" -ForegroundColor Green
Write-Host "Current Directory: $((Get-Location).Path)" -ForegroundColor Yellow
Write-Host "PATH: $env:PATH" -ForegroundColor Yellow
Write-Host ""

# Check if executable exists
if (-not (Test-Path "excellence_coaching_hub.exe")) {
    Write-Host "ERROR: excellence_coaching_hub.exe not found!" -ForegroundColor Red
    Write-Host "Expected location: $((Get-Location).Path)\excellence_coaching_hub.exe" -ForegroundColor Red
    pause
    exit 1
}

# Check required DLLs
Write-Host "Checking required DLLs..." -ForegroundColor Cyan
$dlls = @(
    "flutter_windows.dll",
    "audioplayers_windows_plugin.dll",
    "firebase_auth_plugin.dll",
    "firebase_core_plugin.dll"
)

$missingDlls = @()
foreach ($dll in $dlls) {
    if (Test-Path $dll) {
        Write-Host "Found: $dll" -ForegroundColor Green
    } else {
        Write-Host "Missing: $dll" -ForegroundColor Red
        $missingDlls += $dll
    }
}

if ($missingDlls.Count -gt 0) {
    Write-Host ""
    Write-Host "WARNING: Missing required DLLs:" -ForegroundColor Yellow
    $missingDlls | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host ""
}

Write-Host ""
Write-Host "Starting app with detailed output..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Run the app and capture output
try {
    $process = Start-Process -FilePath ".\excellence_coaching_hub.exe" -PassThru -NoNewWindow
    Write-Host "Process started with ID: $($process.Id)" -ForegroundColor Green
    
    # Wait a moment to see if it crashes immediately
    Start-Sleep -Seconds 3
    
    if ($process.HasExited) {
        Write-Host "Process exited with code: $($process.ExitCode)" -ForegroundColor Red
        Write-Host ""
        Write-Host "=== TROUBLESHOOTING STEPS ===" -ForegroundColor Yellow
        Write-Host "1. Check Windows Event Viewer for application errors" -ForegroundColor Yellow
        Write-Host "2. Try running as Administrator" -ForegroundColor Yellow
        Write-Host "3. Install Visual C++ Redistributables (x64)" -ForegroundColor Yellow
        Write-Host "4. Check if Windows Firewall is blocking the app" -ForegroundColor Yellow
        Write-Host "5. Verify Firebase configuration is correct" -ForegroundColor Yellow
    } else {
        Write-Host "App is still running (PID: $($process.Id))" -ForegroundColor Green
        Write-Host "Press Ctrl+C to stop the app" -ForegroundColor Yellow
        $process.WaitForExit()
    }
}
catch {
    Write-Host "Error starting app: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
pause