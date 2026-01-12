# Accessing Reseller Copilot on Your Phone

There are several ways to run the app on your phone. Choose the easiest option for you:

## Option 1: Web Access (Easiest - Works on Any Phone) 🌐

Run the app on your computer and access it from your phone's browser on the same Wi-Fi network.

### Steps:

1. **On your Mac, run the Flutter app in web mode:**
   ```bash
   flutter run -d chrome --web-port=8080 --web-hostname=0.0.0.0
   ```
   
   The `--web-hostname=0.0.0.0` makes it accessible from your local network.

2. **Find your Mac's IP address:**
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```
   
   Or check System Preferences → Network → Wi-Fi → Advanced → TCP/IP
   
   You'll see something like: `192.168.1.100`

3. **On your phone:**
   - Make sure your phone is on the **same Wi-Fi network** as your Mac
   - Open your phone's browser (Safari, Chrome, etc.)
   - Go to: `http://YOUR_MAC_IP:8080`
   - Example: `http://192.168.1.100:8080`

4. **The app should load on your phone!**

### Pro Tip: Create a Home Screen Shortcut

**iPhone:**
- Open Safari on your iPhone
- Navigate to the app URL
- Tap the Share button
- Select "Add to Home Screen"
- The app will appear like a native app!

**Android:**
- Open Chrome on your Android
- Navigate to the app URL
- Tap the menu (three dots)
- Select "Add to Home screen" or "Install app"

---

## Option 2: Build for iOS (iPhone/iPad) 📱

### Requirements:
- Mac computer
- Xcode installed
- iOS device (iPhone/iPad)
- Apple Developer account (free account works for development)

### Steps:

1. **Open the project in Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Connect your iPhone via USB**

3. **Select your device in Xcode:**
   - At the top of Xcode, select your iPhone from the device dropdown

4. **Sign the app:**
   - Go to "Signing & Capabilities" tab
   - Select your Team (or add your Apple ID)
   - Xcode will automatically manage signing

5. **Build and run:**
   ```bash
   flutter run -d <your-device-id>
   ```
   
   Or click the Play button in Xcode

6. **Trust the developer (first time only):**
   - On your iPhone: Settings → General → VPN & Device Management
   - Tap your developer account
   - Tap "Trust"

### Alternative: Build and Install via USB

1. **Get your device ID:**
   ```bash
   flutter devices
   ```

2. **Build and install:**
   ```bash
   flutter build ios
   flutter install -d <device-id>
   ```

---

## Option 3: Build for Android 🤖

### Requirements:
- Android device with Developer Options enabled
- USB debugging enabled
- Android Studio (optional, for easier setup)

### Steps:

1. **Enable Developer Options on your Android phone:**
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
   - Developer Options will appear in Settings

2. **Enable USB Debugging:**
   - Settings → Developer Options → USB Debugging (turn on)

3. **Connect your Android phone via USB**

4. **Trust your computer:**
   - A prompt will appear on your phone
   - Tap "Allow USB debugging" and check "Always allow from this computer"

5. **Build and install:**
   ```bash
   flutter devices  # Verify your device is connected
   flutter run -d <device-id>
   ```

### Alternative: Build APK and Install

1. **Build APK:**
   ```bash
   flutter build apk
   ```

2. **Install on your phone:**
   - The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`
   - Transfer to your phone (email, AirDrop, USB, etc.)
   - On your phone: Settings → Security → Allow installation from unknown sources
   - Open the APK file and install

---

## Option 4: Use ngrok (Access from Anywhere) 🌍

If you want to access the app from your phone even when you're not on the same network:

1. **Install ngrok:**
   ```bash
   # On Mac
   brew install ngrok
   ```
   
   Or download from: https://ngrok.com/download

2. **Run your Flutter app:**
   ```bash
   flutter run -d chrome --web-port=8080
   ```

3. **Create a tunnel:**
   ```bash
   ngrok http 8080
   ```

4. **Use the ngrok URL on your phone:**
   - ngrok will give you a URL like: `https://abc123.ngrok.io`
   - Open this URL on your phone's browser from anywhere!

**Note:** Free ngrok URLs change each time. Paid plans offer fixed URLs.

---

## Recommended: Web Access (Option 1)

For the quickest setup, use **Option 1 (Web Access)**:
- ✅ Works immediately
- ✅ No code signing needed
- ✅ Works on any phone (iPhone, Android)
- ✅ Easy to update (just refresh the browser)
- ✅ Can add to home screen for app-like experience

### Quick Web Setup:

```bash
# Terminal 1: Run the app
flutter run -d chrome --web-port=8080 --web-hostname=0.0.0.0

# Terminal 2: Find your IP
ifconfig | grep "inet " | grep -v 127.0.0.1
```

Then on your phone: `http://YOUR_IP:8080`

---

## Troubleshooting

### "Can't connect" on phone
- Make sure phone and Mac are on the same Wi-Fi network
- Check Mac's firewall settings (System Preferences → Security & Privacy → Firewall)
- Try disabling firewall temporarily to test

### Camera not working on web
- Web browsers require HTTPS for camera access
- Use ngrok (Option 4) for HTTPS access
- Or build native app (Option 2 or 3)

### App looks different on phone
- This is normal for web apps on mobile
- The app will scale to fit the screen
- For best experience, use native build (iOS/Android)

### Performance issues on web
- Web version may be slower than native
- For best performance, build native app
- Close other browser tabs/apps on your phone

---

## Quick Reference

**Web Access:**
```bash
flutter run -d chrome --web-port=8080 --web-hostname=0.0.0.0
# Then visit: http://YOUR_MAC_IP:8080 on your phone
```

**iOS Build:**
```bash
flutter run -d <ios-device-id>
```

**Android Build:**
```bash
flutter run -d <android-device-id>
```

**Find Devices:**
```bash
flutter devices
```
