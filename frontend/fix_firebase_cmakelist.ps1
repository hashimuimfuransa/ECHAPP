# Script to fix Firebase CMakeLists.txt file and build Flutter Windows app

# Add CMake to PATH if not already present
if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    $cmakePath = "C:\Program Files\CMake\bin"
    if (Test-Path $cmakePath) {
        $env:PATH += ";$cmakePath"
        Write-Host "Added CMake to PATH: $cmakePath"
    }
}

# Add nuget.exe to PATH if not already present
$nugetExe = "D:\ECHAPP\frontend\nuget.exe"
if ((Test-Path $nugetExe) -and (-not (Get-Command nuget -ErrorAction SilentlyContinue))) {
    $env:PATH += ";D:\ECHAPP\frontend"
    Write-Host "Added nuget.exe to PATH"
}

# Check CMake version
try {
    $cmakeVersion = cmake --version | Select-String "cmake version" | ForEach-Object { $_.ToString().Split(' ')[2] }
    Write-Host "CMake version: $cmakeVersion"
} catch {
    Write-Host "Error checking CMake version: $_"
    exit 1
}

$firebaseCMakePath = "D:\ECHAPP\frontend\build\windows\x64\extracted\firebase_cpp_sdk_windows\CMakeLists.txt"

# Check if the file exists
if (Test-Path $firebaseCMakePath) {
    # Read the content of the file
    $content = Get-Content $firebaseCMakePath -Raw
    
    # Check if it contains the old version and update it
    if ($content -match "cmake_minimum_required\(VERSION 3\.1\)") {
        $content = $content -replace "cmake_minimum_required\(VERSION 3\.1\)", "cmake_minimum_required(VERSION 3.14)"
        $content | Set-Content $firebaseCMakePath -NoNewline
        Write-Host "Firebase CMakeLists.txt updated from VERSION 3.1 to VERSION 3.14"
    } else {
        Write-Host "Firebase CMakeLists.txt is already updated or uses a different version"
    }
} else {
    Write-Host "Firebase CMakeLists.txt file not found at: $firebaseCMakePath"
    Write-Host "This might be because the build hasn't been run yet. Proceeding with Flutter build..."
}

# Also update the main CMakeLists.txt to use Debug runtime for Release builds
$mainCMakePath = "D:\ECHAPP\frontend\windows\CMakeLists.txt"
if (Test-Path $mainCMakePath) {
    $mainContent = Get-Content $mainCMakePath -Raw
    $mainUpdated = $false
    
    # Add Debug runtime configuration for Release builds
    $releaseConfigSection = @"

# Define settings for the Release build mode to use Debug runtime
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_DEBUG}")
set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_DEBUG}")
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_DEBUG}")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_DEBUG}")
"@
    
    # Check if the configuration already exists
    if (-not ($mainContent -match "CMAKE_EXE_LINKER_FLAGS_RELEASE.*CMAKE_EXE_LINKER_FLAGS_DEBUG")) {
        # Find the line where Profile settings end and add Release settings
        if ($mainContent -match "CMAKE_CXX_FLAGS_PROFILE.*CMAKE_CXX_FLAGS_DEBUG") {
            $mainContent = $mainContent -replace "(CMAKE_CXX_FLAGS_PROFILE.*CMAKE_CXX_FLAGS_DEBUG)", "`$1$releaseConfigSection"
            $mainContent | Set-Content $mainCMakePath -NoNewline
            $mainUpdated = $true
            Write-Host "Main CMakeLists.txt updated to use Debug runtime for Release builds"
        }
    }
    
    if ($mainUpdated) {
        Write-Host "Main CMakeLists.txt has been updated to use Debug runtime for Release builds!"
    }
}

# Handle Firebase SDK libs directory
$libsDir = "D:\ECHAPP\frontend\build\windows\x64\extracted\firebase_cpp_sdk_windows\libs"
if (!(Test-Path $libsDir)) {
    Write-Host "Libs directory missing. Checking for the zip file to extract..."
    
    $zipFile = "D:\ECHAPP\frontend\build\windows\x64\firebase_cpp_sdk_windows_12.7.0.zip"
    if (Test-Path $zipFile) {
        $extractPath = "D:\ECHAPP\frontend\build\windows\x64\temp_extract"
        if (Test-Path $extractPath) {
            Remove-Item -Recurse -Force $extractPath
        }
        
        # Extract the zip file
        Write-Host "Extracting Firebase SDK..."
        Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force
        
        # Copy the libs directory
        $sourceLibs = Join-Path $extractPath "firebase_cpp_sdk_windows\libs"
        if (Test-Path $sourceLibs) {
            $destLibs = "D:\ECHAPP\frontend\build\windows\x64\extracted\firebase_cpp_sdk_windows\libs"
            if (-not (Test-Path (Split-Path $destLibs))) {
                New-Item -ItemType Directory -Path (Split-Path $destLibs) -Force
            }
            Copy-Item -Path $sourceLibs -Destination $destLibs -Recurse -Force
            Write-Host "Libs directory copied successfully!"
        } else {
            Write-Host "Source libs directory not found in extracted content."
        }
        
        # Clean up temp directory
        if (Test-Path $extractPath) {
            Remove-Item -Recurse -Force $extractPath
        }
    } else {
        Write-Host "Firebase SDK zip file not found: $zipFile"
    }
} else {
    Write-Host "Libs directory already exists."
}

# Now run Flutter build
Write-Host "`n=== Starting Flutter Build ==="
Set-Location "D:\ECHAPP\frontend"

# Clean previous build
Write-Host "Cleaning previous build..."
flutter clean

# Get packages
Write-Host "Getting packages..."
flutter pub get

# Build Windows release with CMake policy override
Write-Host "Building Windows release with CMake policy override..."
$env:CMAKE_POLICY_VERSION_MINIMUM = "3.5"
flutter build windows --release

Write-Host "`n=== Build Complete ==="
Write-Host "If successful, your app is located at: build\windows\x64\runner\Release\"