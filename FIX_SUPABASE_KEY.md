# Fix Supabase Anon Key Issue

## Problem
You're getting a **404 error** when trying to sign up/login. This is because the `anonKey` in `lib/main.dart` is incorrect.

## Current Issue
The key you're using starts with `sb_secret_`, which is **not** the correct format for Supabase anon keys.

## Solution

### 1. Get the Correct Anon Key

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project
3. Go to **Settings** → **API**
4. Under **Project API keys**, find the **`anon` `public`** key
5. This key should:
   - Start with `eyJ` (it's a JWT token)
   - Be labeled as "anon public" or "public"
   - **NOT** be the "service_role" key (that's secret)
   - **NOT** be the "secret" key

### 2. Update main.dart

Replace the `anonKey` value in `lib/main.dart`:

```dart
await Supabase.initialize(
  url: 'https://pzhpkoiqcutkcaudrazn.supabase.co',
  anonKey: 'eyJ...', // Replace with your actual anon/public key from Supabase dashboard
);
```

### 3. Restart the App

After updating the key:
1. Stop the current Flutter app (Ctrl+C in terminal)
2. Hot restart or run: `flutter run -d chrome --web-port=8080`

## Key Types in Supabase

- **anon/public key**: ✅ Use this one (starts with `eyJ`, labeled as "anon public")
- **service_role key**: ❌ Don't use (secret key, has full access)
- **secret key**: ❌ Don't use (this is what you currently have)

The anon/public key is safe to use in client-side applications because it's limited by Row Level Security (RLS) policies.
