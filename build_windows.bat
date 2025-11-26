@echo off
echo Building JustWrite for Windows...
echo.

REM Download fonts if missing
echo Checking for required fonts...
if not exist "assets\fonts\Lora-Regular.ttf" (
    echo Fonts not found. Downloading...
    powershell.exe -ExecutionPolicy Bypass -File "download_fonts.ps1"
    echo.
) else (
    echo Fonts already installed.
)

REM Clean previous builds
flutter clean

REM Get dependencies
flutter pub get

REM Build Windows release
flutter build windows --release

echo.
echo Build complete!
echo Executable location: build\windows\x64\runner\Release\
echo.
echo The entire Release folder can be distributed to users.
echo Users can run justwrite.exe without installing Flutter.
pause
