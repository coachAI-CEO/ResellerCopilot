# Deploy Reseller Copilot to Fly.io

Fly.io is a global platform for deploying apps close to your users. This guide will help you deploy your Flutter web app to Fly.io.

## Prerequisites

1. **Install Fly CLI:**
   ```bash
   # On Mac
   brew install flyctl
   
   # Or download from: https://fly.io/docs/getting-started/installing-flyctl/
   ```

2. **Sign up for Fly.io:**
   - Go to: https://fly.io/app/sign-up
   - Sign up with GitHub or email
   - Free tier includes $5 credit per month

3. **Login to Fly.io:**
   ```bash
   flyctl auth login
   ```

## Quick Deployment

### Step 1: Initialize Fly.io App

```bash
cd /Users/macbook/reseller_copilot

# Launch the app (this creates fly.toml if needed)
flyctl launch
```

**When prompted:**
- App name: `reseller-copilot` (or choose your own)
- Region: Choose closest to you (e.g., `iad` for Washington DC)
- PostgreSQL: **No** (we're using Supabase)
- Redis: **No**

### Step 2: Deploy the App

```bash
flyctl deploy
```

This will:
- Build your Docker image
- Deploy it to Fly.io
- Give you a URL like: `https://reseller-copilot.fly.dev`

### Step 3: Open Your App

```bash
flyctl open
```

Or visit the URL from the deployment output.

## Configuration

### Update Supabase URL for Production

Your `lib/main.dart` already has the Supabase credentials. Make sure they're correct for production.

If you need to use different credentials for production, you can:
1. Use environment variables
2. Or keep the same Supabase project (recommended)

### Set Environment Variables (Optional)

If you need environment variables:

```bash
flyctl secrets set KEY=value
```

For example, if you want to use different Supabase keys in production:
```bash
flyctl secrets set SUPABASE_URL=https://pzhpkoiqcutkcaudrazn.supabase.co
flyctl secrets set SUPABASE_ANON_KEY=your_key_here
```

**Note:** The Flutter app is compiled at build time, so environment variables won't work for runtime config unless you modify the build process.

## Common Commands

### View App Status
```bash
flyctl status
```

### View Logs
```bash
flyctl logs
```

### SSH into Container (for debugging)
```bash
flyctl ssh console
```

### Scale the App
```bash
# Scale to 1 instance
flyctl scale count 1

# Scale to 0 (stop completely)
flyctl scale count 0

# Auto-scaling is configured in fly.toml
```

### Update the App
```bash
# After making changes
git add .
git commit -m "Your changes"
flyctl deploy
```

## Troubleshooting

### Build Fails

**Error: "Docker build failed"**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flyctl deploy --verbose
```

### App Won't Start

**Check logs:**
```bash
flyctl logs
```

**Common issues:**
- Port mismatch: Make sure nginx is listening on 8080 (configured in fly.toml)
- Missing dependencies: Check that `pubspec.yaml` is correct
- Build errors: Run `flutter build web` locally first to test

### Can't Access App

**Check if app is running:**
```bash
flyctl status
```

**Restart the app:**
```bash
flyctl apps restart reseller-copilot
```

### Region Issues

**List regions:**
```bash
flyctl regions list
```

**Change region:**
Edit `fly.toml` and change `primary_region`, then redeploy:
```bash
flyctl deploy
```

## Performance

### Auto-Scaling

The app is configured with auto-scaling in `fly.toml`:
- Machines start automatically when traffic arrives
- Machines stop after inactivity to save resources
- Minimum 0 machines (free tier friendly)

### Custom Domain

**Add a custom domain:**
```bash
flyctl certs create yourdomain.com
```

**Update DNS:**
- Add a CNAME record pointing to `reseller-copilot.fly.dev`
- Or use Fly.io's DNS: `flyctl dns create`

## Cost

**Free Tier:**
- $5 credit per month
- Shared CPU, 256MB RAM
- Auto-scaling to 0 when idle

**Paid Plans:**
- Start at ~$1.94/month for always-on instance
- More CPU/RAM as needed

## Security

### HTTPS

Fly.io automatically provides HTTPS certificates for all apps. No configuration needed!

### Secrets

Never commit secrets to git. Use Fly secrets:
```bash
flyctl secrets set SECRET_KEY=value
```

Access via environment variables in your app (if configured).

## Monitoring

### View Metrics
```bash
flyctl metrics
```

### View App Info
```bash
flyctl info
```

## Updating the App

After making code changes:

```bash
# 1. Commit changes
git add .
git commit -m "Your changes"

# 2. Deploy
flyctl deploy

# 3. Your app will be updated globally!
```

## Accessing from Phone

Once deployed, you can access your app from anywhere:

1. **Get your app URL:**
   ```bash
   flyctl status
   ```

2. **Open on your phone:**
   - Visit: `https://reseller-copilot.fly.dev`
   - Add to Home Screen for app-like experience

3. **HTTPS is automatic** - camera access will work!

## Comparison: Fly.io vs ngrok

**Fly.io:**
- ✅ Permanent URL
- ✅ Always available (or auto-scaling)
- ✅ Global CDN
- ✅ HTTPS included
- ✅ Production-ready
- ⚠️ Requires deployment process

**ngrok:**
- ✅ Instant setup
- ✅ Great for development
- ⚠️ URL changes each time
- ⚠️ Stops when your computer shuts down

## Next Steps

1. Deploy: `flyctl deploy`
2. Get URL: `flyctl status`
3. Access from phone: Visit the URL
4. Set up custom domain (optional)

Your app will be live globally! 🌍
