# Setting Up Flutter on Windows for JustWrite

This guide will walk you through installing Flutter on Windows to build JustWrite.

## Prerequisites

- **Windows 10 or later** (64-bit)
- **Disk Space**: ~2.5 GB for Flutter SDK
- **Git for Windows**: Required for Flutter installation

## Installation Methods

### Method 1: Direct Download (Recommended for Beginners)

This is the simplest method - just download and extract.

#### Step 1: Download Flutter SDK

1. Go to: https://docs.flutter.dev/get-started/install/windows
2. Download the latest stable Flutter SDK ZIP file (around 800 MB)
3. Extract to a permanent location (NOT in Program Files):
   - Recommended: `C:\src\flutter`
   - Alternative: `C:\flutter`

**Important**: Do NOT install in directories with:
- Special characters or spaces
- Directories that require elevated privileges (like Program Files)

#### Step 2: Add Flutter to PATH

1. Open **Start Menu** → Search "env" → Click **Edit the system environment variables**
2. Click **Environment Variables** button
3. Under **User variables**, find **Path** and click **Edit**
4. Click **New** and add: `C:\src\flutter\bin` (or wherever you extracted Flutter)
5. Click **OK** on all dialogs
6. **Restart your terminal/command prompt** for changes to take effect

#### Step 3: Verify Installation

Open a NEW Command Prompt or PowerShell and run:
```bash
flutter --version
```

You should see output like:
```
Flutter 3.24.0 • channel stable • https://github.com/flutter/flutter.git
Framework • revision xyz
Engine • revision abc
Tools • Dart 3.5.0 • DevTools 2.37.0
```

### Method 2: Using Winget (Windows Package Manager)

If you have Windows 11 or Windows 10 with winget installed:

```bash
winget install --id=9NKSQGP7F2NH
```

Then add to PATH as described in Step 2 above.

## Running Flutter Doctor

Flutter includes a diagnostic tool to check your setup:

```bash
flutter doctor
```

You'll see something like:
```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.24.0, on Microsoft Windows...)
[✗] Android toolchain - Android SDK not installed
[✓] Chrome - develop for the web
[✓] Visual Studio - develop Windows apps (Visual Studio Community 2022)
[!] Android Studio (not installed)
[✓] VS Code (version 1.85.0)
```

### What You Need for JustWrite (Desktop Windows)

For building JustWrite on Windows, you need:

✅ **Flutter SDK** (you just installed this)
✅ **Visual Studio 2022** (see below)

You DON'T need:
❌ Android toolchain (only for Android apps)
❌ Android Studio (only for Android apps)
❌ Xcode (only for iOS/macOS apps)

## Installing Visual Studio 2022

Flutter needs Visual Studio to compile Windows desktop apps.

### Step 1: Download Visual Studio

Go to: https://visualstudio.microsoft.com/downloads/

Download **Visual Studio 2022 Community** (free)

### Step 2: Install with C++ Tools

During installation:
1. Select **"Desktop development with C++"** workload
2. In the right panel, ensure these are checked:
   - MSVC v143 - VS 2022 C++ x64/x86 build tools
   - Windows 10/11 SDK
   - C++ CMake tools for Windows

3. Click **Install** (this will take 10-20 minutes)

### Step 3: Verify

Run flutter doctor again:
```bash
flutter doctor
```

You should now see:
```
[✓] Visual Studio - develop Windows apps (Visual Studio Community 2022)
```

## Enable Windows Desktop Development

Run this command to ensure Windows desktop is enabled:
```bash
flutter config --enable-windows-desktop
```

## Enable Windows Developer Mode (REQUIRED)

Flutter requires Developer Mode to be enabled on Windows to create symbolic links needed for plugins.

**Quick Enable:**
1. Press `Win+R` and type: `ms-settings:developers`
2. Toggle "Developer Mode" to **ON**
3. Confirm any prompts and wait for Windows to apply changes

**Or use command:**
```bash
start ms-settings:developers
```

**Why is this needed?**
Flutter uses symbolic links when building Windows apps with plugins (like file_picker, path_provider, etc.). Developer Mode is safe for development and is Microsoft's recommended setting for developers.

**Note:** This is a one-time setting. You won't need to do this again.

## Final Verification

Check that everything is ready:
```bash
flutter doctor -v
```

For JustWrite, you should see checkmarks (✓) for:
- Flutter
- Windows toolchain / Visual Studio
- (Chrome is optional, for web development)

## Building JustWrite

Once setup is complete:

1. Navigate to the JustWrite directory:
```bash
cd E:\Unity\justwrite
```

2. Get dependencies:
```bash
flutter pub get
```

3. Download the required fonts (see assets/fonts/README.md)

4. Build:
```bash
build_windows.bat
```

OR manually:
```bash
flutter build windows --release
```

## Troubleshooting

### "flutter is not recognized"
- Restart your terminal after adding to PATH
- Verify PATH was added correctly
- Try opening a new PowerShell/Command Prompt window

### "Visual Studio not found"
Run:
```bash
flutter doctor -v
```
Look at the detailed output for what's missing. Usually you need:
- Visual Studio 2022 (not just VS Code)
- Desktop development with C++ workload

### "Unable to find suitable Visual Studio toolchain"
Make sure you installed:
- Visual Studio Community 2022 (not an older version)
- The "Desktop development with C++" workload
- Windows 10/11 SDK

### Permission errors during build
- Don't run as Administrator
- Make sure your project is not in a protected folder
- Close any antivirus that might be scanning the build folder

### Build takes very long or fails
- First build is always slow (10-15 minutes)
- Subsequent builds are much faster (30 seconds - 2 minutes)
- Make sure you have at least 5 GB free disk space

## Alternative: Using Chocolatey

If you have Chocolatey package manager:

```bash
choco install flutter
choco install visualstudio2022community --package-parameters "--add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended"
```

## Next Steps

After installation is complete:
1. Read the main README.md for JustWrite features
2. Check BUILDING.md for distribution instructions
3. Start building: `build_windows.bat`

## Useful Commands

```bash
# Check Flutter installation
flutter doctor -v

# Update Flutter to latest
flutter upgrade

# Clean build artifacts
flutter clean

# Run in debug mode (for testing)
flutter run -d windows

# Build release version
flutter build windows --release

# Check what devices are available
flutter devices
```

## Disk Space Summary

- Flutter SDK: ~2.5 GB
- Visual Studio 2022 (minimal): ~8 GB
- Build artifacts (after first build): ~500 MB
- Total: ~11 GB

## Time Estimate

- Download Flutter: 5-10 minutes
- Download Visual Studio: 10-15 minutes
- Install Visual Studio: 10-20 minutes
- First build of JustWrite: 10-15 minutes
- **Total setup time: ~45-60 minutes**

Subsequent builds take only 1-2 minutes.
