-- Migration: Add ebay_search_url and amazon_search_url columns to scans table
-- Run this in your Supabase SQL Editor

ALTER TABLE scans
  ADD COLUMN IF NOT EXISTS ebay_search_url TEXT,
  ADD COLUMN IF NOT EXISTS amazon_search_url TEXT;

COMMENT ON COLUMN scans.ebay_search_url IS 'Fallback eBay search URL generated when direct ebay_url from AI is invalid';
COMMENT ON COLUMN scans.amazon_search_url IS 'Fallback Amazon search URL generated when direct amazon_url from AI is invalid';
