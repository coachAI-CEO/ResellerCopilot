# Setup Gemini API Key for Edge Function

## Problem
The edge function is returning: `{"error":"Gemini API key not configured"}`

This means the `GEMINI_API_KEY` environment variable is not set in your Supabase edge function.

## Solution

### Step 1: Get Your Gemini API Key

1. Go to Google AI Studio: https://aistudio.google.com/app/apikey
2. Sign in with your Google account
3. Click **"Create API Key"** or **"Get API Key"**
4. Copy the API key (it will look something like: `AIzaSy...`)

**Note:** If you don't have a Google account or haven't used Gemini before, you may need to:
- Sign up for Google AI Studio
- Accept the terms of service
- Create a new API key

### Step 2: Set the Environment Variable in Supabase

1. Go to your Supabase Dashboard: https://supabase.com/dashboard/project/pzhpkoiqcutkcaudrazn/functions
2. Click on the **analyze-product** function
3. Go to the **Settings** tab (or look for "Function Configuration")
4. Scroll down to **Environment Variables** or **Secrets** section
5. Click **"Add Secret"** or **"Add Environment Variable"**
6. Enter:
   - **Name:** `GEMINI_API_KEY`
   - **Value:** Your Gemini API key (paste the key you copied)
7. Click **"Save"** or **"Add"**

### Step 3: Verify the Setup

After setting the environment variable:

1. The edge function should automatically pick up the new environment variable
2. Try your request again from the Flutter app
3. The error should be resolved

**Note:** If you just set the environment variable, you may need to wait a few seconds for it to propagate, or you can redeploy the function to ensure it picks up the new variable.

### Step 4: Test the Function

1. Restart your Flutter app
2. Log in (if not already logged in)
3. Take a photo and enter a price
4. Click "Analyze Product"
5. The function should now work without the "Gemini API key not configured" error

## Alternative: Set via Supabase CLI

If you prefer using the command line:

```bash
# Set the secret
supabase secrets set GEMINI_API_KEY=your_api_key_here

# Verify it's set
supabase secrets list
```

**Note:** Make sure you're in the project root directory when running these commands.

## Troubleshooting

### If you still get the error after setting the key:

1. **Wait a few seconds** - Environment variables may take a moment to propagate
2. **Redeploy the function:**
   ```bash
   cd /Users/macbook/reseller_copilot
   supabase functions deploy analyze-product
   ```
3. **Verify the key is set correctly:**
   - Go back to the function settings
   - Make sure `GEMINI_API_KEY` is listed
   - Check that the value is correct (no extra spaces, complete key)

### If you get "Invalid API key" error:

- Make sure you copied the entire API key
- Check that the key hasn't been revoked in Google AI Studio
- Verify you're using the correct key (not a different project's key)

## Cost Information

Google Gemini API has a free tier:
- **Free tier:** 15 requests per minute (RPM)
- **Paid tier:** Higher limits available

For development and testing, the free tier should be sufficient. If you need higher limits, you can upgrade in Google AI Studio.
