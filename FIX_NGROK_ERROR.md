# Fix ngrok Error: Connection Refused

## Error: ERR_NGROK_8012

**Problem:** ngrok is running but can't connect to your Flutter app on port 8080.

**Error Message:** `dial tcp [::1]:8080: connect: connection refused`

## Solution

The Flutter app needs to be running **before** you start ngrok.

### Step 1: Start Flutter App First

Open a terminal and run:

```bash
cd /Users/macbook/reseller_copilot
flutter run -d chrome --web-port=8080
```

**Wait for the app to fully start** - you should see:
- Chrome browser opens with your app
- Terminal shows "Chrome (web) • chrome • web-javascript • Google Chrome"
- The app is visible in the browser

### Step 2: Verify App is Running

In a new terminal, test if the app is accessible:

```bash
curl http://localhost:8080
```

You should see HTML output (not an error).

### Step 3: Start ngrok (After Flutter is Running)

Once Flutter is running and accessible on localhost:8080, **then** start ngrok:

```bash
ngrok http 8080
```

### Step 4: Use the ngrok URL

Copy the HTTPS URL from ngrok (e.g., `https://abc123.ngrok-free.app`) and use it on your phone.

## Quick Fix Right Now

1. **Stop ngrok** (if running): Press `Ctrl+C` in the ngrok terminal

2. **Start Flutter app:**
   ```bash
   cd /Users/macbook/reseller_copilot
   flutter run -d chrome --web-port=8080
   ```

3. **Wait for Flutter to start** (browser should open)

4. **In a NEW terminal, start ngrok:**
   ```bash
   ngrok http 8080
   ```

5. **Copy the ngrok HTTPS URL** and use it on your phone

## Common Issues

### Port 8080 Already in Use

If you get an error that port 8080 is in use:

```bash
# Find what's using it
lsof -ti:8080

# Kill it if needed
kill -9 $(lsof -ti:8080)

# Then start Flutter again
flutter run -d chrome --web-port=8080
```

### Flutter App Not Starting

If Flutter won't start:

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run -d chrome --web-port=8080
```

### ngrok Still Can't Connect

1. Make sure Flutter is running first
2. Test with: `curl http://localhost:8080`
3. If curl works, then start ngrok
4. If curl fails, Flutter isn't running properly

## Correct Order of Operations

1. ✅ **First:** Start Flutter app (`flutter run -d chrome --web-port=8080`)
2. ✅ **Wait:** Until browser opens and app loads
3. ✅ **Then:** Start ngrok (`ngrok http 8080`)
4. ✅ **Finally:** Use ngrok URL on your phone

## Quick Reference

**Terminal 1 (Flutter):**
```bash
flutter run -d chrome --web-port=8080
```

**Terminal 2 (ngrok - start AFTER Flutter is running):**
```bash
ngrok http 8080
```

**Test if Flutter is running:**
```bash
curl http://localhost:8080
```
