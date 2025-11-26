# Building JustWrite for Distribution

This guide explains how to build standalone executables that users can run without installing Flutter.

## Quick Build

### Windows
```bash
build_windows.bat
```
This creates a standalone executable in `build/windows/x64/runner/Release/`

### macOS
```bash
chmod +x build_macos.sh
./build_macos.sh
```
This creates a standalone .app in `build/macos/Build/Products/Release/`

### Linux
```bash
chmod +x build_linux.sh
./build_linux.sh
```
This creates a standalone executable in `build/linux/x64/release/bundle/`

## What Gets Built

Flutter compiles your app into native machine code for each platform. The output is a fully self-contained application that includes:

- The Dart runtime
- Your application code (compiled to native)
- All dependencies
- Flutter engine
- Platform-specific libraries

Users don't need to install Flutter, Dart, or any other dependencies.

## Distribution Package Creation

### Windows Distribution

1. Run `build_windows.bat`
2. Navigate to `build/windows/x64/runner/Release/`
3. ZIP the entire `Release` folder:
   - Right-click the folder
   - Send to > Compressed (zipped) folder
   - Rename to `justwrite-windows-v1.0.0.zip`
4. Distribute the ZIP file

**End User Instructions:**
- Extract the ZIP file
- Run `justwrite.exe`
- No installation required

### macOS Distribution

1. Run `./build_macos.sh`
2. Navigate to `build/macos/Build/Products/Release/`
3. Create a DMG file:

**Option A: Using Disk Utility**
```bash
hdiutil create -volname "JustWrite" -srcfolder justwrite.app -ov -format UDZO justwrite-macos-v1.0.0.dmg
```

**Option B: Using Disk Utility GUI**
- Open Disk Utility
- File > New Image > Image from Folder
- Select `justwrite.app`
- Save as `justwrite-macos-v1.0.0.dmg`

4. Distribute the DMG file

**End User Instructions:**
- Open the DMG file
- Drag JustWrite.app to Applications folder
- No installation required

**Note:** For distribution outside the Mac App Store, you may need to code sign the app. See [Apple's documentation](https://developer.apple.com/support/code-signing/) for details.

### Linux Distribution

1. Run `./build_linux.sh`
2. Navigate to `build/linux/x64/release/`
3. Create a tarball:
```bash
tar -czf justwrite-linux-v1.0.0.tar.gz bundle/
```
4. Distribute the tar.gz file

**End User Instructions:**
```bash
tar -xzf justwrite-linux-v1.0.0.tar.gz
cd bundle
./justwrite
```

**Optional:** Create a .desktop file for launcher integration:
```bash
[Desktop Entry]
Name=JustWrite
Comment=Distraction-free word processor
Exec=/path/to/justwrite/bundle/justwrite
Icon=/path/to/justwrite/bundle/data/flutter_assets/assets/icon.png
Terminal=false
Type=Application
Categories=Office;WordProcessor;
```

## Package Sizes

After compression:
- **Windows**: 25-30 MB
- **macOS**: 20-25 MB
- **Linux**: 25-30 MB

The size includes the entire Flutter runtime and your application.

## Automated Builds with GitHub Actions

This repository includes a GitHub Actions workflow that automatically builds for all platforms when you create a release tag:

1. Commit your changes
2. Create and push a tag:
```bash
git tag v1.0.0
git push origin v1.0.0
```
3. GitHub Actions will automatically:
   - Build for Windows, macOS, and Linux
   - Create release packages
   - Upload them to GitHub Releases

Check `.github/workflows/build-release.yml` for details.

## Code Signing

### Windows
For production distribution, consider signing with a certificate to avoid Windows Defender warnings:
```bash
signtool sign /f certificate.pfx /p password /t http://timestamp.digicert.com justwrite.exe
```

### macOS
Sign and notarize for Gatekeeper:
```bash
codesign --deep --force --verify --verbose --sign "Developer ID Application: Your Name" justwrite.app
xcrun notarytool submit justwrite.app --apple-id "your@email.com" --password "app-specific-password"
```

### Linux
AppImage or Snap packages are good alternatives for easier distribution:
- [AppImage documentation](https://appimage.org/)
- [Snapcraft documentation](https://snapcraft.io/)

## Troubleshooting

### "DLL not found" errors on Windows
Ensure the entire Release folder is distributed, not just the .exe file.

### "App is damaged" on macOS
Users may need to run: `xattr -cr /Applications/justwrite.app`

### "Permission denied" on Linux
Make the executable runnable: `chmod +x justwrite`

## Version Management

Update the version in `pubspec.yaml` before building:
```yaml
version: 1.0.0+1
```

The format is `major.minor.patch+build` (e.g., `1.2.3+4`)

## Testing Builds

Before distribution, test on clean machines without Flutter installed to ensure everything works as expected.
