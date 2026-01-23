# Phase 3 Testing Guide

This guide provides comprehensive test scenarios for the new Phase 3 features: Scan History, Offline Support, and Settings.

## Prerequisites

1. Install dependencies:
```bash
flutter pub get
```

2. Ensure you have a test account with some existing scans in the database

3. Have network connectivity toggle available (airplane mode or network settings)

## Test Plan

### 1. Scan History Screen Tests

#### 1.1 Navigation
- [ ] **TEST**: From Scanner screen, tap the History icon (📊) in the AppBar
- [ ] **EXPECTED**: History screen opens
- [ ] **EXPECTED**: AppBar shows "Scan History" title with Refresh and Export buttons

#### 1.2 Display Scans
- [ ] **TEST**: View the list of scans
- [ ] **EXPECTED**: Scans are displayed in cards with:
  - Product image thumbnail (if available)
  - Product name
  - Barcode and condition (if available)
  - BUY/PASS badge (green for BUY, red for PASS)
  - Buy price, Market price, Net profit
  - Velocity score with colored icon
  - Relative date (e.g., "2h ago", "Yesterday", "Jan 15, 2026")

#### 1.3 Search Functionality
- [ ] **TEST**: Type a product name in the search bar
- [ ] **EXPECTED**: List filters to show only matching products
- [ ] **TEST**: Type a barcode in the search bar
- [ ] **EXPECTED**: List filters to show scans with that barcode
- [ ] **TEST**: Click the X button in search bar
- [ ] **EXPECTED**: Search clears and full list returns
- [ ] **EXPECTED**: Count updates (e.g., "Showing 3 of 15 scans")

#### 1.4 Filter by Verdict
- [ ] **TEST**: Tap "All" filter chip
- [ ] **EXPECTED**: Shows all scans with count (e.g., "All (15)")
- [ ] **TEST**: Tap "Buy" filter chip
- [ ] **EXPECTED**: Shows only BUY scans with count (e.g., "Buy (8)")
- [ ] **EXPECTED**: Chip has green background
- [ ] **TEST**: Tap "Pass" filter chip
- [ ] **EXPECTED**: Shows only PASS scans with count (e.g., "Pass (7)")
- [ ] **EXPECTED**: Chip has red background
- [ ] **TEST**: Combine filter with search
- [ ] **EXPECTED**: Both filters apply correctly

#### 1.5 Sort Options
- [ ] **TEST**: Tap sort dropdown, select "Date"
- [ ] **EXPECTED**: Scans sorted by date (newest first)
- [ ] **TEST**: Tap sort dropdown, select "Profit"
- [ ] **EXPECTED**: Scans sorted by net profit (highest first)
- [ ] **TEST**: Tap sort dropdown, select "Name"
- [ ] **EXPECTED**: Scans sorted alphabetically (A-Z)

#### 1.6 Scan Details
- [ ] **TEST**: Tap a scan card
- [ ] **EXPECTED**: Modal bottom sheet opens showing:
  - Product name in large text
  - Product image (full size)
  - Price breakdown section with all fees
  - Market analysis section with formatted text
  - Marketplace links (eBay, Amazon) if available
- [ ] **TEST**: Swipe down or tap X to close
- [ ] **EXPECTED**: Modal closes

#### 1.7 Swipe to Delete
- [ ] **TEST**: Swipe a scan card left to right
- [ ] **EXPECTED**: Red delete background appears
- [ ] **TEST**: Swipe far enough to trigger delete
- [ ] **EXPECTED**: Confirmation dialog appears: "Delete Scan"
- [ ] **TEST**: Tap "Cancel" in dialog
- [ ] **EXPECTED**: Dialog closes, scan remains
- [ ] **TEST**: Swipe and tap "Delete" in dialog
- [ ] **EXPECTED**: Scan is deleted from database
- [ ] **EXPECTED**: Green snackbar: "[Product name] deleted"
- [ ] **EXPECTED**: Scan removed from list
- [ ] **EXPECTED**: Counts update

#### 1.8 Export to CSV
- [ ] **TEST**: Apply filters (e.g., only "BUY" scans)
- [ ] **TEST**: Tap Export button (download icon) in AppBar
- [ ] **EXPECTED**: Dialog shows CSV content with headers:
  - Date, Product Name, Barcode, Condition, Buy Price, Market Price, Net Profit, Verdict, Velocity Score
- [ ] **EXPECTED**: Only filtered scans are included
- [ ] **EXPECTED**: CSV data is properly formatted
- [ ] **EXPECTED**: Green snackbar: "Exported X scans to CSV"

#### 1.9 Pull to Refresh
- [ ] **TEST**: Pull down on the scan list
- [ ] **EXPECTED**: Refresh indicator appears
- [ ] **EXPECTED**: List reloads from database
- [ ] **EXPECTED**: New scans appear if any were added

#### 1.10 Empty States
- [ ] **TEST**: Clear all filters, ensure no scans exist
- [ ] **EXPECTED**: Empty state shows:
  - History icon
  - "No scan history yet"
  - "Start scanning products to see them here"
- [ ] **TEST**: Apply filters that match nothing
- [ ] **EXPECTED**: Empty state shows:
  - Search-off icon
  - "No matching scans found"
  - "Try adjusting your filters"

#### 1.11 Error Handling
- [ ] **TEST**: Simulate database error (disconnect network before opening screen)
- [ ] **EXPECTED**: Error state shows:
  - Error icon
  - "Failed to load scans"
  - Error message
  - "Retry" button
- [ ] **TEST**: Tap Retry button
- [ ] **EXPECTED**: Attempts to reload scans

---

### 2. Offline Support Tests

#### 2.1 Network Status Detection
- [ ] **TEST**: Open app with network connected
- [ ] **EXPECTED**: No offline indicator
- [ ] **TEST**: Turn on airplane mode or disable network
- [ ] **EXPECTED**: App detects offline status
- [ ] **TEST**: Turn network back on
- [ ] **EXPECTED**: App detects online status

#### 2.2 Offline Scan Queueing
- [ ] **TEST**: Disable network connection
- [ ] **TEST**: Take photo and analyze a product
- [ ] **EXPECTED**: Analysis completes successfully
- [ ] **EXPECTED**: Orange snackbar: "Scan queued for retry when online"
- [ ] **TEST**: Go to Settings > Offline Queue
- [ ] **EXPECTED**: Queue Statistics shows "Queued Scans: 1"

#### 2.3 Automatic Retry
- [ ] **TEST**: With scans queued, enable network connection
- [ ] **EXPECTED**: App automatically attempts to retry queued scans
- [ ] **TEST**: Check Settings > Offline Queue
- [ ] **EXPECTED**: Queue size decreases as scans are saved
- [ ] **EXPECTED**: Green snackbar: "Successfully saved X scan(s)"

#### 2.4 Manual Retry
- [ ] **TEST**: With scans queued and online
- [ ] **TEST**: Go to Settings > Offline Queue > Tap "Retry Queued Scans"
- [ ] **EXPECTED**: All queued scans are attempted
- [ ] **EXPECTED**: Successful scans removed from queue
- [ ] **EXPECTED**: Green snackbar: "Successfully saved X scan(s)"
- [ ] **TEST**: Try manual retry while offline
- [ ] **EXPECTED**: Orange snackbar: "Cannot retry: Device is offline"
- [ ] **EXPECTED**: Retry button disabled

#### 2.5 View Queued Scans
- [ ] **TEST**: With scans in queue, tap "View Queued Scans"
- [ ] **EXPECTED**: Modal shows list of queued scans with:
  - Product name
  - Queued date/time
  - Delete button (red trash icon)
- [ ] **TEST**: Tap delete on a queued scan
- [ ] **EXPECTED**: Scan removed from queue
- [ ] **EXPECTED**: Queue count decreases

#### 2.6 Clear Queue
- [ ] **TEST**: Go to Settings > Offline Queue > Tap "Clear Queue"
- [ ] **EXPECTED**: Confirmation dialog: "Clear Queue"
- [ ] **EXPECTED**: Warning: "This will permanently remove all queued scans"
- [ ] **TEST**: Tap "Cancel"
- [ ] **EXPECTED**: Dialog closes, queue unchanged
- [ ] **TEST**: Tap "Clear"
- [ ] **EXPECTED**: All queued scans removed
- [ ] **EXPECTED**: Green snackbar: "Queue cleared successfully"
- [ ] **EXPECTED**: Queue Statistics shows "Queued Scans: 0"

#### 2.7 Persistence
- [ ] **TEST**: Queue some scans while offline
- [ ] **TEST**: Force close the app (don't just minimize)
- [ ] **TEST**: Reopen the app
- [ ] **EXPECTED**: Queued scans still present
- [ ] **TEST**: Check Settings > Offline Queue
- [ ] **EXPECTED**: Same queue count as before app closed

---

### 3. Settings Screen Tests

#### 3.1 Navigation
- [ ] **TEST**: From Scanner screen, tap Settings icon (⚙️) in AppBar
- [ ] **EXPECTED**: Settings screen opens

#### 3.2 Network Status Banner
- [ ] **TEST**: Disable network
- [ ] **TEST**: Open Settings screen
- [ ] **EXPECTED**: Orange banner at top:
  - Cloud-off icon
  - "You are offline. Scans will be queued for retry."
- [ ] **TEST**: Enable network
- [ ] **EXPECTED**: Orange banner disappears

#### 3.3 Account Section
- [ ] **TEST**: View Account section
- [ ] **EXPECTED**: Shows:
  - User avatar with first letter of email
  - User email address
  - "Logged in" subtitle
- [ ] **TEST**: Tap "Logout"
- [ ] **EXPECTED**: Confirmation dialog: "Are you sure you want to logout?"
- [ ] **TEST**: Tap "Cancel"
- [ ] **EXPECTED**: Dialog closes, user still logged in
- [ ] **TEST**: Tap "Logout" again and confirm
- [ ] **EXPECTED**: User logged out
- [ ] **EXPECTED**: Redirected to Auth screen

#### 3.4 Cache Statistics
- [ ] **TEST**: Scan several products (some with barcodes)
- [ ] **TEST**: Scan same barcode twice
- [ ] **TEST**: Go to Settings > Cache Management
- [ ] **EXPECTED**: Cache Statistics shows:
  - Total entries count
  - Valid entries count
  - Expired entries count
  - Hit Rate percentage

#### 3.5 Clear Expired Cache
- [ ] **TEST**: Tap "Clear Expired Cache"
- [ ] **EXPECTED**: Expired entries removed
- [ ] **EXPECTED**: Green snackbar: "Expired cache entries removed"
- [ ] **EXPECTED**: Statistics update (expired count = 0)

#### 3.6 Clear All Cache
- [ ] **TEST**: Tap "Clear All Cache"
- [ ] **EXPECTED**: Confirmation dialog with warning about slower future scans
- [ ] **TEST**: Tap "Cancel"
- [ ] **EXPECTED**: Cache unchanged
- [ ] **TEST**: Tap "Clear All Cache" again and confirm
- [ ] **EXPECTED**: All cache cleared
- [ ] **EXPECTED**: Green snackbar: "Cache cleared successfully"
- [ ] **EXPECTED**: Statistics show 0 entries
- [ ] **TEST**: Scan same barcode again
- [ ] **EXPECTED**: Takes longer (no cache hit)

#### 3.7 About Section
- [ ] **TEST**: Scroll to About section
- [ ] **EXPECTED**: Shows:
  - Version: 1.0.0+1
  - Report an Issue
  - Privacy Policy
  - Terms of Service

---

### 4. Cache Integration Tests

#### 4.1 Cache Hit
- [ ] **TEST**: Scan a product with a barcode
- [ ] **EXPECTED**: Analysis completes normally
- [ ] **TEST**: Immediately scan the same barcode again
- [ ] **EXPECTED**: Blue snackbar: "Using cached result (faster!)"
- [ ] **EXPECTED**: Analysis completes much faster
- [ ] **EXPECTED**: Results are identical (market price, etc.)

#### 4.2 Cache Miss
- [ ] **TEST**: Scan a product without a barcode
- [ ] **EXPECTED**: No caching occurs (requires full analysis each time)
- [ ] **TEST**: Scan a new barcode never scanned before
- [ ] **EXPECTED**: Full analysis occurs
- [ ] **EXPECTED**: Result cached for future

#### 4.3 Cache Expiration
- [ ] **TEST**: Scan a product and note the time
- [ ] **TEST**: Wait 24+ hours (or modify cache duration in code for testing)
- [ ] **TEST**: Scan same barcode again
- [ ] **EXPECTED**: Cache expired, full analysis occurs
- [ ] **EXPECTED**: New result cached

---

### 5. Integration Tests

#### 5.1 Complete Workflow - Online
1. [ ] Log in to app
2. [ ] Scan a product with barcode → Should analyze normally
3. [ ] Go to History → Should see the scan
4. [ ] Scan same barcode → Should use cache
5. [ ] Go to History → Should see both scans
6. [ ] Filter by BUY → Should show only BUY scans
7. [ ] Export to CSV → Should export filtered scans
8. [ ] Delete a scan → Should remove from list
9. [ ] Go to Settings → Should see cache statistics
10. [ ] Clear cache → Should reset statistics
11. [ ] Scan same barcode → Should take longer (cache cleared)

#### 5.2 Complete Workflow - Offline
1. [ ] Log in to app
2. [ ] Disable network
3. [ ] Go to Settings → Should see orange offline banner
4. [ ] Scan a product → Should queue the scan
5. [ ] Go to Settings > Offline Queue → Should see 1 queued scan
6. [ ] Scan another product → Should queue it
7. [ ] View Queued Scans → Should see 2 scans
8. [ ] Enable network
9. [ ] Wait for auto-retry or manually retry
10. [ ] Go to History → Should see both scans saved
11. [ ] Check Offline Queue → Should be empty

#### 5.3 Network Toggle During Scan
- [ ] **TEST**: Start scanning a product
- [ ] **TEST**: Disable network while analysis is in progress
- [ ] **EXPECTED**: Analysis completes but save fails
- [ ] **EXPECTED**: Scan queued automatically
- [ ] **TEST**: Enable network
- [ ] **EXPECTED**: Scan saved automatically

---

## Performance Checks

### Cache Performance
- [ ] First scan with barcode: Time how long analysis takes
- [ ] Second scan with same barcode: Should be 60-80% faster
- [ ] Expected: ~1-2 seconds for cached vs ~5-10 seconds for fresh

### Offline Queue Performance
- [ ] Queue 10 scans while offline
- [ ] Enable network
- [ ] All 10 should save within 30 seconds

### UI Responsiveness
- [ ] Scrolling through 100+ scans in History should be smooth
- [ ] Search should filter instantly as you type
- [ ] Swipe-to-delete should be fluid

---

## Edge Cases

### 1. Empty History
- [ ] New user with no scans → Should show empty state

### 2. Network Flapping
- [ ] Toggle network on/off rapidly → App should handle gracefully

### 3. Large Queue
- [ ] Queue 50+ scans → Should handle without crashing

### 4. Invalid Barcode
- [ ] Scan product with invalid/unknown barcode → Should still work

### 5. Database Errors
- [ ] Simulate DB error → Should show error message with retry

---

## Known Limitations / TODOs

1. **Export to CSV**: Currently shows in dialog. Future: Save to file and share
2. **URL Launcher**: Marketplace links in history details need implementation
3. **Undo Delete**: Currently no undo for deleted scans (requires implementation)
4. **Cache by Product Name**: Currently only caches by barcode (product name caching exists in service but not used in UI)

---

## Success Criteria

✅ All scans appear in History screen
✅ Filters, search, and sort work correctly
✅ Swipe-to-delete removes scans from database
✅ Export generates valid CSV
✅ Offline scans are queued and retried automatically
✅ Cache speeds up repeat scans significantly
✅ Settings provide full control over cache and queue
✅ No crashes or UI freezes during normal use
✅ Network status changes detected and handled properly

---

## Reporting Issues

If you encounter bugs or unexpected behavior:

1. Note the exact steps to reproduce
2. Include any error messages or snackbars shown
3. Check the console/logs for debugging output
4. Take screenshots if UI issue
5. Note your platform (Android/iOS/Web) and Flutter version

## Testing Checklist Summary

- [ ] **History Screen**: All 11 test scenarios pass
- [ ] **Offline Support**: All 7 test scenarios pass
- [ ] **Settings Screen**: All 7 test scenarios pass
- [ ] **Cache Integration**: All 3 test scenarios pass
- [ ] **Integration**: All 3 workflows complete successfully
- [ ] **Performance**: Meets performance expectations
- [ ] **Edge Cases**: All 5 edge cases handled

---

**Happy Testing! 🚀**
