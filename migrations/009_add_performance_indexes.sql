-- Add performance indexes for scans table
-- Migration: 009_add_performance_indexes.sql
-- Date: 2026-01-21

-- Index for user scans query (most common query pattern)
-- Speeds up: SELECT * FROM scans WHERE user_id = ? ORDER BY created_at DESC
CREATE INDEX IF NOT EXISTS idx_scans_user_id_created_at
ON scans(user_id, created_at DESC);

-- Index for barcode lookups
-- Speeds up: SELECT * FROM scans WHERE barcode = ?
CREATE INDEX IF NOT EXISTS idx_scans_barcode
ON scans(barcode)
WHERE barcode IS NOT NULL;

-- Index for verdict filtering
-- Speeds up: SELECT * FROM scans WHERE verdict = 'BUY'
CREATE INDEX IF NOT EXISTS idx_scans_verdict
ON scans(verdict);

-- Index for profit range queries
-- Speeds up: SELECT * FROM scans WHERE net_profit > ? ORDER BY net_profit DESC
CREATE INDEX IF NOT EXISTS idx_scans_net_profit
ON scans(net_profit DESC);

-- Composite index for common filter combinations
-- Speeds up: SELECT * FROM scans WHERE user_id = ? AND verdict = 'BUY' ORDER BY net_profit DESC
CREATE INDEX IF NOT EXISTS idx_scans_user_verdict_profit
ON scans(user_id, verdict, net_profit DESC);

-- Index for product name searches (useful for future search feature)
-- Speeds up: SELECT * FROM scans WHERE product_name ILIKE '%search%'
CREATE INDEX IF NOT EXISTS idx_scans_product_name
ON scans USING gin(product_name gin_trgm_ops);

-- Enable pg_trgm extension for fuzzy text search (if not already enabled)
-- This extension is needed for the GIN index above
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Performance notes:
-- 1. idx_scans_user_id_created_at: Primary index for user's scan history
--    Expected improvement: 10-100x faster queries as data grows
-- 2. idx_scans_barcode: Fast duplicate detection by barcode
--    Expected improvement: O(log n) vs O(n) table scan
-- 3. idx_scans_verdict: Filter by BUY/PASS efficiently
--    Expected improvement: 50-75% faster filtered queries
-- 4. idx_scans_net_profit: Sort by profitability
--    Expected improvement: Eliminates sort step in query plan
-- 5. idx_scans_user_verdict_profit: Composite for complex queries
--    Expected improvement: Single index lookup instead of multiple filters
-- 6. idx_scans_product_name: Fuzzy search support
--    Expected improvement: Enables ILIKE queries with good performance
