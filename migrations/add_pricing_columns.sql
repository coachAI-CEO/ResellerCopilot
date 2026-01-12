-- Migration: Add new pricing columns to scans table
-- Run this in your Supabase SQL Editor

-- Add new columns for detailed pricing information
ALTER TABLE scans 
  ADD COLUMN IF NOT EXISTS ebay_price NUMERIC,
  ADD COLUMN IF NOT EXISTS amazon_price NUMERIC,
  ADD COLUMN IF NOT EXISTS current_price NUMERIC,
  ADD COLUMN IF NOT EXISTS market_price_source TEXT;

-- Add comments to document the columns
COMMENT ON COLUMN scans.ebay_price IS 'Current eBay price or average of recent sold listings';
COMMENT ON COLUMN scans.amazon_price IS 'Current Amazon price if available';
COMMENT ON COLUMN scans.current_price IS 'Current best available price across platforms';
COMMENT ON COLUMN scans.market_price_source IS 'Source/explanation of where market_price comes from';
