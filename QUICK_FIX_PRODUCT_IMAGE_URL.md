# Quick Fix: Add product_image_url Column

## Error
```
PostgrestException: Could not find the 'product_image_url' column of 'scans' in the schema cache
```

## Quick Solution (2 minutes)

### Step 1: Open Supabase SQL Editor
1. Go to: https://supabase.com/dashboard/project/pzhpkoiqcutkcaudrazn/sql/new
2. Or: Dashboard → **SQL Editor** → **New Query**

### Step 2: Run This SQL
Copy and paste this into the SQL Editor:

```sql
-- Add product_image_url column
ALTER TABLE scans 
  ADD COLUMN IF NOT EXISTS product_image_url TEXT;
```

### Step 3: Execute
Click **Run** (or press `Cmd+Enter` / `Ctrl+Enter`)

### Step 4: Done! ✅
You should see "Success. No rows returned"

Now try scanning a product again - the error should be gone!

## Why This Happened
The app code was updated to save `product_image_url`, but the database column wasn't created yet. This SQL adds the missing column.
