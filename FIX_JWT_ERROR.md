# Fix JWT Error

## Changes Made

### 1. Edge Function (`supabase/functions/analyze-product/index.ts`)
- ✅ Improved JWT token verification
- ✅ Added Bearer prefix handling for Authorization header
- ✅ Better error messages for authentication failures
- ✅ Fallback to anon key if service role key is not available
- ✅ More robust error handling

### 2. Flutter Service (`lib/services/supabase_service.dart`)
- ✅ Improved session refresh error handling
- ✅ Better validation of access tokens
- ✅ More informative error messages

## Next Steps

### 1. Deploy the Updated Edge Function

You need to redeploy the edge function for the changes to take effect:

```bash
# IMPORTANT: Make sure you're in the project root (not in lib/ or any subdirectory)
cd /Users/macbook/reseller_copilot

# Deploy the edge function
supabase functions deploy analyze-product
```

**Note:** If you see a "Docker is not running" warning, you can ignore it for remote deployments. Docker is only needed for local development/testing.

### 2. Set Environment Variables (IMPORTANT)

Make sure your edge function has the correct environment variables set in Supabase:

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project
3. Go to **Edge Functions** → **analyze-product** → **Settings**
4. Set these environment variables:
   - `SUPABASE_URL`: `https://pzhpkoiqcutkcaudrazn.supabase.co`
   - `SUPABASE_ANON_KEY`: Your anon/public key (starts with `eyJ`)
   - `SUPABASE_SERVICE_ROLE_KEY`: Your service role key (optional but recommended)
   - `GEMINI_API_KEY`: Your Gemini API key

**Note:** The `SUPABASE_SERVICE_ROLE_KEY` is recommended because it allows the edge function to verify user JWT tokens more reliably. You can find it in **Settings** → **API** → **service_role** key.

### 3. Test the Fix

After deploying:

1. **Restart your Flutter app:**
   ```bash
   flutter run -d chrome --web-port=8080
   ```

2. **Log in** to your app

3. **Try analyzing a product** - the JWT error should be resolved

## Troubleshooting

### If you still get JWT errors:

1. **Check Edge Function Logs:**
   - Go to Supabase Dashboard → **Edge Functions** → **analyze-product** → **Logs**
   - Look for authentication errors

2. **Verify Session is Valid:**
   - Make sure you're logged in
   - Try logging out and logging back in
   - Check if the session token is expired

3. **Check Environment Variables:**
   - Ensure all environment variables are set correctly
   - The `SUPABASE_SERVICE_ROLE_KEY` is especially important for JWT verification

4. **Clear Browser Cache:**
   - Sometimes cached tokens can cause issues
   - Try clearing browser cache or using incognito mode

### Common JWT Error Messages:

- **"Invalid or expired JWT token"**: Your session expired, log in again
- **"Missing authorization header"**: The Flutter SDK isn't sending the token (shouldn't happen with the SDK)
- **"Authentication failed"**: The edge function can't verify your token - check environment variables

## How It Works Now

1. Flutter app calls `supabase.functions.invoke('analyze-product')`
2. Supabase Flutter SDK automatically includes `Authorization: Bearer <jwt_token>` header
3. Edge function receives the header and verifies the JWT token
4. If verification succeeds, the function processes the request
5. If verification fails, a clear error message is returned

The edge function now:
- Handles both Bearer-prefixed and non-prefixed tokens
- Uses service role key if available (more reliable)
- Falls back to anon key if service role key is not set
- Provides clear error messages for debugging
