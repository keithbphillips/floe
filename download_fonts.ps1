# Font Download Script for JustWrite
# This script automatically downloads the required fonts from Google Fonts

Write-Host "=== JustWrite Font Download Script ===" -ForegroundColor Cyan
Write-Host ""

$FontsDir = "E:\Unity\justwrite\assets\fonts"
$TempDir = "$env:TEMP\justwrite_fonts"

# Create directories
Write-Host "Creating fonts directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $FontsDir | Out-Null
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

# Font URLs (direct links from GitHub - Google Fonts repository)
$LoraRegularUrl = "https://github.com/google/fonts/raw/main/ofl/lora/Lora%5Bwght%5D.ttf"
$LoraBoldUrl = "https://github.com/google/fonts/raw/main/ofl/lora/Lora-Italic%5Bwght%5D.ttf"
$IBMPlexMonoUrl = "https://github.com/google/fonts/raw/main/ofl/ibmplexmono/IBMPlexMono-Regular.ttf"

# Actually, let's use the static fonts which are easier
$LoraRegularUrl = "https://github.com/google/fonts/raw/main/ofl/lora/static/Lora-Regular.ttf"
$LoraBoldUrl = "https://github.com/google/fonts/raw/main/ofl/lora/static/Lora-Bold.ttf"
$IBMPlexMonoUrl = "https://github.com/google/fonts/raw/main/ofl/ibmplexmono/IBMPlexMono-Regular.ttf"

# Download Lora Regular
Write-Host "Downloading Lora-Regular.ttf..." -ForegroundColor Yellow
try {
    $process = Start-Process -FilePath "curl" -ArgumentList "-L", "$LoraRegularUrl", "-o", "$FontsDir\Lora-Regular.ttf", "-s" -Wait -PassThru -NoNewWindow
    if ($process.ExitCode -eq 0 -and (Test-Path "$FontsDir\Lora-Regular.ttf")) {
        Write-Host "  Lora-Regular.ttf installed!" -ForegroundColor Green
    } else {
        Write-Host "  Failed to download Lora-Regular" -ForegroundColor Red
    }
} catch {
    Write-Host "  Failed to download Lora-Regular: $_" -ForegroundColor Red
}

# Download Lora Bold
Write-Host "Downloading Lora-Bold.ttf..." -ForegroundColor Yellow
try {
    $process = Start-Process -FilePath "curl" -ArgumentList "-L", "$LoraBoldUrl", "-o", "$FontsDir\Lora-Bold.ttf", "-s" -Wait -PassThru -NoNewWindow
    if ($process.ExitCode -eq 0 -and (Test-Path "$FontsDir\Lora-Bold.ttf")) {
        Write-Host "  Lora-Bold.ttf installed!" -ForegroundColor Green
    } else {
        Write-Host "  Failed to download Lora-Bold" -ForegroundColor Red
    }
} catch {
    Write-Host "  Failed to download Lora-Bold: $_" -ForegroundColor Red
}

# Download IBM Plex Mono
Write-Host "Downloading IBMPlexMono-Regular.ttf..." -ForegroundColor Yellow
try {
    $process = Start-Process -FilePath "curl" -ArgumentList "-L", "$IBMPlexMonoUrl", "-o", "$FontsDir\IBMPlexMono-Regular.ttf", "-s" -Wait -PassThru -NoNewWindow
    if ($process.ExitCode -eq 0 -and (Test-Path "$FontsDir\IBMPlexMono-Regular.ttf")) {
        Write-Host "  IBMPlexMono-Regular.ttf installed!" -ForegroundColor Green
    } else {
        Write-Host "  Failed to download IBM Plex Mono" -ForegroundColor Red
    }
} catch {
    Write-Host "  Failed to download IBM Plex Mono: $_" -ForegroundColor Red
}

# Clean up temporary files
Write-Host "Cleaning up temporary files..." -ForegroundColor Yellow
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue

# Verify installation
Write-Host ""
Write-Host "=== Font Installation Summary ===" -ForegroundColor Cyan
$requiredFonts = @("Lora-Regular.ttf", "Lora-Bold.ttf", "IBMPlexMono-Regular.ttf")
$allInstalled = $true

foreach ($font in $requiredFonts) {
    $fontPath = Join-Path $FontsDir $font
    if (Test-Path $fontPath) {
        Write-Host "[OK] $font" -ForegroundColor Green
    } else {
        Write-Host "[MISSING] $font" -ForegroundColor Red
        $allInstalled = $false
    }
}

Write-Host ""
if ($allInstalled) {
    Write-Host "All fonts installed successfully!" -ForegroundColor Green
    Write-Host "You can now run: flutter build windows --release" -ForegroundColor Cyan
} else {
    Write-Host "Some fonts are missing. Please download them manually:" -ForegroundColor Yellow
    Write-Host "  Lora: https://fonts.google.com/specimen/Lora" -ForegroundColor White
    Write-Host "  IBM Plex Mono: https://fonts.google.com/specimen/IBM+Plex+Mono" -ForegroundColor White
    Write-Host "Place the .ttf files in: $FontsDir" -ForegroundColor White
}
Write-Host ""
