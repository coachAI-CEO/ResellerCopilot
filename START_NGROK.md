# Quick Start: ngrok for Reseller Copilot

ngrok is already installed and configured! ✅

## Start the App with ngrok (2 Terminal Windows)

### Terminal 1: Start Flutter App

```bash
cd /Users/macbook/reseller_copilot
flutter run -d chrome --web-port=8080
```

Wait until you see "Chrome (web) • chrome • web-javascript • Google Chrome"
Press 'r' to hot reload (or wait for it to finish starting)

### Terminal 2: Start ngrok Tunnel

Once the Flutter app is running, open a new terminal and run:

```bash
cd /Users/macbook/reseller_copilot
ngrok http 8080
```

### Get Your ngrok URL

In Terminal 2 (ngrok), you'll see output like:

```
Forwarding   https://abc123def456.ngrok-free.app -> http://localhost:8080
```

Copy the `https://...` URL - that's your public URL!

### Access on Your Phone

1. **Open your phone's browser** (Safari, Chrome, etc.)
2. **Go to the ngrok URL** (e.g., `https://abc123def456.ngrok-free.app`)
3. **The app will load!** 📱
4. **Add to Home Screen** for app-like experience:
   - iPhone: Share button → Add to Home Screen
   - Android: Menu → Add to Home Screen

## Quick Commands

**Terminal 1:**
```bash
flutter run -d chrome --web-port=8080
```

**Terminal 2:**
```bash
ngrok http 8080
```

**To stop:**
- Terminal 1: Press `q` to quit Flutter
- Terminal 2: Press `Ctrl+C` to stop ngrok

## Important Notes

- ✅ **HTTPS:** ngrok provides HTTPS automatically (required for camera access!)
- ✅ **Works from anywhere:** Your phone doesn't need to be on the same Wi-Fi
- ⚠️ **URL changes:** Free ngrok URLs change each time you restart ngrok
- 🔒 **Security:** Anyone with the URL can access your app (fine for development)

## Troubleshooting

**Port 8080 already in use:**
```bash
# Find what's using it
lsof -ti:8080

# Kill it if needed
kill -9 $(lsof -ti:8080)
```

**ngrok connection refused:**
- Make sure Flutter app is running first
- Wait a few seconds after starting Flutter before starting ngrok

**Camera not working:**
- Make sure you're using the HTTPS URL (ngrok provides this automatically)
- Check browser permissions on your phone
