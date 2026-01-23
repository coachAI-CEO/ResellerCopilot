# Mobile Testing Guide 📱

Complete guide for testing the Reseller Copilot app on your mobile phone.

---

## 🎯 Quick Start - Choose Your Method

| Method | Best For | Time | Difficulty |
|--------|----------|------|------------|
| **1. Web (WiFi)** | Quick testing, any phone | 5 min | ⭐ Easy |
| **2. USB Debugging** | Android, best performance | 2 min | ⭐⭐ Medium |
| **3. APK Install** | Android, permanent install | 10 min | ⭐⭐ Medium |
| **4. ngrok Tunnel** | Remote testing, iOS web | 10 min | ⭐⭐⭐ Advanced |

---

## Method 1: Web App via WiFi (Easiest) 🌐

**Requirements:**
- Phone and computer on same WiFi network
- Any smartphone (Android/iOS)
- Modern browser (Chrome/Safari)

**Steps:**

### 1. Run the automated script:
```bash
chmod +x run_web_mobile.sh
./run_web_mobile.sh
```

### 2. The script will:
- Build the web version
- Start a local server
- Show you the URL (e.g., `http://192.168.1.100:8080`)

### 3. On your phone:
- Open browser
- Type in the URL shown
- App loads instantly!

### 4. Make it feel like a native app:
- **Android Chrome**: Menu → "Add to Home screen"
- **iOS Safari**: Share button → "Add to Home Screen"

**Manual Method** (if script fails):
```bash
# 1. Build web
flutter build web --release

# 2. Serve it
cd build/web
python3 -m http.server 8080

# 3. Find your IP
# macOS: ipconfig getifaddr en0
# Linux: hostname -I
# Windows: ipconfig

# 4. Open on phone: http://YOUR_IP:8080
```

---

## Method 2: USB Debugging (Best for Android) 🔌

**Requirements:**
- Android phone
- USB cable
- USB debugging enabled

**Steps:**

### 1. Enable USB Debugging on phone:
- Go to **Settings** → **About phone**
- Tap **Build number** 7 times (unlocks Developer options)
- Go back to **Settings** → **Developer options**
- Enable **USB debugging**

### 2. Connect phone via USB

### 3. Run app:
```bash
# Check device is connected
flutter devices

# You should see your phone listed
# Example: "SM G950F (mobile) • ABC123 • android-arm64 • Android 12"

# Run the app
flutter run
```

### 4. App installs and runs automatically!

**Advantages:**
- ✅ Full performance (native Android)
- ✅ Hot reload works
- ✅ Easy debugging
- ✅ Camera access
- ✅ All sensors work

---

## Method 3: Build & Install APK 📦

**Requirements:**
- Android phone only
- Android SDK installed

**Steps:**

### Option A: Automated Script
```bash
chmod +x build_apk.sh
./build_apk.sh
```

### Option B: Manual Build
```bash
# Build the APK
flutter build apk --release

# APK location:
# build/app/outputs/flutter-apk/app-release.apk
```

### Transfer APK to Phone:

**Method 3A - Email:**
1. Email the APK to yourself
2. Open email on phone
3. Download and tap to install

**Method 3B - USB Transfer:**
1. Connect phone via USB
2. Copy APK to Downloads folder
3. Open Files app → Downloads
4. Tap APK to install

**Method 3C - Cloud Storage:**
1. Upload to Google Drive/Dropbox
2. Open on phone
3. Download and install

**Method 3D - Direct Install (if USB connected):**
```bash
flutter install
```

### Install on Phone:
1. Tap the APK file
2. If prompted, allow "Install from unknown sources"
3. Tap **Install**
4. Tap **Open** to launch

**Advantages:**
- ✅ Permanent installation
- ✅ Works offline
- ✅ Full native performance
- ✅ No need for computer after install

---

## Method 4: ngrok Tunnel (Remote/iOS Web) 🌍

**Requirements:**
- ngrok account (free)
- Works for remote testing
- Great for iOS web testing

**Steps:**

### 1. Install ngrok:
```bash
# macOS
brew install ngrok

# Linux
snap install ngrok

# Or download from: https://ngrok.com/download
```

### 2. Sign up and authenticate:
```bash
# Get auth token from: https://dashboard.ngrok.com/get-started/your-authtoken
ngrok authtoken YOUR_AUTH_TOKEN
```

### 3. Build and serve:
```bash
# Build web
flutter build web --release

# Serve locally
cd build/web
python3 -m http.server 8080
```

### 4. In another terminal, create tunnel:
```bash
ngrok http 8080
```

### 5. ngrok will show a URL like:
```
Forwarding: https://abc123.ngrok.io -> http://localhost:8080
```

### 6. Open that URL on ANY phone, anywhere!
- Works over cellular data
- Works on iOS
- Can share with others
- HTTPS enabled

**Advantages:**
- ✅ Works remotely (not just local WiFi)
- ✅ HTTPS for secure features
- ✅ Share with testers anywhere
- ✅ Works on iOS without app store

---

## Feature Testing on Mobile 📋

### What Works on Web vs Native:

| Feature | Web | Android Native | iOS (Web) |
|---------|-----|----------------|-----------|
| Camera | ✅ | ✅ | ✅ |
| Photo upload | ✅ | ✅ | ✅ |
| Barcode scanning | ⚠️ Manual | ✅ | ⚠️ Manual |
| Offline support | ✅ | ✅ | ✅ |
| Push notifications | ❌ | ✅ | ❌ |
| App installation | ❌ | ✅ | ❌ |

### Camera Access on Web:
- **Android Chrome**: Works perfectly
- **iOS Safari**: Requires HTTPS (use ngrok)
- **Desktop**: May not work on some browsers

---

## Testing Checklist for Mobile 📝

### Basic Functionality
- [ ] App loads and shows login screen
- [ ] Can log in with credentials
- [ ] Camera button works
- [ ] Can take/upload photos
- [ ] Analysis completes successfully
- [ ] Results display correctly

### Phase 3 Features
- [ ] **History icon** visible and clickable
- [ ] History screen loads scans
- [ ] Can filter by Buy/Pass
- [ ] Can search products
- [ ] Can sort by date/profit/name
- [ ] Swipe to delete works
- [ ] **Settings icon** visible and clickable
- [ ] Cache statistics show correctly
- [ ] Offline queue works

### Mobile-Specific
- [ ] Touch targets are big enough
- [ ] Scrolling is smooth
- [ ] Keyboard doesn't hide inputs
- [ ] Can switch between apps
- [ ] Works in portrait mode
- [ ] Works in landscape mode
- [ ] No UI overflow/cutoff

### Offline Testing
- [ ] Turn on airplane mode
- [ ] Scan a product
- [ ] See "queued" message
- [ ] Turn off airplane mode
- [ ] Scan saves automatically
- [ ] Check Settings → Offline Queue

### Performance
- [ ] App loads in < 5 seconds
- [ ] Scans complete in < 10 seconds
- [ ] UI responds instantly to taps
- [ ] Scrolling is 60fps smooth
- [ ] No freezing or crashes

---

## Troubleshooting 🔧

### Web App Issues

**Problem: Can't access from phone**
```
✓ Check phone and computer on same WiFi
✓ Check firewall isn't blocking port 8080
✓ Try: http://IP:8080 (not https://)
✓ Disable VPN on computer or phone
```

**Problem: Camera doesn't work**
```
✓ Web requires HTTPS for camera (use ngrok)
✓ Grant camera permissions in browser
✓ Try different browser
✓ Use photo upload instead
```

**Problem: Slow performance**
```
✓ Web is slower than native - expected
✓ Use --release build, not debug
✓ Close other apps
✓ Try native APK instead
```

### USB Debugging Issues

**Problem: Device not detected**
```
✓ Enable USB debugging on phone
✓ Try different USB cable
✓ Try different USB port
✓ Install phone drivers (Windows)
✓ Trust computer on phone when prompted
```

**Problem: flutter run fails**
```
✓ Run: flutter doctor
✓ Fix any issues shown
✓ Try: flutter clean && flutter pub get
✓ Restart adb: adb kill-server && adb start-server
```

### APK Install Issues

**Problem: Can't install APK**
```
✓ Enable "Install from unknown sources"
  Settings → Security → Unknown sources
✓ Or per-app in Android 8+:
  Settings → Apps → Special access → Install unknown apps
✓ File may be corrupted - rebuild
✓ Storage space full - free up space
```

**Problem: App crashes on launch**
```
✓ Check Android version (needs Android 5.0+)
✓ Rebuild with: flutter clean && flutter build apk
✓ Check logs: adb logcat
✓ Ensure .env file configured correctly
```

### Network Issues

**Problem: "Network error" or offline**
```
✓ Check internet connection
✓ Check Supabase credentials in .env
✓ Test offline mode explicitly
✓ Check Settings → Offline Queue
```

---

## Performance Optimization 🚀

### For Best Performance:

1. **Build in Release Mode:**
```bash
flutter build apk --release       # Android
flutter build web --release       # Web
```

2. **Clear Cache:**
```bash
flutter clean
flutter pub get
```

3. **Optimize Images:**
- App already uses image compression
- Configured in `lib/constants/app_constants.dart`

4. **Enable Caching:**
- Scan products with barcodes
- Second scan is 80% faster!

---

## Comparing Methods Side-by-Side

### Speed to Test:
1. 🥇 USB Debugging (2 min)
2. 🥈 Web WiFi (5 min)
3. 🥉 APK Install (10 min)
4. ngrok (10 min)

### Best Performance:
1. 🥇 USB/APK Native (100%)
2. 🥈 Web on WiFi (70%)
3. 🥉 Web via ngrok (50%)

### Best for Sharing:
1. 🥇 ngrok URL (anyone, anywhere)
2. 🥈 APK file (Android only)
3. 🥉 WiFi (same network only)

### Best for iOS:
1. 🥇 Web via ngrok (HTTPS)
2. 🥈 Web on WiFi (HTTP, limited)
3. ❌ APK (Android only)

---

## Quick Commands Reference

```bash
# Web - Local WiFi
./run_web_mobile.sh

# USB Debugging
flutter run

# Build APK
./build_apk.sh

# Manual web build
flutter build web --release
cd build/web && python3 -m http.server 8080

# Manual APK build
flutter build apk --release

# Install via USB
flutter install

# Check connected devices
flutter devices

# Check setup
flutter doctor

# Clean build
flutter clean && flutter pub get

# ngrok tunnel
ngrok http 8080
```

---

## Getting Your Phone's IP (if needed)

### Android:
- Settings → About phone → Status → IP address
- Or: Settings → WiFi → Tap network → IP address

### iOS:
- Settings → WiFi → Tap (i) icon → IP Address

---

## Security Notes 🔒

### Web Testing:
- ✅ Safe on local network
- ⚠️ Don't expose to internet without HTTPS
- ✅ ngrok provides HTTPS automatically

### APK Installation:
- ✅ Your own build is safe
- ⚠️ "Unknown sources" warning is normal
- ✅ Can verify with Play Protect

### Credentials:
- ⚠️ Never commit .env file to git
- ✅ Use environment variables
- ✅ Don't share Supabase keys publicly

---

## Need Help?

### Common Questions:

**Q: Which method should I use?**
A: For quick testing → Web WiFi. For best experience → USB/APK.

**Q: Does it work on iPhone?**
A: Yes, via web (use ngrok for HTTPS). Native iOS requires macOS + Xcode.

**Q: Can I share with others?**
A: Yes, use ngrok URL or send APK file.

**Q: Will this affect my data plan?**
A: Web uses WiFi. APK installs once, then works offline.

**Q: How do I update the app?**
A: Rebuild and reinstall. Or use hot reload with USB.

---

## Next Steps After Setup

Once you've got the app running on your phone:

1. **Follow the testing guide:**
   - See `PHASE_3_TESTING_GUIDE.md`
   - Complete the 60+ test scenarios

2. **Try these Phase 3 features:**
   - 📊 History screen with filters
   - 📶 Offline mode (airplane mode)
   - ⚡ Cache (scan same barcode twice)
   - ⚙️ Settings screen

3. **Report issues:**
   - Note what you were doing
   - Include screenshots
   - Check console logs

---

**Happy Mobile Testing! 📱✨**

Choose your method above and get started in minutes!
