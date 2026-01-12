# Troubleshooting 404 Error in Supabase Authentication

## Current Issue
Getting "Received an empty response with status code 404" when trying to sign up/login.

## Possible Causes & Solutions

### 1. Check Supabase Authentication Settings

In your Supabase Dashboard:
1. Go to **Authentication** → **Settings**
2. Under **Email Auth**, make sure:
   - **Enable Email Provider** is **ON** ✅
   - Email confirmation can be disabled for testing
3. Check **Site URL** setting:
   - Should include `http://localhost:8080` for local development
   - Or set to `*` for development (less secure but works for testing)

### 2. Check API Settings

1. Go to **Settings** → **API**
2. Verify:
   - **Project URL** is correct: `https://pzhpkoiqcutkcaudrazn.supabase.co`
   - **anon public** key is being used (starts with `eyJ`)
   - The key matches what's in `lib/main.dart`

### 3. Browser Console Check

Open browser DevTools (F12 or Cmd+Option+I):
1. Go to **Console** tab
2. Try signing up again
3. Look for any CORS errors or network errors
4. Check the **Network** tab to see what requests are failing

### 4. Common Issues

**CORS Errors:**
- Make sure Site URL includes localhost for development
- Or temporarily allow all origins in Supabase settings

**Wrong Endpoint:**
- The URL should be: `https://pzhpkoiqcutkcaudrazn.supabase.co`
- **NOT** with `/rest/v1/` for the base URL
- Supabase Flutter SDK handles the endpoint paths automatically

**Cache Issues:**
- Clear browser cache
- Try incognito/private mode
- Hot restart the Flutter app (R key in terminal)

### 5. Verify Supabase Project Status

Make sure your Supabase project is:
- ✅ Active (not paused)
- ✅ Has authentication enabled
- ✅ Has the correct project reference ID

### 6. Test Supabase Connection

You can test if Supabase is accessible:
```bash
curl -X POST "https://pzhpkoiqcutkcaudrazn.supabase.co/auth/v1/signup" \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

If this works, the issue is likely in the Flutter app configuration.
If this fails, the issue is with Supabase settings.

## Next Steps

1. Check browser console for detailed error messages
2. Verify Site URL in Supabase settings includes `localhost:8080`
3. Try disabling email confirmation temporarily
4. Check that authentication provider is enabled
