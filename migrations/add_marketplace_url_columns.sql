-- Migration: Add ebay_url and amazon_url columns to scans table
-- Run this in your Supabase SQL Editor (or include in your migration pipeline)

ALTER TABLE scans
  ADD COLUMN IF NOT EXISTS ebay_url TEXT,
  ADD COLUMN IF NOT EXISTS amazon_url TEXT;

COMMENT ON COLUMN scans.ebay_url IS 'Direct URL to the eBay listing used as source for ebay_price';
COMMENT ON COLUMN scans.amazon_url IS 'Direct URL to the Amazon product page used as source for amazon_price';
