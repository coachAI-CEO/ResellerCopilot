# Fix 401 Unauthorized Error

## Problem
Getting 401 errors when calling the `analyze-product` edge function. This means authentication is failing.

## Quick Fix

### Step 1: Log Out and Log Back In

The most common cause is an expired session token. Try:

1. **Log out** of the app
2. **Log back in** with your credentials
3. **Try scanning again**

This will refresh your JWT token.

### Step 2: Check Edge Function Environment Variables

Make sure your edge function has the correct secrets set:

1. Go to Supabase Dashboard: https://supabase.com/dashboard
2. Navigate to **Edge Functions** → **analyze-product** → **Settings** → **Secrets**
3. Ensure these are set:
   - `SUPABASE_URL`: `https://pzhpkoiqcutkcaudrazn.supabase.co`
   - `SUPABASE_ANON_KEY`: Your anon key (starts with `eyJ`)
   - `SUPABASE_SERVICE_ROLE_KEY`: **Important!** Your service role key (found in Settings → API)
   - `GEMINI_API_KEY`: Your Gemini API key

**Why Service Role Key?**
- The service role key allows the edge function to verify user JWT tokens more reliably
- Without it, authentication can fail intermittently

### Step 3: Check Edge Function Logs

1. Go to Supabase Dashboard
2. Navigate to **Edge Functions** → **analyze-product** → **Logs**
3. Look for authentication errors
4. Check what error message is logged when the 401 occurs

Common log messages:
- "Authentication failed: No user found" → Token verification issue
- "getUser() error: ..." → Check if service role key is set
- "Missing authorization header" → Flutter SDK issue (rare)

### Step 4: Verify Session in Browser

1. Open browser DevTools (F12)
2. Go to **Application** tab → **Local Storage**
3. Look for Supabase auth keys
4. Check if the session token exists and is recent

### Step 5: Clear Cache and Restart

If the issue persists:

1. **Clear browser cache** or use incognito mode
2. **Hot restart** the Flutter app (press `R` in terminal or restart)
3. **Log out and log back in**

## Why This Happens

401 errors occur when:
- Your JWT session token expired (tokens expire after a period of inactivity)
- The edge function can't verify your token (missing service role key)
- There's a mismatch between the JWT secret used by Supabase and the edge function

## Prevention

The edge function tries to automatically refresh your session, but sometimes manual refresh is needed. The best practice is:
- Log out and log back in if you get 401 errors
- Make sure `SUPABASE_SERVICE_ROLE_KEY` is set in edge function secrets

## Still Having Issues?

If none of the above works:
1. Check the edge function logs for specific error messages
2. Verify all environment variables/secrets are set correctly
3. Try creating a new session (log out, clear cache, log back in)
