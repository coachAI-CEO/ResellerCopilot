# Findings & Recommendations

This file summarizes the code review findings and recommended next steps.

Major findings

- Hard-coded Supabase credentials were present in `lib/main.dart`. These have been replaced to load from environment variables via `flutter_dotenv`. See `.env.example`.
- The `analyze-product` Supabase Edge Function uses an LLM (Google Gemini) and extracts JSON out of free-text responses using a regex. This parsing is fragile and should be hardened.
- Images are sent as base64 payloads to the edge function which can lead to large payload sizes and slower performance.

Recommended next steps (prioritized)

1. Harden AI response handling (HIGH)
   - In the edge function, instruct the model to return only JSON and validate the JSON schema before returning to clients.
   - Consider using a JSON schema (ajv or similar) to validate fields and return clear error codes when validation fails.

2. Optimize image handling (HIGH)
   - Resize/compress images on-device before encoding to base64. Aim for < 200–300 KB when possible.
   - Alternatively, upload images to Supabase Storage and send a URL to the edge function instead of the full base64 payload.

3. Add CI and tests (MEDIUM)
   - Add GitHub Actions to run `flutter analyze`, `flutter test`, and code generation (build_runner).
   - Add unit tests for `SupabaseService` parsing logic (mock the edge function response).

4. Consistent error shapes (LOW)
   - Standardize error responses between the edge function and client (e.g., { error: string, code?: string }).

5. Security review (HIGH)
   - Ensure Supabase service role key is not used in client-side code.
   - Use `supabase secrets` for GEMINI_API_KEY and restrict access in the Supabase project.

Quick wins implemented in this change

- Added `flutter_dotenv` dependency and `.env.example` to remove embedded keys from source.
- Added `docs/` files: `OVERVIEW.md`, `SETUP.md`, `ARCHITECTURE.md`, `USAGE.md`.

If you'd like, I can implement the edge function hardening (add JSON schema validation and stricter error responses) next, or add a GitHub Actions workflow to run the analyzer and tests.
