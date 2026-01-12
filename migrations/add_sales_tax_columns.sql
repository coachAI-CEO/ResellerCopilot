-- Migration: Add sales tax columns to scans table
-- Run this in your Supabase SQL Editor

-- Add new columns for sales tax calculation
ALTER TABLE scans 
  ADD COLUMN IF NOT EXISTS sales_tax_rate NUMERIC,
  ADD COLUMN IF NOT EXISTS sales_tax_amount NUMERIC;

-- Add comments to document the columns
COMMENT ON COLUMN scans.sales_tax_rate IS 'Sales tax rate percentage (typically 7-10%)';
COMMENT ON COLUMN scans.sales_tax_amount IS 'Sales tax amount calculated (buy_price * sales_tax_rate / 100)';
