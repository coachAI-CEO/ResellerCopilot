# Accessing Reseller Copilot from a Remote Location

Since your code is on GitHub, you can access it from any computer with internet access. Here's how:

## Quick Start

### 1. Clone the Repository

On your remote computer, open a terminal and run:

```bash
git clone https://github.com/coachAI-CEO/ResellerCopilot.git
cd ResellerCopilot
```

### 2. Prerequisites

Make sure you have the following installed:

- **Flutter SDK**: https://flutter.dev/docs/get-started/install
- **Git**: Usually pre-installed on Mac/Linux, or download from https://git-scm.com/
- **Supabase CLI** (optional, for edge function deployment):
  ```bash
  npm install -g supabase
  ```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Generate Required Files

The project uses Freezed for code generation:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 5. Configure Supabase Credentials

Edit `lib/main.dart` and add your Supabase credentials:

```dart
await Supabase.initialize(
  url: 'https://pzhpkoiqcutkcaudrazn.supabase.co',
  anonKey: 'YOUR_ANON_KEY_HERE', // Get from Supabase Dashboard → Settings → API
);
```

**Where to find your keys:**
1. Go to https://supabase.com/dashboard
2. Select your project: `pzhpkoiqcutkcaudrazn`
3. Go to **Settings** → **API**
4. Copy the **anon public** key (starts with `eyJ`)

### 6. Set Up Database

Run the database migrations in Supabase SQL Editor:

1. Go to Supabase Dashboard → **SQL Editor**
2. Run each migration file in order:
   - `migrations/add_pricing_columns.sql`
   - `migrations/add_profit_calculation_columns.sql`
   - `migrations/add_sales_tax_columns.sql`
   - `migrations/add_market_analysis_column.sql`

Or see `UPDATE_DATABASE_SCHEMA.md` for detailed instructions.

### 7. Configure Edge Function (If Needed)

If you need to deploy or update the edge function:

```bash
# Link to your Supabase project
supabase link --project-ref pzhpkoiqcutkcaudrazn

# Set environment variables
supabase secrets set GEMINI_API_KEY=your_gemini_api_key_here

# Deploy the function
supabase functions deploy analyze-product
```

**Get your Gemini API key:**
1. Go to https://aistudio.google.com/app/apikey
2. Sign in with Google
3. Click "Create API Key" or "Get API Key"
4. Copy the key

### 8. Run the App

**For Web (Chrome):**
```bash
flutter run -d chrome --web-port=8080
```

**For iOS (Mac only):**
```bash
flutter run -d ios
```

**For Android:**
```bash
flutter run -d android
```

## Alternative: Using GitHub Codespaces (Browser-Based)

If you want to work from any browser without installing anything:

1. Go to https://github.com/coachAI-CEO/ResellerCopilot
2. Click the green **"Code"** button
3. Select **"Codespaces"** tab
4. Click **"Create codespace on main"**
5. GitHub will create a cloud-based development environment

Note: Codespaces has limitations for Flutter development, but you can view and edit code.

## Keeping Your Code in Sync

### Pull Latest Changes

On any machine, pull the latest code:

```bash
git pull origin main
```

### Push Your Changes

After making changes:

```bash
git add .
git commit -m "Description of your changes"
git push origin main
```

## Important Notes

### ⚠️ Security: Don't Commit Secrets

**NEVER commit these to GitHub:**
- Supabase service role keys
- API keys (Gemini, etc.)
- Passwords
- Environment files with secrets

They're already excluded in `.gitignore`, but double-check before committing.

### 🔐 Where to Store Secrets Locally

For Supabase credentials:
- Add them directly in `lib/main.dart` (they're public anyway - anon keys are safe)
- Or use environment variables (more secure for team projects)

For Gemini API key:
- Store in Supabase Dashboard → Edge Functions → Settings → Secrets
- Never commit to git

### 📝 Recommended Workflow

1. **First Time Setup:**
   ```bash
   git clone https://github.com/coachAI-CEO/ResellerCopilot.git
   cd ResellerCopilot
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   # Edit lib/main.dart with your Supabase credentials
   flutter run
   ```

2. **Daily Work:**
   ```bash
   git pull  # Get latest changes
   flutter run  # Run the app
   # Make changes...
   git add .
   git commit -m "Your changes"
   git push
   ```

## Troubleshooting

### "Cannot find module" errors
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Supabase connection errors
- Verify your Supabase URL and anon key in `lib/main.dart`
- Check that your Supabase project is active
- Verify network connection

### Edge function errors
- Check edge function logs in Supabase Dashboard
- Verify `GEMINI_API_KEY` is set in Supabase Dashboard → Edge Functions → Settings
- Redeploy if needed: `supabase functions deploy analyze-product`

### Database errors
- Run the database migrations (see `UPDATE_DATABASE_SCHEMA.md`)
- Check Supabase Dashboard → Database → Tables

## Quick Reference

**Repository URL:** https://github.com/coachAI-CEO/ResellerCopilot

**Clone Command:**
```bash
git clone https://github.com/coachAI-CEO/ResellerCopilot.git
```

**Supabase Dashboard:** https://supabase.com/dashboard/project/pzhpkoiqcutkcaudrazn

**Main Setup Files:**
- `CRITICAL_SETUP.md` - Initial setup steps
- `README.md` - Project overview
- `UPDATE_DATABASE_SCHEMA.md` - Database setup
