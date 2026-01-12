# Debugging 500 Internal Server Error

## What I Fixed

I've updated the edge function with:
- ✅ Better error handling for request body parsing
- ✅ Improved error messages with more details
- ✅ Additional logging to help identify the issue
- ✅ Better handling of missing environment variables

## Next Steps to Find the Root Cause

### 1. Check Edge Function Logs

The updated function now logs more information. To see what's actually failing:

1. Go to your Supabase Dashboard: https://supabase.com/dashboard/project/pzhpkoiqcutkcaudrazn/functions
2. Click on **analyze-product** function
3. Go to the **Logs** tab
4. Try your request again from the app
5. Look at the latest log entries - you should see:
   - "Request received" with method and URL
   - "Supabase URL: Set" or "Missing"
   - "Supabase Anon Key: Set" or "Missing"
   - Any error messages with details

### 2. Verify Environment Variables

Make sure all required environment variables are set:

1. Go to **Edge Functions** → **analyze-product** → **Settings**
2. Check these environment variables are set:
   - `SUPABASE_URL`: Should be `https://pzhpkoiqcutkcaudrazn.supabase.co`
   - `SUPABASE_ANON_KEY`: Your anon/public key (starts with `eyJ`)
   - `SUPABASE_SERVICE_ROLE_KEY`: Your service role key (optional but recommended)
   - `GEMINI_API_KEY`: Your Gemini API key (required)

**Note:** Supabase automatically provides `SUPABASE_URL` and `SUPABASE_ANON_KEY`, but you should verify they're set correctly.

### 3. Check the Request Payload

The error might be in the request body. Check the browser's Network tab:

1. Open DevTools (F12 or Cmd+Option+I)
2. Go to **Network** tab
3. Click on the failed `analyze-product` request
4. Go to **Payload** tab
5. Verify the request body has:
   - `image_base64`: Base64 encoded image string
   - `store_price`: A valid number > 0
   - `barcode`: (optional) String

### 4. Common Causes of 500 Errors

**Missing GEMINI_API_KEY:**
- Error message: "Gemini API key not configured"
- Fix: Set `GEMINI_API_KEY` in edge function settings

**Invalid Request Body:**
- Error message: "Invalid request body"
- Fix: Check that the Flutter app is sending the correct payload format

**Supabase Configuration Missing:**
- Error message: "Server configuration error: Missing Supabase credentials"
- Fix: Verify `SUPABASE_URL` and `SUPABASE_ANON_KEY` are set in edge function settings

**Authentication Error:**
- Error message: "Unauthorized" or "Authentication failed"
- Fix: Make sure "Verify JWT with legacy secret" is **OFF** in function settings

**Gemini API Error:**
- Error message: "Failed to analyze product with AI"
- Fix: Check your Gemini API key is valid and has quota

### 5. Test the Function Directly

You can test the function directly from the Supabase dashboard:

1. Go to **Edge Functions** → **analyze-product**
2. Scroll to **Invoke function** section
3. Use the **Flutter** tab to see the example code
4. Or use **cURL** to test manually

Example test payload:
```json
{
  "image_base64": "base64_encoded_image_here",
  "store_price": 10.99,
  "barcode": "123456789"
}
```

### 6. Check Browser Console

Look at the browser console for any additional error messages:
1. Open DevTools (F12)
2. Go to **Console** tab
3. Look for any red error messages
4. Check if there are any CORS errors or network errors

## What to Share for Further Debugging

If the error persists, please share:
1. The **exact error message** from the edge function logs
2. The **request payload** from the Network tab
3. A screenshot of the **edge function logs** showing the error
4. Confirmation that all **environment variables** are set

The improved error handling should now give you a more specific error message that will help identify the exact issue.
