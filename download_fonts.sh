#!/bin/bash

# Font Download Script for JustWrite (macOS/Linux)
# This script automatically downloads the required fonts from Google Fonts

echo "=== JustWrite Font Download Script ==="
echo ""

FONTS_DIR="assets/fonts"
TEMP_DIR="/tmp/justwrite_fonts"

# Create directories
echo "Creating fonts directory..."
mkdir -p "$FONTS_DIR"
mkdir -p "$TEMP_DIR"

# Font URLs (direct links from GitHub - Google Fonts repository)
LORA_REGULAR_URL="https://github.com/google/fonts/raw/main/ofl/lora/static/Lora-Regular.ttf"
LORA_BOLD_URL="https://github.com/google/fonts/raw/main/ofl/lora/static/Lora-Bold.ttf"
IBM_PLEX_MONO_URL="https://github.com/google/fonts/raw/main/ofl/ibmplexmono/IBMPlexMono-Regular.ttf"

# Download Lora Regular
echo "Downloading Lora-Regular.ttf..."
if curl -L -o "$FONTS_DIR/Lora-Regular.ttf" "$LORA_REGULAR_URL" 2>/dev/null; then
    echo "  Lora-Regular.ttf installed!"
else
    echo "  Failed to download Lora-Regular"
fi

# Download Lora Bold
echo "Downloading Lora-Bold.ttf..."
if curl -L -o "$FONTS_DIR/Lora-Bold.ttf" "$LORA_BOLD_URL" 2>/dev/null; then
    echo "  Lora-Bold.ttf installed!"
else
    echo "  Failed to download Lora-Bold"
fi

# Download IBM Plex Mono
echo "Downloading IBMPlexMono-Regular.ttf..."
if curl -L -o "$FONTS_DIR/IBMPlexMono-Regular.ttf" "$IBM_PLEX_MONO_URL" 2>/dev/null; then
    echo "  IBMPlexMono-Regular.ttf installed!"
else
    echo "  Failed to download IBM Plex Mono"
fi

# Clean up temporary files
echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

# Verify installation
echo ""
echo "=== Font Installation Summary ==="
all_installed=true

for font in "Lora-Regular.ttf" "Lora-Bold.ttf" "IBMPlexMono-Regular.ttf"; do
    if [ -f "$FONTS_DIR/$font" ]; then
        echo "[OK] $font"
    else
        echo "[MISSING] $font"
        all_installed=false
    fi
done

echo ""
if [ "$all_installed" = true ]; then
    echo "All fonts installed successfully!"
    echo "You can now run: flutter build macos --release (or linux)"
else
    echo "Some fonts are missing. Please download them manually:"
    echo "  Lora: https://fonts.google.com/specimen/Lora"
    echo "  IBM Plex Mono: https://fonts.google.com/specimen/IBM+Plex+Mono"
    echo "Place the .ttf files in: $FONTS_DIR"
fi
echo ""
