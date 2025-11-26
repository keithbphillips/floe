# Flutter Installation Script for Windows
# This script downloads and installs Flutter SDK

Write-Host "=== Flutter Installation Script ===" -ForegroundColor Cyan
Write-Host ""

# Configuration
$FlutterDir = "C:\src\flutter"
$FlutterZip = "$env:TEMP\flutter_windows.zip"
$FlutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip"

# Step 1: Check if Flutter is already installed
Write-Host "Checking if Flutter is already installed..." -ForegroundColor Yellow
$env:PATH = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    Write-Host "Flutter is already installed!" -ForegroundColor Green
    flutter --version
    exit 0
}

# Step 2: Create installation directory
Write-Host "Creating installation directory: $FlutterDir" -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "C:\src" | Out-Null

# Step 3: Download Flutter SDK
Write-Host "Downloading Flutter SDK..." -ForegroundColor Yellow
Write-Host "This may take 5-10 minutes (file size: ~850 MB)" -ForegroundColor Gray
try {
    # Use .NET WebClient for better progress reporting
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($FlutterUrl, $FlutterZip)
    Write-Host "Download complete!" -ForegroundColor Green
} catch {
    Write-Host "Download failed: $_" -ForegroundColor Red
    exit 1
}

# Step 4: Extract Flutter SDK
Write-Host "Extracting Flutter SDK to C:\src\..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Gray
try {
    Expand-Archive -Path $FlutterZip -DestinationPath "C:\src\" -Force
    Write-Host "Extraction complete!" -ForegroundColor Green
} catch {
    Write-Host "Extraction failed: $_" -ForegroundColor Red
    exit 1
}

# Step 5: Clean up downloaded ZIP
Remove-Item $FlutterZip -Force
Write-Host "Cleaned up temporary files" -ForegroundColor Green

# Step 6: Add Flutter to PATH
Write-Host "Adding Flutter to PATH..." -ForegroundColor Yellow
$FlutterBin = "$FlutterDir\bin"
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ($UserPath -notlike "*$FlutterBin*") {
    [Environment]::SetEnvironmentVariable(
        "Path",
        "$UserPath;$FlutterBin",
        "User"
    )
    Write-Host "Flutter added to PATH!" -ForegroundColor Green
} else {
    Write-Host "Flutter is already in PATH" -ForegroundColor Green
}

# Step 7: Refresh PATH for current session
$env:PATH = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Step 8: Verify installation
Write-Host ""
Write-Host "Verifying Flutter installation..." -ForegroundColor Yellow
Write-Host ""
& "$FlutterBin\flutter.bat" --version

Write-Host ""
Write-Host "=== Installation Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT: Close and reopen your terminal for PATH changes to take effect." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Close this terminal window" -ForegroundColor White
Write-Host "2. Open a NEW PowerShell or Command Prompt" -ForegroundColor White
Write-Host "3. Run: flutter doctor" -ForegroundColor White
Write-Host "4. Install Visual Studio 2022 if needed (see SETUP_WINDOWS.md)" -ForegroundColor White
Write-Host ""
