#!/bin/bash

echo "Building JustWrite for macOS..."
echo ""

# Download fonts if missing
echo "Checking for required fonts..."
if [ ! -f "assets/fonts/Lora-Regular.ttf" ]; then
    echo "Fonts not found. Downloading..."
    ./download_fonts.sh
    echo ""
else
    echo "Fonts already installed."
fi

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build macOS release
flutter build macos --release

echo ""
echo "Build complete!"
echo "Application location: build/macos/Build/Products/Release/justwrite.app"
echo ""
echo "To create a DMG for distribution:"
echo "1. Open Disk Utility"
echo "2. File > New Image > Image from Folder"
echo "3. Select the justwrite.app"
echo "4. Save as JustWrite.dmg"
echo ""
echo "Users can drag justwrite.app to Applications without installing Flutter."
