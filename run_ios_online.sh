#!/bin/bash
# Run Flutter app online for iOS testing
# Uses ngrok to create a secure HTTPS tunnel (required for iOS camera)

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  iOS Online Testing Setup             ║${NC}"
echo -e "${CYAN}║  Flutter App → Web → ngrok → iPhone   ║${NC}"
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo ""

# Check Flutter
echo -e "${BLUE}🔍 Checking Flutter installation...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter not found.${NC}"
    echo "Please install Flutter from: https://flutter.dev/docs/get-started/install"
    exit 1
fi
echo -e "${GREEN}✅ Flutter found${NC}"
echo ""

# Check ngrok
echo -e "${BLUE}🔍 Checking ngrok installation...${NC}"
if ! command -v ngrok &> /dev/null; then
    echo -e "${YELLOW}⚠️  ngrok not found.${NC}"
    echo ""
    echo "ngrok is needed to create a secure HTTPS tunnel for iOS."
    echo "iOS Safari requires HTTPS to access the camera."
    echo ""
    echo -e "${CYAN}To install ngrok:${NC}"
    echo ""
    echo "  macOS:"
    echo "    brew install ngrok"
    echo ""
    echo "  Linux:"
    echo "    snap install ngrok"
    echo ""
    echo "  Or download from: https://ngrok.com/download"
    echo ""
    echo "After installing, run this script again."
    exit 1
fi
echo -e "${GREEN}✅ ngrok found${NC}"
echo ""

# Check ngrok auth
echo -e "${BLUE}🔍 Checking ngrok authentication...${NC}"
if ! ngrok config check &> /dev/null; then
    echo -e "${YELLOW}⚠️  ngrok not authenticated yet.${NC}"
    echo ""
    echo "You need a free ngrok account (takes 30 seconds):"
    echo ""
    echo "1. Sign up: https://dashboard.ngrok.com/signup"
    echo "2. Get your auth token: https://dashboard.ngrok.com/get-started/your-authtoken"
    echo "3. Run: ngrok config add-authtoken YOUR_TOKEN_HERE"
    echo ""
    echo "Then run this script again."
    exit 1
fi
echo -e "${GREEN}✅ ngrok authenticated${NC}"
echo ""

# Build Flutter web
echo -e "${BLUE}📦 Building Flutter web app...${NC}"
echo "This may take 2-5 minutes on first build..."
echo ""

flutter build web --release

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Build complete!${NC}"
echo ""

# Start local server in background
echo -e "${BLUE}🌐 Starting local web server...${NC}"
cd build/web

# Kill any existing python servers on port 8080
lsof -ti:8080 | xargs kill -9 2>/dev/null || true

# Start server in background
python3 -m http.server 8080 > /dev/null 2>&1 &
SERVER_PID=$!

echo -e "${GREEN}✅ Local server started (port 8080)${NC}"
echo ""

# Give server a moment to start
sleep 2

# Start ngrok
echo -e "${BLUE}🚀 Creating secure HTTPS tunnel with ngrok...${NC}"
echo ""

# Kill any existing ngrok
pkill ngrok 2>/dev/null || true
sleep 1

# Start ngrok in background and capture output
ngrok http 8080 --log=stdout > /tmp/ngrok.log 2>&1 &
NGROK_PID=$!

# Wait for ngrok to start and get URL
echo -e "${YELLOW}⏳ Waiting for ngrok tunnel...${NC}"
sleep 3

# Get the public URL
NGROK_URL=""
for i in {1..10}; do
    NGROK_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | grep -o '"public_url":"https://[^"]*' | grep -o 'https://[^"]*' | head -1)
    if [ ! -z "$NGROK_URL" ]; then
        break
    fi
    sleep 1
done

if [ -z "$NGROK_URL" ]; then
    echo -e "${RED}❌ Failed to get ngrok URL${NC}"
    kill $SERVER_PID $NGROK_PID 2>/dev/null
    exit 1
fi

# Success! Show the URL
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ YOUR APP IS NOW ONLINE!            ║${NC}"
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo ""
echo -e "${CYAN}📱 To test on your iPhone:${NC}"
echo ""
echo -e "1. Open Safari on your iPhone"
echo ""
echo -e "2. Go to this URL:"
echo ""
echo -e "   ${GREEN}${NGROK_URL}${NC}"
echo ""
echo -e "3. Tap 'Add to Home Screen' for app-like experience:"
echo "   • Tap Share button (box with arrow)"
echo "   • Scroll down → 'Add to Home Screen'"
echo "   • Tap 'Add' → Now it's like a native app!"
echo ""
echo -e "${CYAN}📱 Want to test on other devices too?${NC}"
echo ""
echo "Anyone can access this URL:"
echo -e "  ${GREEN}${NGROK_URL}${NC}"
echo ""
echo "Works on:"
echo "  ✅ iPhone/iPad (Safari)"
echo "  ✅ Android (Chrome)"
echo "  ✅ Desktop (any browser)"
echo "  ✅ Even share with friends!"
echo ""
echo -e "${YELLOW}⚠️  Important Notes:${NC}"
echo ""
echo "• This URL works until you close this terminal"
echo "• Camera access works (HTTPS enabled)"
echo "• Free ngrok URLs change each time you restart"
echo "• Paid ngrok gives you a permanent custom URL"
echo ""
echo -e "${CYAN}📊 To monitor traffic:${NC}"
echo "Open: http://localhost:4040"
echo ""
echo -e "${CYAN}🔗 QR Code for easy access:${NC}"
echo "Scan this QR code with your iPhone camera:"
echo ""

# Generate QR code if qrencode is available
if command -v qrencode &> /dev/null; then
    qrencode -t ANSIUTF8 "$NGROK_URL"
else
    echo "Install qrencode to see QR code: brew install qrencode"
    echo "Or manually visit: https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${NGROK_URL}"
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 Shutting down servers...${NC}"
    kill $SERVER_PID 2>/dev/null || true
    kill $NGROK_PID 2>/dev/null || true
    pkill ngrok 2>/dev/null || true
    echo -e "${GREEN}✅ Cleanup complete${NC}"
    echo ""
    echo "Thanks for testing! 🚀"
    echo ""
    exit 0
}

# Set up cleanup on script exit
trap cleanup EXIT INT TERM

# Keep script running
echo -e "${CYAN}📱 Test the app on your iPhone now!${NC}"
echo ""
echo "Quick Test Checklist:"
echo "  1. ☐ Log in to the app"
echo "  2. ☐ Take a photo with camera"
echo "  3. ☐ Scan a product"
echo "  4. ☐ Tap History icon (📊)"
echo "  5. ☐ Tap Settings icon (⚙️)"
echo "  6. ☐ Try offline mode (airplane mode)"
echo ""

# Wait indefinitely
tail -f /tmp/ngrok.log 2>/dev/null || sleep infinity
