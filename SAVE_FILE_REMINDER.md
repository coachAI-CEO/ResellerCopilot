# ⚠️ IMPORTANT: Save Your File!

## Issue Found
The `lib/main.dart` file has **unsaved changes**!

- ✅ **In your editor**: The correct anon key (starts with `eyJ`)
- ❌ **On disk**: The old incorrect key (starts with `sb_secret_`)

## Solution

1. **Save the file**: Press `Cmd+S` (Mac) or `Ctrl+S` (Windows/Linux)
2. **Hot restart the app**: 
   - Press `R` in the terminal where Flutter is running
   - OR stop and restart: `flutter run -d chrome --web-port=8080`

## Why This Matters

The Flutter app reads from the **saved file on disk**, not from your editor's unsaved changes. Until you save, the app will continue using the old incorrect key, which causes the 404 error.

## Verify After Saving

After saving, verify the file has the correct key:
```bash
grep "anonKey" lib/main.dart
```

You should see the key starts with `eyJ`, not `sb_secret_`.
