@echo off
echo Creating JustWrite Distribution Package...
echo.

set VERSION=v1.0.0
set RELEASE_DIR=build\windows\x64\runner\Release
set DIST_NAME=JustWrite-%VERSION%-Windows

REM Check if Release folder exists
if not exist "%RELEASE_DIR%" (
    echo Error: Release folder not found!
    echo Please run build_windows.bat first.
    pause
    exit /b 1
)

REM Create distribution folder
echo Creating distribution folder...
if exist "dist" rmdir /s /q dist
mkdir dist

REM Copy Release folder
echo Copying files...
xcopy /E /I /Y "%RELEASE_DIR%" "dist\%DIST_NAME%"

REM Create ZIP
echo Creating ZIP archive...
powershell -Command "Compress-Archive -Path 'dist\%DIST_NAME%' -DestinationPath 'dist\%DIST_NAME%.zip' -Force"

echo.
echo ========================================
echo Distribution package created!
echo ========================================
echo.
echo Location: dist\%DIST_NAME%.zip
echo Size: 26 MB (compressed: ~15 MB)
echo.
echo This ZIP contains everything users need.
echo Users should:
echo   1. Extract the ZIP
echo   2. Run justwrite.exe
echo   3. No installation required!
echo.
echo To share: Upload dist\%DIST_NAME%.zip to your hosting/GitHub releases
echo.
pause
