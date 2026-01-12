# Reseller Copilot

A Flutter mobile app that helps resellers analyze product profitability by scanning items in stores like Ross/Marshalls.

## Features

- 📸 Take photos of products or scan barcodes
- 🤖 AI-powered analysis using Google Gemini 1.5 Flash
- 💰 Instant profitability calculations
- 📊 Velocity scoring (High/Med/Low)
- 💾 Save scan history to Supabase

## Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Supabase (PostgreSQL, Auth, Edge Functions)
- **AI:** Google Gemini 1.5 Flash API
- **State Management:** Riverpod (ready to use)

## Setup Instructions

### 1. Supabase Setup

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Create the `scans` table with the following schema:
   ```sql
   CREATE TABLE scans (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     user_id UUID REFERENCES auth.users(id),
     barcode TEXT,
     product_name TEXT NOT NULL,
     buy_price NUMERIC NOT NULL,
     market_price NUMERIC NOT NULL,
     net_profit NUMERIC NOT NULL,
     verdict TEXT NOT NULL CHECK (verdict IN ('BUY', 'PASS')),
     velocity_score TEXT NOT NULL CHECK (velocity_score IN ('High', 'Med', 'Low')),
     created_at TIMESTAMP DEFAULT NOW()
   );
   ```

3. Set up Row Level Security (RLS):
   ```sql
   ALTER TABLE scans ENABLE ROW LEVEL SECURITY;
   
   CREATE POLICY "Users can view their own scans"
     ON scans FOR SELECT
     USING (auth.uid() = user_id);
   
   CREATE POLICY "Users can insert their own scans"
     ON scans FOR INSERT
     WITH CHECK (auth.uid() = user_id);
   ```

### 2. Edge Function Setup

1. Install Supabase CLI:
   ```bash
   npm install -g supabase
   ```

2. Link your project:
   ```bash
   supabase link --project-ref your-project-ref
   ```

3. Set environment variables:
   ```bash
   supabase secrets set GEMINI_API_KEY=your_gemini_api_key
   ```

4. Deploy the edge function:
   ```bash
   supabase functions deploy analyze-product
   ```

### 3. Flutter Setup

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Generate code (for Freezed models):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. Update `lib/main.dart` with your Supabase credentials:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── scan_result.dart     # ScanResult model (Freezed)
├── services/
│   └── supabase_service.dart # Supabase service layer
└── screens/
    ├── auth_screen.dart      # Authentication (login/signup)
    └── scanner_screen.dart   # Main scanner UI

supabase/
└── functions/
    └── analyze-product/
        └── index.ts         # Edge function for AI analysis
```

## Usage

1. Open the app and take a photo of a product
2. Enter the store price
3. Optionally enter a barcode
4. Tap "Analyze Product"
5. View the verdict (BUY/PASS) and profitability metrics

## Environment Variables

- `GEMINI_API_KEY`: Your Google Gemini API key (set in Supabase secrets)
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Your Supabase anonymous key

## Notes

- The camera functionality uses `image_picker` package. For production, consider using `camera` package for a more native camera experience.
- The app includes authentication with login/signup screens. Users must be authenticated to use the scanner.
- The edge function expects the image as base64. For large images, consider compression or resizing.

## Critical Setup

⚠️ **IMPORTANT**: Before running the app, you must:

1. **Generate Freezed code**: Run `flutter pub run build_runner build --delete-conflicting-outputs`
2. **Configure Supabase credentials** in `lib/main.dart`
3. **Set up the database** (see Setup Instructions above)
4. **Deploy the edge function** (see Setup Instructions above)

See `CRITICAL_SETUP.md` for detailed instructions.
