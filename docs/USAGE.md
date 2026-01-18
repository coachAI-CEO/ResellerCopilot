# Reseller Copilot — Quick Usage

This short guide shows the typical flow in the mobile app once you have the project configured and running.

1. Start the app (ensure environment variables are set as described in `docs/SETUP.md`).

2. Create an account or log in using the Auth screen.

3. On the scanner screen:
   - Tap "Take Photo" and take a picture of the product.
   - Enter the store price in the price field.
   - (Optional) Enter a barcode if available.
   - Select the item condition: `Used`, `New`, or `New in Box`.
   - Tap "Analyze Product".

4. The app will call the `analyze-product` edge function and display the result card with:
   - Verdict (BUY / PASS)
   - Market price and net profit calculation
   - Velocity score (High/Med/Low)
   - Links to marketplace listings (eBay/Amazon) when available

5. The scan is saved to the `scans` table in Supabase and appears in history (if implemented).

Notes
- If the analysis fails with an auth error, re-login to refresh your session.
- For better performance, keep photos relatively small (compress or resize before sending).
