#!/bin/bash
# Build and serve Flutter web app for mobile testing
# This creates a web version accessible from your phone

set -e

echo "========================================"
echo "Flutter Web - Mobile Testing Setup"
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

# Check if in project directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}Error: Not in Flutter project directory${NC}"
    exit 1
fi

# Clean and get dependencies
echo -e "${BLUE}Installing dependencies...${NC}"
flutter pub get
echo ""

# Build for web
echo -e "${BLUE}Building Flutter web app...${NC}"
echo "This may take a few minutes..."
flutter build web --release
echo -e "${GREEN}✓ Web build complete${NC}"
echo ""

# Get local IP address
echo -e "${BLUE}Detecting your local IP address...${NC}"
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    LOCAL_IP=$(ipconfig getifaddr en0 || ipconfig getifaddr en1)
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    LOCAL_IP=$(hostname -I | awk '{print $1}')
else
    # Windows (Git Bash)
    LOCAL_IP=$(ipconfig | grep -i "IPv4" | head -1 | awk '{print $NF}')
fi

if [ -z "$LOCAL_IP" ]; then
    echo -e "${YELLOW}Could not auto-detect IP. Please find your local IP manually.${NC}"
    LOCAL_IP="YOUR_IP_ADDRESS"
fi

echo -e "${GREEN}Your local IP: ${LOCAL_IP}${NC}"
echo ""

# Start HTTP server
PORT=8080
echo -e "${BLUE}Starting web server on port ${PORT}...${NC}"
echo ""
echo -e "${GREEN}========================================"
echo -e "Server is running!"
echo -e "========================================${NC}"
echo ""
echo -e "${YELLOW}To test on your phone:${NC}"
echo ""
echo "1. Make sure your phone is on the SAME WiFi network as this computer"
echo ""
echo "2. Open a browser on your phone and go to:"
echo ""
echo -e "   ${GREEN}http://${LOCAL_IP}:${PORT}${NC}"
echo ""
echo "3. Add to home screen for app-like experience:"
echo "   - Chrome (Android): Menu → Add to Home screen"
echo "   - Safari (iOS): Share → Add to Home Screen"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
echo ""
echo "========================================"
echo ""

# Serve the web build
cd build/web
python3 -m http.server $PORT 2>/dev/null || python -m SimpleHTTPServer $PORT 2>/dev/null || echo -e "${RED}Error: Python not found. Install Python or use another HTTP server.${NC}"
