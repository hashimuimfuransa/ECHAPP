# Excellence Coaching Hub - Release Build Runner
Set-Location "D:\ECHAPP\frontend"

Write-Host "=== Excellence Coaching Hub - Release Build Runner ===" -ForegroundColor Green
Write-Host ""

# Check if the executable exists
$exePath = "build\windows\x64\runner\Release\excellence_coaching_hub.exe"
if (Test-Path $exePath) {
    $fileInfo = Get-Item $exePath
    Write-Host "Found executable: excellence_coaching_hub.exe" -ForegroundColor Green
    Write-Host "Size: $($fileInfo.Length) bytes" -ForegroundColor Yellow
    Write-Host "Last modified: $($fileInfo.LastWriteTime)" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Starting Excellence Coaching Hub..." -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    
    try {
        $process = Start-Process -FilePath $exePath -PassThru
        Write-Host "App started successfully! Process ID: $($process.Id)" -ForegroundColor Green
        Write-Host ""
        Write-Host "App should now be visible on your screen." -ForegroundColor Yellow
        Write-Host "If you don't see it:" -ForegroundColor Yellow
        Write-Host "1. Check Windows Task Manager for the process" -ForegroundColor Yellow
        Write-Host "2. Try running as Administrator" -ForegroundColor Yellow
        Write-Host "3. Check Windows Event Viewer for errors" -ForegroundColor Yellow
        Write-Host "4. Ensure all required DLLs are present" -ForegroundColor Yellow
        
        # Wait a moment to see if it crashes immediately
        Start-Sleep -Seconds 2
        if ($process.HasExited) {
            Write-Host "WARNING: Process exited quickly (code: $($process.ExitCode))" -ForegroundColor Red
        } else {
            Write-Host "App is still running normally" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Error starting app: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "ERROR: excellence_coaching_hub.exe not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please build the app first:" -ForegroundColor Yellow
    Write-Host "flutter build windows --release" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Or check if the build is still in progress" -ForegroundColor Yellow
}

Write-Host ""
pause