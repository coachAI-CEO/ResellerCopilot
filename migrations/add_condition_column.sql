-- Migration: Add condition column to scans table
-- Run this in your Supabase SQL Editor

-- Add new column for item condition
ALTER TABLE scans 
  ADD COLUMN IF NOT EXISTS condition TEXT CHECK (condition IN ('Used', 'New', 'New in Box'));

-- Add comment to document the column
COMMENT ON COLUMN scans.condition IS 'Item condition: Used, New, or New in Box';

-- Set default for existing rows (optional)
UPDATE scans SET condition = 'Used' WHERE condition IS NULL;
