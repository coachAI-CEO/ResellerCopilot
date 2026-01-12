# Critical Setup Steps

Before running the app, you must complete these steps:

## 1. Generate Freezed Code (REQUIRED)

The `ScanResult` model uses Freezed for code generation. You **must** run this command before the app will compile:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate the missing `*.freezed.dart` and `*.g.dart` files in the `lib/models/` directory.

## 2. Configure Supabase Credentials (REQUIRED)

Update `lib/main.dart` with your actual Supabase credentials:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',  // Replace with your actual Supabase URL
  anonKey: 'YOUR_SUPABASE_ANON_KEY',  // Replace with your actual anon key
);
```

You can find these values in your Supabase project dashboard under Settings → API.

## 3. Set Up Supabase Database

Make sure you've created the `scans` table and set up RLS policies as described in the README.md file.

## 4. Deploy Edge Function

Deploy the `analyze-product` edge function and set the `GEMINI_API_KEY` secret as described in the README.md file.

## After Setup

Once these steps are complete, you can run the app:

```bash
flutter run
```

The app will now:
1. Show an authentication screen if the user is not logged in
2. Show the scanner screen if the user is authenticated
3. Allow users to sign up, log in, and log out
