# Reseller Copilot — Architecture

This file explains the major components and how they interact.

High-level components

- Flutter client (`lib/`) — UI and local interactions
  - `screens/` — `AuthScreen`, `ScannerScreen`
  - `services/SupabaseService` — encapsulates calls to Supabase (edge function + DB)
  - `models/ScanResult` — Freezed model for serialized scan data

- Supabase
  - Auth — handles user accounts and JWT sessions
  - Database — `scans` table stores results
  - Edge Functions — `analyze-product` function calls the Gemini API and returns normalized JSON

Data & control flow

1. User authenticates via `AuthScreen` (Supabase Auth).
2. In `ScannerScreen`, user takes a photo and provides a price (and optional barcode).
3. `SupabaseService.analyzeItem` builds a payload (base64 image + price + condition) and invokes the `analyze-product` edge function via `supabase.functions.invoke`.
4. The edge function authenticates incoming requests using the Authorization header and the Supabase client. It calls Google Gemini with a system prompt that instructs the model to return a JSON object with fields like `market_price`, `ebay_price`, `net_profit`, `verdict`, `velocity_score`, and `product_image_url`.
5. The edge function returns normalized JSON. The Flutter client parses it into `ScanResult` and optionally saves it to the `scans` table via `SupabaseService.saveScan`.

Error handling & edge cases

- Auth: The edge function verifies the caller's JWT; if invalid/expired, it returns 401. The client attempts to refresh the session before calling the function.
- Image sizes: The app sends full images as base64. For reliability, resize/compress images before sending to reduce payload sizes.
- Gemini response parsing: The function extracts JSON from the AI response text; if the model returns non-JSON or malformed JSON, the function sends a 500 with the raw response for debugging.

Security considerations

- Never commit API keys or service role keys to source. Use `supabase secrets` for GEMINI_API_KEY and env vars for Supabase URL/anon key in the Flutter client.
- Prefer the service role key only in server-side contexts. The edge function should use the service key if it needs elevated privileges but never return sensitive information to the client.

Extensibility

- Add more marketplaces (StockX, Poshmark) by enriching the system prompt and parsing logic.
- Replace Gemini with another model by adjusting the edge function payload and parsing.
