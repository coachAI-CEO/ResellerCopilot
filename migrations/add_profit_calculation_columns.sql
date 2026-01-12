-- Migration: Add profit calculation detail columns to scans table
-- Run this in your Supabase SQL Editor

-- Add new columns for profit calculation breakdown
ALTER TABLE scans 
  ADD COLUMN IF NOT EXISTS fee_percentage NUMERIC,
  ADD COLUMN IF NOT EXISTS fees_amount NUMERIC,
  ADD COLUMN IF NOT EXISTS shipping_cost NUMERIC,
  ADD COLUMN IF NOT EXISTS profit_calculation TEXT;

-- Add comments to document the columns
COMMENT ON COLUMN scans.fee_percentage IS 'Platform fee percentage (typically 15%)';
COMMENT ON COLUMN scans.fees_amount IS 'Total fees calculated (market_price * fee_percentage / 100)';
COMMENT ON COLUMN scans.shipping_cost IS 'Estimated shipping cost';
COMMENT ON COLUMN scans.profit_calculation IS 'Human-readable profit calculation breakdown';
