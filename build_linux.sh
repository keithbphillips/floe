#!/bin/bash

echo "Building JustWrite for Linux..."
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

# Build Linux release
flutter build linux --release

echo ""
echo "Build complete!"
echo "Executable location: build/linux/x64/release/bundle/"
echo ""
echo "The entire bundle folder can be distributed to users."
echo "Users can run justwrite without installing Flutter."
echo ""
echo "To create a distributable archive:"
echo "cd build/linux/x64/release/"
echo "tar -czf justwrite-linux.tar.gz bundle/"
