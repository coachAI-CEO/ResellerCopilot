# Reseller Copilot — Overview

Reseller Copilot is a Flutter app that helps resellers analyze product profitability in retail stores by using a scanned photo or barcode plus an AI-powered backend to estimate market prices, fees, shipping, taxes, and a buy/pass verdict.

Key features
- Take photos of products or provide a barcode
- Analyze product pricing and calculate net profit using an AI-backed Supabase Edge Function
- Save scan history to Supabase for later review
- Authentication via Supabase Auth
- Simple, mobile-first UI built with Flutter

Primary users
- Resellers sourcing inventory in retail stores (e.g., off-price stores like Ross/Marshalls)

What this repo contains
- `lib/` — Flutter app source
- `supabase/functions/` — Supabase Edge Functions (AI analysis)
- `migrations/` — SQL migrations to prepare the `scans` table
- `build/`, `web/`, `test/` — build outputs and tests

Goals of the project
- Help resellers quickly determine whether an item is worth buying for resale
- Provide transparent profit calculations and market data sources (eBay/Amazon)

When to read other docs
- Follow `docs/SETUP.md` if setting up locally or deploying the edge function.
- Read `docs/ARCHITECTURE.md` for how parts interact (client, edge function, Supabase DB).
