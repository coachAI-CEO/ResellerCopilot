# Reseller Copilot — Setup

This guide covers local setup for development (macOS / zsh) and how to configure Supabase and the AI edge function.

Prerequisites
- Flutter SDK installed and on PATH
- Node (for Supabase CLI) and npm
- Supabase project and CLI (`npm i -g supabase`)
- A Google Gemini API key (set as a Supabase secret)

1) Clone & install

```bash
# from your shell (zsh)
git clone <repo-url>
cd reseller_copilot
flutter pub get
```

2) Generate code (Freezed / JSON serialization)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

3) Remove hard-coded keys from source

WARNING: The project currently includes example Supabase credentials in `lib/main.dart`. Do NOT keep credentials in source control. Replace the hard-coded initialization with environment-driven configuration.

Recommended approaches
- Use `flutter_dotenv` for local development and load a `.env` file (never commit `.env`).
- Example: a `.env.example` has been added to the project. Copy it to `.env` and fill in your values.

Example `.env` usage (zsh):

```bash
cp .env.example .env
# Edit .env and add your values
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your_anon_key"
flutter run
```
- Use CI secrets and per-platform environment injection for builds.
- For the edge function, use `supabase secrets set GEMINI_API_KEY=...`.

Example (replace `lib/main.dart` initialization):

```dart
await Supabase.initialize(
  url: const String.fromEnvironment('SUPABASE_URL'),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
);
```

And start locally with environment injection:

```bash
export SUPABASE_URL=https://your-project.supabase.co
export SUPABASE_ANON_KEY=your_anon_key
flutter run
```

4) Supabase DB setup

Run the SQL migration in `migrations/` to create the `scans` table. Example using Supabase SQL editor or psql against the database.

6) Storage bucket for images

- Create a bucket named `scans-temp` in your Supabase project for temporary image uploads.
- Recommended settings: private bucket (not public). The client uploads files and we create short-lived signed URLs for the edge function to fetch.

Example using Supabase CLI:

```bash
supabase storage create-bucket scans-temp --public false
```

If you don't have the CLI, create the bucket in the Supabase dashboard (Storage → New bucket) and set it to private.

Grant authenticated users access to upload into the bucket via a storage policy or allow authenticated uploads by default. For example, in SQL you can add a policy that allows inserts for authenticated users.


5) Edge function (AI analysis)

Install Supabase CLI and link project:

```bash
npm install -g supabase
supabase login
supabase link --project-ref your-project-ref
```

Create the secret for Gemini:

```bash
supabase secrets set GEMINI_API_KEY=your_gemini_api_key
```

Deploy the function:

```bash
supabase functions deploy analyze-product
```

6) Run the app

With environment variables set as above, run:

```bash
flutter run
```

7) Debugging tips
- If the analyze edge function returns 401: ensure Supabase client in the app is sending the auth session and that the edge function has access to the needed Supabase keys.
- If Gemini returns errors: confirm `GEMINI_API_KEY` is set and valid. Check function logs via `supabase functions logs analyze-product`.
