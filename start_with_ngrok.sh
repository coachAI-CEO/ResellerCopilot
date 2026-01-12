#!/bin/bash

# Script to start Reseller Copilot with ngrok tunnel

echo "🚀 Starting Reseller Copilot with ngrok..."
echo ""

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
    echo "❌ ngrok is not installed. Installing..."
    brew install ngrok
fi

# Check if ngrok is authenticated
if ! ngrok config check &> /dev/null; then
    echo "⚠️  ngrok needs authentication (free account required)"
    echo ""
    echo "To get your auth token:"
    echo "1. Sign up at: https://dashboard.ngrok.com/signup"
    echo "2. Copy your authtoken from: https://dashboard.ngrok.com/get-started/your-authtoken"
    echo "3. Run: ngrok config add-authtoken YOUR_TOKEN"
    echo ""
    read -p "Have you already set up ngrok auth token? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Please set up ngrok authentication first, then run this script again."
        exit 1
    fi
fi

# Start Flutter app in background on port 8080
echo "📱 Starting Flutter app on port 8080..."
flutter run -d chrome --web-port=8080 --web-hostname=localhost &

# Wait a bit for Flutter to start
sleep 5

# Start ngrok tunnel
echo "🌐 Starting ngrok tunnel..."
echo ""
echo "Your app will be accessible at the ngrok URL below:"
echo "📱 Open this URL on your phone from anywhere!"
echo ""

ngrok http 8080
