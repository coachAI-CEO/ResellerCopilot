#!/bin/bash
# Phase 3 Testing Setup Script
# Run this script to prepare and test Phase 3 features

set -e  # Exit on error

echo "================================"
echo "Phase 3 Testing Setup"
echo "================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Check Flutter installation
echo -e "${BLUE}Step 1: Checking Flutter installation...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Flutter is not installed or not in PATH${NC}"
    echo "Please install Flutter from https://flutter.dev/docs/get-started/install"
    exit 1
fi
echo -e "${GREEN}✓ Flutter found: $(flutter --version | head -1)${NC}"
echo ""

# Step 2: Check current directory
echo -e "${BLUE}Step 2: Verifying project directory...${NC}"
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}Error: pubspec.yaml not found. Are you in the project root?${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Project directory confirmed${NC}"
echo ""

# Step 3: Clean previous build
echo -e "${BLUE}Step 3: Cleaning previous build...${NC}"
flutter clean
echo -e "${GREEN}✓ Clean complete${NC}"
echo ""

# Step 4: Get dependencies
echo -e "${BLUE}Step 4: Installing dependencies...${NC}"
flutter pub get
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to install dependencies${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Step 5: Check for syntax errors
echo -e "${BLUE}Step 5: Analyzing code for errors...${NC}"
flutter analyze
if [ $? -ne 0 ]; then
    echo -e "${RED}Code analysis found issues. Please fix them before testing.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ No analysis errors found${NC}"
echo ""

# Step 6: Run tests (if any)
echo -e "${BLUE}Step 6: Running unit tests...${NC}"
flutter test --no-sound-null-safety
if [ $? -ne 0 ]; then
    echo -e "${RED}Some tests failed. Check output above.${NC}"
    # Don't exit - tests might fail but app might still run
fi
echo ""

# Step 7: List available devices
echo -e "${BLUE}Step 7: Available devices:${NC}"
flutter devices
echo ""

# Step 8: Provide testing instructions
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "Next steps:"
echo ""
echo "1. Choose a device from the list above"
echo ""
echo "2. Run the app:"
echo "   ${BLUE}flutter run${NC}                    # Run on first available device"
echo "   ${BLUE}flutter run -d chrome${NC}          # Run on Chrome (web)"
echo "   ${BLUE}flutter run -d <device-id>${NC}    # Run on specific device"
echo ""
echo "3. Follow the testing guide:"
echo "   ${BLUE}cat docs/PHASE_3_TESTING_GUIDE.md${NC}"
echo ""
echo "4. Quick reference:"
echo "   ${BLUE}cat docs/PHASE_3_QUICK_REFERENCE.md${NC}"
echo ""
echo -e "${GREEN}New Features:${NC}"
echo "  📊 History Screen    - View all past scans"
echo "  ⚙️  Settings Screen   - Manage cache and queue"
echo "  🔄 Offline Support   - Scans work without internet"
echo "  ⚡ Smart Caching     - Faster repeat scans"
echo "  📥 Export to CSV     - Download scan history"
echo ""
echo "Happy testing! 🚀"
