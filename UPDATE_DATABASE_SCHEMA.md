# Update Database Schema - Add Pricing Columns

## Problem

You're getting this error:
```
"code": "PGRST204",
"message": "Could not find the 'amazon_price' column of 'scans' in the schema cache"
```

This means the `scans` table is missing the new pricing columns we added to the model.

## Solution

### Option 1: Run SQL in Supabase Dashboard (Recommended)

1. Go to your Supabase Dashboard: https://supabase.com/dashboard/project/pzhpkoiqcutkcaudrazn
2. Click on **SQL Editor** in the left sidebar
3. Click **New Query**

#### First Migration: Pricing Columns
4. Copy and paste this SQL:

```sql
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
```

5. Click **Run** (or press `Cmd+Enter` / `Ctrl+Enter`)

#### Second Migration: Profit Calculation Columns
6. Create a new query and paste this SQL:

```sql
-- Add new columns for profit calculation breakdown
ALTER TABLE scans 
  ADD COLUMN IF NOT EXISTS sales_tax_rate NUMERIC,
  ADD COLUMN IF NOT EXISTS sales_tax_amount NUMERIC,
  ADD COLUMN IF NOT EXISTS fee_percentage NUMERIC,
  ADD COLUMN IF NOT EXISTS fees_amount NUMERIC,
  ADD COLUMN IF NOT EXISTS shipping_cost NUMERIC,
  ADD COLUMN IF NOT EXISTS profit_calculation TEXT;

-- Add comments to document the columns
COMMENT ON COLUMN scans.sales_tax_rate IS 'Sales tax rate percentage (typically 7-10%)';
COMMENT ON COLUMN scans.sales_tax_amount IS 'Sales tax amount calculated (buy_price * sales_tax_rate / 100)';
COMMENT ON COLUMN scans.fee_percentage IS 'Platform fee percentage (typically 15%)';
COMMENT ON COLUMN scans.fees_amount IS 'Total fees calculated (market_price * fee_percentage / 100)';
COMMENT ON COLUMN scans.shipping_cost IS 'Estimated shipping cost';
COMMENT ON COLUMN scans.profit_calculation IS 'Human-readable profit calculation breakdown';
```

7. Click **Run**

#### Third Migration: Market Analysis Column
8. Create a new query and paste this SQL:

```sql
-- Add new column for comprehensive market analysis
ALTER TABLE scans 
  ADD COLUMN IF NOT EXISTS market_analysis TEXT;

-- Add comment to document the column
COMMENT ON COLUMN scans.market_analysis IS 'Comprehensive market analysis including item details, brand value, scarcity, pricing data, strategy, warnings, and summary';
```

9. Click **Run**

#### Fourth Migration: Product Image URL Column
10. Create a new query and paste this SQL:

```sql
-- Add new column for product image URL from marketplace
ALTER TABLE scans 
  ADD COLUMN IF NOT EXISTS product_image_url TEXT;

-- Add comment to document the column
COMMENT ON COLUMN scans.product_image_url IS 'URL to actual product image from eBay, Amazon, or other marketplace (not the scanned photo)';
```

11. Click **Run**

#### Fifth Migration: Condition Column (if not already added)
12. Create a new query and paste this SQL:

```sql
-- Add new column for item condition
ALTER TABLE scans 
  ADD COLUMN IF NOT EXISTS condition TEXT CHECK (condition IN ('Used', 'New', 'New in Box'));

-- Add comment to document the column
COMMENT ON COLUMN scans.condition IS 'Item condition: Used, New, or New in Box';
```

13. Click **Run**
14. You should see "Success. No rows returned" for all migrations

### Option 2: Use Supabase CLI

If you have Supabase CLI set up:

```bash
cd /Users/macbook/reseller_copilot
supabase db push
```

Or run the SQL file directly:

```bash
supabase db execute --file migrations/add_pricing_columns.sql
```

## Verify the Migration

After running the migration, verify the columns were added:

1. Go to **Table Editor** in Supabase Dashboard
2. Click on the `scans` table
3. You should see the new columns:
   - `ebay_price` (NUMERIC, nullable)
   - `amazon_price` (NUMERIC, nullable)
   - `current_price` (NUMERIC, nullable)
   - `market_price_source` (TEXT, nullable)

## What These Columns Do

### Pricing Columns (from first migration):
- **ebay_price**: Stores the eBay price from the AI analysis
- **amazon_price**: Stores the Amazon price from the AI analysis
- **current_price**: Stores the current best available price
- **market_price_source**: Stores where the market price came from (e.g., "eBay sold listings average")

### Profit Calculation Columns (from second migration):
- **sales_tax_rate**: Sales tax rate percentage (typically 7-10%)
- **sales_tax_amount**: Sales tax amount (buy_price * sales_tax_rate / 100)
- **fee_percentage**: Platform fee percentage (typically 15%)
- **fees_amount**: Total fees calculated (market_price * fee_percentage / 100)
- **shipping_cost**: Estimated shipping cost
- **profit_calculation**: Human-readable profit calculation breakdown

### Market Analysis Column (from third migration):
- **market_analysis**: Comprehensive market analysis text including item details, brand value, scarcity, pricing data, selling strategy, warnings, and summary

All columns are **nullable** (optional), so existing scans won't break.

## After Migration

Once you've added the columns:
1. The error should be resolved
2. Try analyzing a product again
3. The new pricing details should save correctly

## Troubleshooting

If you get permission errors:
- Make sure you're logged in as the project owner
- Or ensure your database user has ALTER TABLE permissions

If columns already exist:
- The `IF NOT EXISTS` clause will prevent errors
- It's safe to run the migration multiple times
