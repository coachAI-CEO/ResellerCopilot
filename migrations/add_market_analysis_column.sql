-- Migration: Add market_analysis column to scans table
-- Run this in your Supabase SQL Editor

-- Add new column for comprehensive market analysis
ALTER TABLE scans 
  ADD COLUMN IF NOT EXISTS market_analysis TEXT;

-- Add comment to document the column
COMMENT ON COLUMN scans.market_analysis IS 'Comprehensive market analysis including item details, brand value, scarcity, pricing data, strategy, warnings, and summary';
