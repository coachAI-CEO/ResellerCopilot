-- Migration: Add product_image_url column to scans table
-- Run this in your Supabase SQL Editor

-- Add new column for product image URL from marketplace
ALTER TABLE scans 
  ADD COLUMN IF NOT EXISTS product_image_url TEXT;

-- Add comment to document the column
COMMENT ON COLUMN scans.product_image_url IS 'URL to actual product image from eBay, Amazon, or other marketplace (not the scanned photo)';
