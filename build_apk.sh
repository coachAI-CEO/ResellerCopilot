#!/bin/bash
# Build Android APK for direct installation on phone
# Creates an installable .apk file

set -e

echo "========================================"
echo "Android APK Build Script"
echo "========================================"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check Flutter
echo -e "${BLUE}Checking Flutter installation...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Flutter not found. Please install Flutter first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Flutter found${NC}"
echo ""

# Check Android setup
echo -e "${BLUE}Checking Android SDK...${NC}"
if ! flutter doctor | grep -q "Android toolchain"; then
    echo -e "${RED}Android SDK not properly configured.${NC}"
    echo "Run 'flutter doctor' to see what's missing."
    exit 1
fi
echo -e "${GREEN}✓ Android SDK configured${NC}"
echo ""

# Clean and get dependencies
echo -e "${BLUE}Installing dependencies...${NC}"
flutter pub get
echo ""

# Build APK
echo -e "${BLUE}Building Android APK...${NC}"
echo "This may take 5-10 minutes on first build..."
echo ""

flutter build apk --release

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================"
    echo -e "✓ APK Build Successful!"
    echo -e "========================================${NC}"
    echo ""
    echo "APK Location:"
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    echo -e "  ${GREEN}${APK_PATH}${NC}"
    echo ""

    # Get file size
    if [ -f "$APK_PATH" ]; then
        SIZE=$(du -h "$APK_PATH" | cut -f1)
        echo "File Size: ${SIZE}"
        echo ""
    fi

    echo -e "${YELLOW}To install on your phone:${NC}"
    echo ""
    echo "Option 1 - USB Cable:"
    echo "  1. Connect phone via USB"
    echo "  2. Enable USB debugging on phone"
    echo "  3. Run: flutter install"
    echo ""
    echo "Option 2 - Transfer File:"
    echo "  1. Copy the APK to your phone:"
    echo "     - Email it to yourself"
    echo "     - Upload to Google Drive/Dropbox"
    echo "     - Use AirDroid/Send Anywhere"
    echo "     - USB transfer to Downloads folder"
    echo "  2. On phone, tap the APK file"
    echo "  3. Allow 'Install from unknown sources' if prompted"
    echo "  4. Tap 'Install'"
    echo ""
    echo "Option 3 - QR Code:"
    echo "  1. Upload APK to a file hosting service"
    echo "  2. Generate QR code for download link"
    echo "  3. Scan with phone camera"
    echo ""
    echo -e "${YELLOW}Security Note:${NC}"
    echo "This is a debug/release APK, not from Play Store."
    echo "You may need to enable 'Install from unknown sources' in phone settings."
    echo ""
else
    echo -e "${RED}Build failed. Check errors above.${NC}"
    exit 1
fi
