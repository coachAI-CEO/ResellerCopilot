# 📱 Test on Your Phone - Quick Start

## Choose Your Method (Pick One):

### 🌐 Method 1: Web App (Easiest - 5 minutes)
**Works on: Android, iOS, any phone**

```bash
./run_web_mobile.sh
```

Then open the URL shown on your phone's browser.
- Make sure phone and computer are on the **same WiFi**
- URL looks like: `http://192.168.1.100:8080`

**Tip:** Add to home screen for app-like experience!

---

### 🔌 Method 2: USB Debugging (Best for Android)
**Works on: Android only**

1. Enable USB debugging on phone (Settings → Developer options)
2. Connect phone via USB cable
3. Run:
```bash
flutter run
```

App installs and runs instantly!

---

### 📦 Method 3: Install APK (Permanent Install)
**Works on: Android only**

```bash
./build_apk.sh
```

Then transfer the APK file to your phone:
- Location: `build/app/outputs/flutter-apk/app-release.apk`
- Send via email, USB, or cloud storage
- Tap to install on phone

---

### 🌍 Method 4: Remote Access (Advanced)
**Works on: Any phone, anywhere**

Requires ngrok (free). See `MOBILE_TESTING_GUIDE.md` for details.

---

## ⚡ Quick Test (2 minutes)

Once app is running on your phone:

1. ✅ Log in with your test account
2. ✅ Tap camera button → Take photo
3. ✅ Enter price → Scan product
4. ✅ Tap **History** icon (📊) → See your scan
5. ✅ Tap **Settings** icon (⚙️) → View statistics
6. ✅ Turn on airplane mode → Scan → See "queued" message
7. ✅ Turn off airplane mode → Scan saves automatically

---

## 📚 Full Documentation

- **MOBILE_TESTING_GUIDE.md** - Complete guide with all methods
- **PHASE_3_TESTING_GUIDE.md** - 60+ test scenarios
- **PHASE_3_QUICK_REFERENCE.md** - Visual guides and tips

---

## 🆘 Need Help?

### Web app won't load?
- Check phone and computer on same WiFi
- Try `http://IP:8080` (not https)
- Disable firewall/VPN

### Can't connect via USB?
- Enable USB debugging: Settings → Developer options
- Trust computer when prompted
- Try: `flutter devices` to check connection

### APK won't install?
- Enable "Install from unknown sources" in Settings
- Make sure you have Android 5.0+
- Try: `flutter clean && flutter build apk`

---

## 🎯 Recommended Method by Use Case

| Your Situation | Best Method |
|----------------|-------------|
| Quick test, have WiFi | Method 1 (Web) |
| Android phone + USB cable | Method 2 (USB) |
| Want to keep app installed | Method 3 (APK) |
| Testing on iPhone | Method 1 (Web) |
| Share with others | Method 4 (ngrok) |

---

**Just run one of the scripts above and you'll be testing on your phone in minutes!** 🚀

Need detailed instructions? See `MOBILE_TESTING_GUIDE.md`
