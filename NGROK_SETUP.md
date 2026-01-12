# Setting Up ngrok for Reseller Copilot

ngrok allows you to access your Flutter app from your phone from anywhere, even when you're not on the same Wi-Fi network.

## Quick Setup

### Step 1: Install ngrok (if not already installed)

ngrok is already installed! ✅

To install it fresh:
```bash
brew install ngrok
```

Or download from: https://ngrok.com/download

### Step 2: Sign up for free ngrok account

1. Go to: https://dashboard.ngrok.com/signup
2. Sign up with email or GitHub
3. Free account gives you everything you need

### Step 3: Get your auth token

1. After signing up, go to: https://dashboard.ngrok.com/get-started/your-authtoken
2. Copy your authtoken (looks like: `2abc123def456ghi789jkl012mno345pqr678stu901vwx234yz_5AbC6DeF7GhI8JkL`)

### Step 4: Configure ngrok

Run this command with your authtoken:

```bash
ngrok config add-authtoken YOUR_AUTH_TOKEN_HERE
```

### Step 5: Start the app with ngrok

**Option A: Use the script (Easiest)**

```bash
./start_with_ngrok.sh
```

**Option B: Manual setup**

1. **Terminal 1: Start Flutter app**
   ```bash
   flutter run -d chrome --web-port=8080
   ```

2. **Terminal 2: Start ngrok tunnel**
   ```bash
   ngrok http 8080
   ```

3. **Get your ngrok URL**
   - ngrok will display a URL like: `https://abc123def456.ngrok-free.app`
   - Copy this URL

4. **Access on your phone**
   - Open your phone's browser
   - Go to the ngrok URL (e.g., `https://abc123def456.ngrok-free.app`)
   - The app will load!

## Important Notes

### Free ngrok URLs

- Free ngrok URLs change each time you restart ngrok
- If you want a fixed URL, you need a paid plan
- For development, free URLs work great!

### Security Warning

When you start ngrok, anyone with the URL can access your app. For development/testing, this is fine. For production:
- Use ngrok's authentication features
- Consider paid plans for more security
- Or use ngrok only for testing

### Camera Access

**Important:** Web browsers require HTTPS for camera access. ngrok provides HTTPS automatically, so camera access will work on your phone!

### Troubleshooting

**"ngrok: command not found"**
- Make sure ngrok is installed: `brew install ngrok`
- Or download from ngrok.com

**"authtoken required"**
- Sign up at https://dashboard.ngrok.com/signup
- Get your token from https://dashboard.ngrok.com/get-started/your-authtoken
- Run: `ngrok config add-authtoken YOUR_TOKEN`

**"Connection refused"**
- Make sure Flutter app is running on port 8080 first
- Check that port 8080 is not being used by another app

**App loads but camera doesn't work**
- Make sure you're using HTTPS (ngrok provides this automatically)
- Check browser permissions on your phone
- Some browsers require HTTPS for camera access

## Quick Reference

**Start app + ngrok (manual):**
```bash
# Terminal 1
flutter run -d chrome --web-port=8080

# Terminal 2
ngrok http 8080
```

**Start app + ngrok (script):**
```bash
./start_with_ngrok.sh
```

**Get ngrok URL:**
- Look at the ngrok terminal output
- You'll see: "Forwarding" → `https://abc123.ngrok-free.app`

**Access on phone:**
- Open browser on phone
- Go to the ngrok URL
- Add to home screen for app-like experience!
