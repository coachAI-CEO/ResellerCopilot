# Reseller Copilot - Comprehensive Improvement Recommendations

**Document Version:** 1.0
**Date:** 2026-01-21
**Reviewed By:** Claude Code Analysis

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Critical Issues](#1-critical-issues-)
3. [Performance Optimizations](#2-performance-optimizations-)
4. [UI/UX Improvements](#3-uiux-improvements-)
5. [Missing Features](#4-missing-features-)
6. [Code Quality](#5-code-quality-)
7. [Security Enhancements](#6-security-enhancements-)
8. [Backend Improvements](#7-backend-improvements-)
9. [DevOps & Deployment](#8-devops--deployment-)
10. [Documentation](#9-documentation-)
11. [Web Application - Research & Marketplace Management](#10-web-application---research--marketplace-management-)
12. [Priority Matrix](#priority-matrix)
13. [Quick Wins](#quick-wins)

---

## Executive Summary

The Reseller Copilot is a well-structured mobile application with a solid foundation. This document outlines **89 specific recommendations** for the mobile app plus a comprehensive **Web Application architecture** for research and marketplace management.

**Mobile App - Key Findings:**
- ✅ Strong foundation with proper authentication, AI integration, and data persistence
- ⚠️ Monolithic UI component (957 lines) needs refactoring
- ⚠️ No testing infrastructure in place
- ⚠️ Missing critical UX features (history, offline support, sharing)
- ⚠️ Performance optimization opportunities (caching, image handling)
- ⚠️ Limited accessibility and mobile-first UX patterns

**Web App - Vision:**
- 🌐 Companion platform for pre-purchase research and post-purchase workflow
- 📊 Trending products discovery and market research
- 📦 Inventory management from scan to sale
- 🤖 AI-powered marketplace listing generation
- 🔄 Multi-marketplace publishing (eBay, Amazon, Poshmark, Mercari)
- 📈 Comprehensive analytics and profitability tracking

---

## 1. Critical Issues 🚨

### 1.1 Testing Infrastructure

**Current State:** Only default widget_test.dart exists - no actual tests written

**Impact:** High risk of regressions, difficult to maintain and refactor safely

**Recommendations:**

#### Unit Tests
```dart
// test/services/supabase_service_test.dart
// Target: Test all public methods
- analyzeItem() with valid/invalid inputs
- saveScan() success/failure scenarios
- getScans() with various filters
- Image compression logic
- Error handling for network failures
```

#### Widget Tests
```dart
// test/screens/scanner_screen_test.dart
- Image picker interaction
- Form validation (price, barcode)
- Condition selection
- Result display with various data states
- Error state handling

// test/screens/auth_screen_test.dart
- Login/signup toggle
- Form validation
- Error message display
- Loading states
```

#### Integration Tests
```dart
// integration_test/app_test.dart
- Complete scan workflow: auth → photo → analyze → save → display
- Offline scenario handling
- Session persistence
```

**Target:** Minimum 70% code coverage

**Files Affected:**
- Create: `test/services/supabase_service_test.dart`
- Create: `test/screens/scanner_screen_test.dart`
- Create: `test/screens/auth_screen_test.dart`
- Create: `integration_test/app_test.dart`

---

### 1.2 Code Organization - Monolithic Scanner Screen

**Current State:** `scanner_screen.dart` is 957 lines with mixed UI and business logic

**Impact:** Hard to maintain, test, and reuse components

**Recommendations:**

#### Extract Reusable Widgets

```
lib/
  widgets/
    scanner/
      product_image_widget.dart        (lines 336-436 → ~100 lines)
      verdict_card.dart                (lines 318-627 → ~150 lines)
      market_analysis_card.dart        (lines 629-661 → ~80 lines)
      profit_calculation_card.dart     (lines 555-624 → ~70 lines)
      price_input_field.dart           (lines 224-237 → ~50 lines)
      condition_selector.dart          (lines 255-288 → ~80 lines)
      camera_preview_widget.dart       (lines 168-208 → ~60 lines)
    common/
      info_row.dart                    (lines 751-892 → ~140 lines)
      calculation_row.dart             (lines 894-918 → ~25 lines)
```

#### Extract Business Logic

```dart
// lib/controllers/scanner_controller.dart
class ScannerController extends ChangeNotifier {
  // State management
  // Image handling logic
  // Analysis coordination
  // Error handling
}
```

**Expected Outcome:**
- `scanner_screen.dart`: 957 → ~200 lines
- Better testability
- Reusable components across future screens

---

### 1.3 State Management Migration

**Current State:** Using `setState()` throughout; Riverpod installed but unused

**Impact:** Difficult to test, share state, and manage complex state transitions

**Recommendations:**

#### Create Providers

```dart
// lib/providers/auth_provider.dart
final authProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange
    .map((event) => event.session?.user);
});

// lib/providers/scan_provider.dart
final currentScanProvider = StateNotifierProvider<ScanNotifier, AsyncValue<ScanResult?>>(...);

final scanHistoryProvider = FutureProvider.autoDispose<List<ScanResult>>(...);

// lib/providers/camera_provider.dart
final cameraStateProvider = StateNotifierProvider<CameraNotifier, CameraState>(...);
```

#### Refactor Scanner Screen

```dart
class ScannerScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(currentScanProvider);
    final authState = ref.watch(authProvider);

    // Reactive UI based on provider state
  }
}
```

**Benefits:**
- Centralized state management
- Easy testing with provider overrides
- Better separation of concerns
- Built-in async state handling

---

## 2. Performance Optimizations ⚡

### 2.1 Image Handling

#### Issue: No Compression on Web
**File:** `lib/services/supabase_service.dart:67`

```dart
// Current: Web images not compressed
if (kIsWeb) {
  // No compression applied
}
```

**Recommendation:**
```dart
// Add web-compatible compression
import 'package:image/image.dart' as img;

Future<Uint8List> _compressImage(Uint8List bytes) async {
  final image = img.decodeImage(bytes);
  if (image == null) return bytes;

  // Resize if too large
  final resized = img.copyResize(image, width: 1024);

  // Compress as JPEG
  return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
}
```

#### Issue: Synchronous URL Validation Blocks Response
**File:** `supabase/functions/analyze-product/index.ts:401-421`

**Current:** Makes blocking network requests to validate URLs before returning response

**Recommendation:**
```typescript
// Option 1: Remove validation entirely (most URLs work)
// Option 2: Validate asynchronously in background
// Option 3: Use simple regex validation (no network calls)

// Preferred approach:
function isValidUrl(url: string): boolean {
  try {
    new URL(url);
    return url.startsWith('http');
  } catch {
    return false;
  }
}
```

#### Issue: Missing Image Size Limits

**Recommendation:**
```dart
// Add validation before analysis
const maxImageSize = 5 * 1024 * 1024; // 5MB
if (imageBytes.length > maxImageSize) {
  throw Exception('Image too large. Maximum size is 5MB');
}
```

---

### 2.2 Caching Implementation

**Current State:** Every scan calls expensive AI API, even for identical products

**Impact:** Unnecessary costs, slow performance for repeat scans

**Recommendations:**

#### Client-Side Caching

```dart
// lib/services/cache_service.dart
import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const _boxName = 'scan_cache';
  static const _cacheDuration = Duration(hours: 24);

  Future<ScanResult?> getCachedResult(String barcode) async {
    final box = await Hive.openBox<CachedScan>(_boxName);
    final cached = box.get(barcode);

    if (cached == null) return null;
    if (DateTime.now().difference(cached.timestamp) > _cacheDuration) {
      await box.delete(barcode);
      return null;
    }

    return cached.result;
  }

  Future<void> cacheResult(String barcode, ScanResult result) async {
    final box = await Hive.openBox<CachedScan>(_boxName);
    await box.put(barcode, CachedScan(
      timestamp: DateTime.now(),
      result: result,
    ));
  }
}
```

#### Server-Side Caching

```typescript
// supabase/functions/analyze-product/index.ts
import { Redis } from '@upstash/redis';

const redis = new Redis({...});
const CACHE_TTL = 24 * 60 * 60; // 24 hours

// Before calling Gemini API:
const cacheKey = `product:${barcode}:${condition}`;
const cached = await redis.get(cacheKey);
if (cached) {
  console.log('Cache hit:', cacheKey);
  return cached;
}

// After getting result:
await redis.setex(cacheKey, CACHE_TTL, result);
```

**Expected Impact:**
- 60-80% reduction in API calls for common products
- Instant results for cached items
- Significant cost savings

---

### 2.3 Database Performance

**Current State:** No indexes on frequently queried columns

**Recommendations:**

```sql
-- Create migration: 009_add_performance_indexes.sql

-- Index for user scans query (most common)
CREATE INDEX idx_scans_user_id_created_at
ON scans(user_id, created_at DESC);

-- Index for barcode lookups
CREATE INDEX idx_scans_barcode
ON scans(barcode)
WHERE barcode IS NOT NULL;

-- Index for verdict filtering
CREATE INDEX idx_scans_verdict
ON scans(verdict);

-- Index for profit range queries
CREATE INDEX idx_scans_net_profit
ON scans(net_profit DESC);

-- Composite index for common filters
CREATE INDEX idx_scans_user_verdict_profit
ON scans(user_id, verdict, net_profit DESC);
```

**Expected Impact:**
- 10-100x faster queries on scan history
- Better performance as data grows

---

## 3. UI/UX Improvements 🎨

### 3.1 Navigation & Information Architecture

#### Issue: Single-Screen App with No Navigation
**Current:** Everything happens on one screen; no way to access history or settings

**Recommendations:**

```dart
// Add bottom navigation bar
BottomNavigationBar(
  items: [
    BottomNavigationBarItem(
      icon: Icon(Icons.camera_alt),
      label: 'Scan',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history),
      label: 'History',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ],
)
```

**New Screens to Add:**
1. **History Screen** - View past scans
2. **Settings Screen** - Configure preferences
3. **Product Detail Screen** - Expanded view of scan results
4. **Comparison Screen** - Compare multiple products side-by-side

---

### 3.2 Scanner Screen UX Improvements

#### 3.2.1 Image Source Options

**Current:** Only camera available (line 41-44)

**Recommendation:**
```dart
// Add bottom sheet for image source selection
void _showImageSourceOptions() {
  showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text('Take Photo'),
            onTap: () => _pickImage(ImageSource.camera),
          ),
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Choose from Gallery'),
            onTap: () => _pickImage(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
}
```

**Benefits:**
- Test products at home using existing photos
- Easier to test in low-light environments

---

#### 3.2.2 Barcode Scanner Integration

**Current:** Manual barcode entry only (line 241-252)

**Recommendation:**
```dart
// Add dependencies: mobile_scanner: ^3.5.5

import 'package:mobile_scanner/mobile_scanner.dart';

// Add scanner button
IconButton(
  icon: Icon(Icons.qr_code_scanner),
  onPressed: _scanBarcode,
)

Future<void> _scanBarcode() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => BarcodeScannerScreen(),
    ),
  );

  if (result != null) {
    setState(() => _barcode = result);
  }
}
```

**Benefits:**
- Faster, more accurate barcode entry
- Better UX for high-volume scanning

---

#### 3.2.3 Quick Actions & Workflows

**Current:** Results disappear when taking new photo; must re-enter all data

**Recommendation:**

```dart
// Add floating action button after successful scan
if (_scanResult != null)
  FloatingActionButton.extended(
    onPressed: _scanAnother,
    icon: Icon(Icons.add_a_photo),
    label: Text('Scan Another'),
  )

void _scanAnother() {
  // Keep price, condition
  // Only clear image and result
  setState(() {
    _selectedImage = null;
    _selectedImageBytes = null;
    _scanResult = null;
  });
  _pickImage();
}
```

**Additional Quick Actions:**
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    ElevatedButton.icon(
      icon: Icon(Icons.share),
      label: Text('Share'),
      onPressed: _shareResult,
    ),
    ElevatedButton.icon(
      icon: Icon(Icons.compare_arrows),
      label: Text('Compare'),
      onPressed: _addToComparison,
    ),
    ElevatedButton.icon(
      icon: Icon(Icons.refresh),
      label: Text('Retry'),
      onPressed: _retryAnalysis,
    ),
  ],
)
```

---

#### 3.2.4 Results Display Improvements

**Current Issues:**
- Long scrolling required to see all information
- No quick summary view
- Important metrics buried in details

**Recommendation: Collapsible Sections**

```dart
// Sticky summary at top
Container(
  color: verdict == 'BUY' ? Colors.green : Colors.orange,
  padding: EdgeInsets.all(16),
  child: Column(
    children: [
      // Large verdict
      Text(verdict, style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
      // Key metrics row
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetric('Profit', '\$${netProfit}'),
          _buildMetric('ROI', '${roi}%'),
          _buildMetric('Velocity', velocityScore),
        ],
      ),
    ],
  ),
)

// Expandable sections
ExpansionTile(
  title: Text('Profit Breakdown'),
  children: [/* detailed calculation */],
)
ExpansionTile(
  title: Text('Market Analysis'),
  children: [/* full analysis */],
)
ExpansionTile(
  title: Text('Marketplace Prices'),
  children: [/* eBay, Amazon links */],
)
```

**Add Missing Metrics:**
```dart
// ROI Percentage
final roi = ((marketPrice - buyPrice) / buyPrice * 100).toStringAsFixed(1);

// Break-even timeline
final daysToSell = velocityScore == 'High' ? 7 : velocityScore == 'Med' ? 30 : 90;
final monthlyProfit = (30 / daysToSell) * netProfit;
```

---

#### 3.2.5 Input Improvements

**Current Issues:**
- Small condition buttons (line 276-283)
- No visual feedback on selection
- No keyboard shortcuts or quick entry

**Recommendation:**

```dart
// Larger, more accessible condition selector
Container(
  height: 80,
  child: ListView(
    scrollDirection: Axis.horizontal,
    children: [
      _buildConditionCard('Used', Icons.shopping_bag,
        'Pre-owned, shows wear'),
      _buildConditionCard('New', Icons.new_releases,
        'Unused, may lack packaging'),
      _buildConditionCard('New in Box', Icons.inventory_2,
        'Factory sealed, pristine'),
    ],
  ),
)

Widget _buildConditionCard(String label, IconData icon, String description) {
  final isSelected = _condition == label;
  return Card(
    elevation: isSelected ? 8 : 2,
    color: isSelected ? Colors.blue.shade100 : Colors.white,
    child: InkWell(
      onTap: () => setState(() => _condition = label),
      child: Container(
        width: 140,
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? Colors.blue : Colors.grey),
            SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(description, style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    ),
  );
}
```

**Price Input Enhancements:**
```dart
// Add preset price buttons for common values
Wrap(
  spacing: 8,
  children: [
    for (final price in [5.99, 9.99, 14.99, 19.99, 29.99])
      ActionChip(
        label: Text('\$$price'),
        onPressed: () => _priceController.text = price.toString(),
      ),
  ],
)

// Add voice input option
IconButton(
  icon: Icon(Icons.mic),
  onPressed: _startVoiceInput,
)
```

---

### 3.3 Authentication Screen Improvements

**Current Issues:**
- No password visibility toggle
- No "Forgot Password" option
- Generic error messages
- No social authentication

**Recommendations:**

#### Password Visibility Toggle
```dart
// Add to password field
bool _obscurePassword = true;

TextFormField(
  obscureText: _obscurePassword,
  decoration: InputDecoration(
    suffixIcon: IconButton(
      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
    ),
  ),
)
```

#### Forgot Password Flow
```dart
TextButton(
  onPressed: _showForgotPasswordDialog,
  child: Text('Forgot Password?'),
)

Future<void> _showForgotPasswordDialog() async {
  final email = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Reset Password'),
      content: TextField(
        decoration: InputDecoration(hintText: 'Enter your email'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _emailController.text),
          child: Text('Send Reset Link'),
        ),
      ],
    ),
  );

  if (email != null) {
    await Supabase.instance.client.auth.resetPasswordForEmail(email);
    // Show success message
  }
}
```

#### Better Error Messages
```dart
// Instead of generic "Authentication error: ..."
String _getUserFriendlyError(AuthException e) {
  switch (e.statusCode) {
    case '400':
      if (e.message.contains('email')) {
        return 'Please enter a valid email address';
      }
      if (e.message.contains('password')) {
        return 'Password must be at least 6 characters';
      }
      return 'Invalid input. Please check your credentials.';
    case '401':
      return 'Incorrect email or password. Please try again.';
    case '422':
      return 'This email is already registered. Try logging in instead.';
    case '429':
      return 'Too many attempts. Please wait a few minutes and try again.';
    default:
      return 'Unable to connect. Please check your internet connection.';
  }
}
```

---

### 3.4 Visual Design Improvements

#### 3.4.1 Color System & Theming

**Current:** Hard-coded colors throughout (Colors.blue.shade700, etc.)

**Recommendation:**
```dart
// lib/theme/app_theme.dart
class AppTheme {
  static const _primaryColor = Color(0xFF1976D2);
  static const _successColor = Color(0xFF2E7D32);
  static const _warningColor = Color(0xFFF57C00);
  static const _errorColor = Color(0xFFD32F2F);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
    ),
    // ... dark theme specifics
  );
}
```

#### 3.4.2 Typography Consistency

```dart
// lib/theme/app_text_styles.dart
class AppTextStyles {
  static const headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static const headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  static const bodyLarge = TextStyle(
    fontSize: 16,
    height: 1.5,
  );

  static const caption = TextStyle(
    fontSize: 12,
    color: Colors.grey,
    height: 1.4,
  );
}
```

#### 3.4.3 Spacing System

```dart
// lib/theme/app_spacing.dart
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}
```

---

### 3.5 Loading States & Feedback

#### 3.5.1 Better Loading Indicators

**Current:** Generic circular progress indicator

**Recommendation:**
```dart
// Animated loading with context
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Lottie.asset('assets/animations/analyzing.json'), // or custom animation
    SizedBox(height: 16),
    Text('Analyzing product...', style: TextStyle(fontSize: 18)),
    SizedBox(height: 8),
    LinearProgressIndicator(),
    SizedBox(height: 8),
    Text(
      _loadingMessage,
      style: TextStyle(fontSize: 14, color: Colors.grey),
    ),
  ],
)

// Rotate through messages
final _loadingMessages = [
  'Searching eBay listings...',
  'Checking Amazon prices...',
  'Analyzing market trends...',
  'Calculating profitability...',
];
```

#### 3.5.2 Skeleton Loaders

```dart
// While loading images
Shimmer.fromColors(
  baseColor: Colors.grey[300]!,
  highlightColor: Colors.grey[100]!,
  child: Container(
    width: double.infinity,
    height: 200,
    color: Colors.white,
  ),
)
```

#### 3.5.3 Empty States

```dart
// When no scan results
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.camera_alt, size: 120, color: Colors.grey[300]),
      SizedBox(height: 24),
      Text(
        'Ready to scan',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 8),
      Text(
        'Take a photo of a product to analyze profitability',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
      SizedBox(height: 32),
      ElevatedButton.icon(
        icon: Icon(Icons.camera_alt),
        label: Text('Start Scanning'),
        onPressed: _pickImage,
      ),
    ],
  ),
)
```

---

### 3.6 Accessibility Improvements

#### 3.6.1 Semantic Labels

```dart
Semantics(
  label: 'Product verdict: ${_scanResult.verdict}. Net profit: \$${_scanResult.netProfit}',
  child: VerdictCard(...),
)
```

#### 3.6.2 Keyboard Navigation

```dart
// Add focus nodes and shortcuts
final _priceFocusNode = FocusNode();
final _barcodeFocusNode = FocusNode();

// Shortcuts for power users
Shortcuts(
  shortcuts: {
    LogicalKeySet(LogicalKeyboardKey.enter): SubmitIntent(),
    LogicalKeySet(LogicalKeyboardKey.escape): ClearIntent(),
  },
  child: Actions(
    actions: {
      SubmitIntent: CallbackAction(onInvoke: (_) => _scanProduct()),
      ClearIntent: CallbackAction(onInvoke: (_) => _clearForm()),
    },
    child: child,
  ),
)
```

#### 3.6.3 Contrast & Font Sizing

```dart
// Ensure AA/AAA contrast ratios
// Use theme.textTheme for responsive font sizes
Text(
  'Verdict',
  style: Theme.of(context).textTheme.headlineMedium,
  // Automatically respects user's system font size settings
)
```

---

### 3.7 Mobile-First UX Patterns

#### 3.7.1 Pull-to-Refresh

```dart
RefreshIndicator(
  onRefresh: () async {
    // Re-analyze current product or refresh history
    await _scanProduct();
  },
  child: SingleChildScrollView(...),
)
```

#### 3.7.2 Swipe Gestures

```dart
// Swipe to delete in history
Dismissible(
  key: Key(scan.id),
  direction: DismissDirection.endToStart,
  background: Container(
    color: Colors.red,
    alignment: Alignment.centerRight,
    padding: EdgeInsets.only(right: 16),
    child: Icon(Icons.delete, color: Colors.white),
  ),
  onDismissed: (direction) => _deleteScan(scan),
  child: ScanHistoryCard(scan),
)
```

#### 3.7.3 Bottom Sheets for Actions

```dart
// Replace dialogs with bottom sheets on mobile
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  builder: (context) => DraggableScrollableSheet(...),
)
```

---

### 3.8 Onboarding & Help

#### 3.8.1 First-Time User Experience

```dart
// Show tutorial on first launch
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

void _showTutorial() {
  TutorialCoachMark(
    targets: [
      TargetFocus(
        identify: 'camera_button',
        contents: [
          TargetContent(
            child: Text('Tap here to take a photo of the product'),
          ),
        ],
      ),
      TargetFocus(
        identify: 'price_input',
        contents: [
          TargetContent(
            child: Text('Enter the store price you see on the tag'),
          ),
        ],
      ),
      // ... more steps
    ],
  ).show(context: context);
}
```

#### 3.8.2 Contextual Help

```dart
// Help icon in app bar
IconButton(
  icon: Icon(Icons.help_outline),
  onPressed: () => _showHelp(),
)

// Tooltips on complex features
Tooltip(
  message: 'Velocity indicates how quickly this item typically sells',
  triggerMode: TooltipTriggerMode.tap,
  showDuration: Duration(seconds: 5),
  child: Icon(Icons.info_outline),
)
```

---

## 4. Missing Features 🎯

### 4.1 Scan History Screen

**Current State:** `getScans()` exists in service but never used (lib/services/supabase_service.dart:270)

**Implementation:**

```dart
// lib/screens/history_screen.dart
class HistoryScreen extends StatefulWidget {
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScanResult> _scans = [];
  bool _isLoading = true;
  String _sortBy = 'date'; // date, profit, name
  String _filterBy = 'all'; // all, buy, pass

  @override
  void initState() {
    super.initState();
    _loadScans();
  }

  Future<void> _loadScans() async {
    setState(() => _isLoading = true);
    final scans = await widget.supabaseService.getScans();
    setState(() {
      _scans = scans;
      _applyFiltersAndSort();
      _isLoading = false;
    });
  }

  void _applyFiltersAndSort() {
    var filtered = _scans;

    // Filter
    if (_filterBy != 'all') {
      filtered = filtered.where((s) =>
        s.verdict.toLowerCase() == _filterBy.toLowerCase()
      ).toList();
    }

    // Sort
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'profit':
          return b.netProfit.compareTo(a.netProfit);
        case 'name':
          return a.productName.compareTo(b.productName);
        case 'date':
        default:
          return b.createdAt!.compareTo(a.createdAt!);
      }
    });

    setState(() => _scans = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan History'),
        actions: [
          // Search
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _showSearch,
          ),
          // Filter
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filterBy = value);
              _applyFiltersAndSort();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'all', child: Text('All Items')),
              PopupMenuItem(value: 'buy', child: Text('Buy Only')),
              PopupMenuItem(value: 'pass', child: Text('Pass Only')),
            ],
          ),
          // Sort
          PopupMenuButton<String>(
            icon: Icon(Icons.sort),
            onSelected: (value) {
              setState(() => _sortBy = value);
              _applyFiltersAndSort();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'date', child: Text('Date')),
              PopupMenuItem(value: 'profit', child: Text('Profit')),
              PopupMenuItem(value: 'name', child: Text('Name')),
            ],
          ),
          // Export
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _exportToCsv,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _scans.isEmpty
              ? _buildEmptyState()
              : _buildHistoryList(),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      itemCount: _scans.length,
      itemBuilder: (context, index) {
        final scan = _scans[index];
        return ScanHistoryCard(
          scan: scan,
          onTap: () => _viewDetails(scan),
          onDelete: () => _deleteScan(scan),
        );
      },
    );
  }

  Future<void> _exportToCsv() async {
    final csv = const ListToCsvConverter().convert([
      ['Date', 'Product', 'Buy Price', 'Sell Price', 'Profit', 'Verdict'],
      ..._scans.map((s) => [
        s.createdAt?.toIso8601String(),
        s.productName,
        s.buyPrice,
        s.marketPrice,
        s.netProfit,
        s.verdict,
      ]),
    ]);

    // Save and share CSV
    final file = await _saveFile('scan_history.csv', csv);
    await Share.shareXFiles([XFile(file.path)]);
  }
}
```

**Features:**
- View all past scans
- Search by product name
- Filter by verdict (BUY/PASS)
- Sort by date, profit, or name
- Swipe to delete
- Export to CSV
- Tap to view full details

---

### 4.2 Offline Support

**Current State:** App completely unusable without internet

**Implementation:**

```dart
// lib/services/offline_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

class OfflineService {
  static const _queueBox = 'pending_scans';

  // Queue failed scans for retry
  Future<void> queueScan(PendingScan scan) async {
    final box = await Hive.openBox<PendingScan>(_queueBox);
    await box.add(scan);
  }

  // Retry queued scans when online
  Future<void> processQueue(SupabaseService service) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;

    final box = await Hive.openBox<PendingScan>(_queueBox);
    for (final scan in box.values) {
      try {
        await service.analyzeItem(
          imageBytes: scan.imageBytes,
          barcode: scan.barcode,
          price: scan.price,
          condition: scan.condition,
        );
        await box.delete(scan.key);
      } catch (e) {
        // Keep in queue, try again later
      }
    }
  }

  // Listen for connectivity changes
  void startConnectivityListener(SupabaseService service) {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        processQueue(service);
      }
    });
  }
}

// Update scanner_screen.dart
catch (e) {
  if (e.toString().contains('network')) {
    await OfflineService().queueScan(PendingScan(...));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved for later. Will analyze when online.'),
        action: SnackBarAction(
          label: 'View Queue',
          onPressed: () => Navigator.push(...),
        ),
      ),
    );
  }
}
```

**Features:**
- Cache authentication state
- Queue failed scans
- Auto-retry when connection restored
- View pending queue
- Show cached scan history offline

---

### 4.3 Product Comparison

**Implementation:**

```dart
// lib/screens/comparison_screen.dart
class ComparisonScreen extends StatefulWidget {
  final List<ScanResult> products;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Compare Products')),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: products.map((product) =>
            Container(
              width: 300,
              child: ProductComparisonCard(product),
            ),
          ).toList(),
        ),
      ),
    );
  }
}

// Comparison table view
DataTable(
  columns: [
    DataColumn(label: Text('Metric')),
    ...products.map((p) => DataColumn(label: Text(p.productName))),
  ],
  rows: [
    DataRow(cells: [
      DataCell(Text('Buy Price')),
      ...products.map((p) => DataCell(Text('\$${p.buyPrice}'))),
    ]),
    DataRow(cells: [
      DataCell(Text('Sell Price')),
      ...products.map((p) => DataCell(Text('\$${p.marketPrice}'))),
    ]),
    DataRow(cells: [
      DataCell(Text('Net Profit')),
      ...products.map((p) => DataCell(Text('\$${p.netProfit}'))),
    ]),
    DataRow(cells: [
      DataCell(Text('ROI')),
      ...products.map((p) => DataCell(Text('${p.roi}%'))),
    ]),
    DataRow(cells: [
      DataCell(Text('Velocity')),
      ...products.map((p) => DataCell(Text(p.velocityScore))),
    ]),
  ],
)
```

---

### 4.4 Batch Scanning Mode

**Implementation:**

```dart
// lib/screens/batch_scan_screen.dart
class BatchScanScreen extends StatefulWidget {
  @override
  State<BatchScanScreen> createState() => _BatchScanScreenState();
}

class _BatchScanScreenState extends State<BatchScanScreen> {
  List<PendingScan> _scans = [];
  List<ScanResult> _results = [];
  bool _isAnalyzing = false;

  void _addScan() async {
    final image = await _pickImage();
    final price = await _showPriceDialog();

    setState(() {
      _scans.add(PendingScan(
        image: image,
        price: price,
        condition: _defaultCondition,
      ));
    });
  }

  Future<void> _analyzeAll() async {
    setState(() => _isAnalyzing = true);

    for (final scan in _scans) {
      final result = await widget.supabaseService.analyzeItem(
        imageBytes: scan.image,
        price: scan.price,
        condition: scan.condition,
      );
      setState(() => _results.add(result));
    }

    setState(() => _isAnalyzing = false);
    _showSummary();
  }

  void _showSummary() {
    final totalProfit = _results.fold(0.0, (sum, r) => sum + r.netProfit);
    final buyCount = _results.where((r) => r.verdict == 'BUY').length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Batch Analysis Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Items Scanned: ${_results.length}'),
            Text('Items to Buy: $buyCount'),
            Text('Total Profit: \$${totalProfit.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}
```

---

### 4.5 Settings & Preferences

**Implementation:**

```dart
// lib/screens/settings_screen.dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          _buildSection(
            'Profit Thresholds',
            [
              _buildSliderSetting(
                'Minimum Profit',
                '\$0 - \$100',
                (value) => _updateMinProfit(value),
              ),
              _buildSliderSetting(
                'Minimum ROI',
                '0% - 100%',
                (value) => _updateMinRoi(value),
              ),
            ],
          ),

          _buildSection(
            'Default Values',
            [
              _buildDropdownSetting(
                'Default Condition',
                ['Used', 'New', 'New in Box'],
                (value) => _updateDefaultCondition(value),
              ),
              _buildSwitchSetting(
                'Auto-analyze on photo',
                (value) => _updateAutoAnalyze(value),
              ),
            ],
          ),

          _buildSection(
            'Appearance',
            [
              _buildDropdownSetting(
                'Theme',
                ['Light', 'Dark', 'System'],
                (value) => _updateTheme(value),
              ),
              _buildSwitchSetting(
                'Compact Results View',
                (value) => _updateCompactView(value),
              ),
            ],
          ),

          _buildSection(
            'Advanced',
            [
              ListTile(
                title: Text('Clear Cache'),
                subtitle: Text('Delete cached product data'),
                trailing: Icon(Icons.delete_outline),
                onTap: _clearCache,
              ),
              ListTile(
                title: Text('Export All Data'),
                trailing: Icon(Icons.download),
                onTap: _exportAllData,
              ),
            ],
          ),

          _buildSection(
            'Account',
            [
              ListTile(
                title: Text('Change Password'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _changePassword,
              ),
              ListTile(
                title: Text('Delete Account'),
                textColor: Colors.red,
                trailing: Icon(Icons.warning, color: Colors.red),
                onTap: _deleteAccount,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## 5. Code Quality 📝

### 5.1 Magic Numbers & Constants

**Current Issues:** Hard-coded values throughout codebase

**File:** `lib/screens/scanner_screen.dart`
- Line 169: `height: 300` (image preview)
- Line 43: `imageQuality: 85`
- Multiple padding values: 16, 24, 12, 8, etc.

**Recommendation:**

```dart
// lib/constants/app_constants.dart
class AppConstants {
  // Image Settings
  static const double imagePreviewHeight = 300;
  static const int imageQuality = 85;
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB

  // Spacing
  static const double spacingXs = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXl = 32;

  // Border Radius
  static const double borderRadiusS = 8;
  static const double borderRadiusM = 12;
  static const double borderRadiusL = 16;

  // Durations
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration cacheDuration = Duration(hours: 24);
  static const Duration retryDelay = Duration(seconds: 2);

  // Business Logic
  static const double salesTaxRateDefault = 0.08; // 8%
  static const double platformFeeDefault = 0.15; // 15%
  static const double shippingCostDefault = 5.0;

  // Velocity Thresholds
  static const int velocityHighDays = 14;
  static const int velocityMedDays = 30;
  static const int velocityLowDays = 90;
}
```

**Usage:**
```dart
// Instead of:
Container(height: 300, ...)

// Use:
Container(height: AppConstants.imagePreviewHeight, ...)
```

---

### 5.2 Error Handling

**Current Issues:** Inconsistent error handling, generic messages

**Recommendation:**

```dart
// lib/models/app_exception.dart
abstract class AppException implements Exception {
  final String message;
  final String? details;
  final StackTrace? stackTrace;

  AppException(this.message, {this.details, this.stackTrace});

  String getUserMessage();
}

class NetworkException extends AppException {
  NetworkException([String? details])
    : super('Network error', details: details);

  @override
  String getUserMessage() =>
    'Unable to connect. Please check your internet connection.';
}

class AuthenticationException extends AppException {
  AuthenticationException([String? details])
    : super('Authentication failed', details: details);

  @override
  String getUserMessage() =>
    'Invalid credentials. Please check your email and password.';
}

class AIAnalysisException extends AppException {
  AIAnalysisException([String? details])
    : super('Analysis failed', details: details);

  @override
  String getUserMessage() =>
    'Unable to analyze product. Please try again or check the image quality.';
}

class RateLimitException extends AppException {
  final DateTime retryAfter;

  RateLimitException(this.retryAfter)
    : super('Rate limit exceeded');

  @override
  String getUserMessage() =>
    'Too many requests. Please try again in a few minutes.';
}
```

**Global Error Handler:**
```dart
// lib/utils/error_handler.dart
class ErrorHandler {
  static void handle(dynamic error, BuildContext context) {
    String message;
    SnackBarAction? action;

    if (error is AppException) {
      message = error.getUserMessage();

      // Log to error tracking service
      if (error is! NetworkException) {
        ErrorTracker.log(error, stackTrace: error.stackTrace);
      }
    } else if (error is SocketException) {
      message = 'No internet connection';
      action = SnackBarAction(
        label: 'Settings',
        onPressed: () => AppSettings.openWIFISettings(),
      );
    } else {
      message = 'An unexpected error occurred';
      ErrorTracker.log(error);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        action: action,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Usage in catch blocks:
catch (e, stackTrace) {
  ErrorHandler.handle(e, context);
}
```

---

### 5.3 Debug Logging

**Current Issue:** `debugPrint` everywhere - not production-ready

**Recommendation:**

```dart
// lib/utils/logger.dart
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void info(String message) {
    _logger.i(message);
  }

  static void warning(String message, [dynamic error]) {
    _logger.w(message, error: error);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);

    // Send to error tracking service in production
    if (kReleaseMode) {
      ErrorTracker.log(error ?? message, stackTrace: stackTrace);
    }
  }
}

// Usage:
AppLogger.info('User logged in: ${user.email}');
AppLogger.error('Failed to analyze product', error, stackTrace);
```

**Integration with Error Tracking:**

```dart
// lib/services/error_tracker.dart
import 'package:sentry_flutter/sentry_flutter.dart';

class ErrorTracker {
  static Future<void> initialize() async {
    await SentryFlutter.init(
      (options) {
        options.dsn = dotenv.env['SENTRY_DSN'];
        options.environment = kReleaseMode ? 'production' : 'development';
        options.tracesSampleRate = 0.1;
      },
    );
  }

  static void log(dynamic error, {StackTrace? stackTrace}) {
    Sentry.captureException(error, stackTrace: stackTrace);
  }

  static void logMessage(String message, {SentryLevel level = SentryLevel.info}) {
    Sentry.captureMessage(message, level: level);
  }

  static void setUser(String userId, String email) {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(id: userId, email: email));
    });
  }
}
```

---

## 6. Security Enhancements 🔒

### 6.1 Input Validation

**Current Issues:** Minimal client-side validation

**Recommendations:**

#### Price Validation
```dart
// lib/utils/validators.dart
class Validators {
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a price';
    }

    final price = double.tryParse(value);
    if (price == null) {
      return 'Please enter a valid number';
    }

    if (price <= 0) {
      return 'Price must be greater than 0';
    }

    if (price > 10000) {
      return 'Price seems unusually high. Please verify.';
    }

    // Check for too many decimal places
    if (value.contains('.') && value.split('.')[1].length > 2) {
      return 'Maximum 2 decimal places';
    }

    return null;
  }

  static String? validateBarcode(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    // Remove any spaces or dashes
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');

    // Common barcode formats: UPC (12), EAN (13), ISBN (10 or 13)
    if (!RegExp(r'^\d{8,13}$').hasMatch(cleaned)) {
      return 'Invalid barcode format';
    }

    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }

    // RFC 5322 simplified regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    return null;
  }
}
```

#### Input Sanitization
```dart
// lib/utils/sanitizer.dart
class Sanitizer {
  // Remove potentially dangerous characters before sending to API
  static String sanitizeText(String input) {
    return input
      .trim()
      .replaceAll(RegExp(r'[<>]'), '') // Remove HTML tags
      .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ''); // Remove control chars
  }

  // Sanitize image filename
  static String sanitizeFilename(String filename) {
    return filename
      .replaceAll(RegExp(r'[^\w\s.-]'), '')
      .replaceAll(RegExp(r'\s+'), '_');
  }
}
```

---

### 6.2 Environment Variables

**Current State:** Using flutter_dotenv (good), but can be improved

**Recommendations:**

#### Environment-Specific Configs

```dart
// lib/config/env_config.dart
enum Environment { development, staging, production }

class EnvConfig {
  static Environment get environment {
    const env = String.fromEnvironment('ENV', defaultValue: 'development');
    return Environment.values.firstWhere(
      (e) => e.name == env,
      orElse: () => Environment.development,
    );
  }

  static String get supabaseUrl {
    switch (environment) {
      case Environment.development:
        return dotenv.env['SUPABASE_URL_DEV']!;
      case Environment.staging:
        return dotenv.env['SUPABASE_URL_STAGING']!;
      case Environment.production:
        return dotenv.env['SUPABASE_URL_PROD']!;
    }
  }

  static String get supabaseAnonKey {
    switch (environment) {
      case Environment.development:
        return dotenv.env['SUPABASE_ANON_KEY_DEV']!;
      case Environment.staging:
        return dotenv.env['SUPABASE_ANON_KEY_STAGING']!;
      case Environment.production:
        return dotenv.env['SUPABASE_ANON_KEY_PROD']!;
    }
  }

  static bool get enableAnalytics => environment == Environment.production;
  static bool get enableCrashReporting => environment != Environment.development;
  static bool get enableDebugLogs => environment == Environment.development;
}
```

#### Startup Validation

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load env
  await dotenv.load(fileName: ".env");

  // Validate all required env vars
  final requiredVars = [
    'SUPABASE_URL',
    'SUPABASE_ANON_KEY',
  ];

  final missing = requiredVars.where((v) => dotenv.env[v] == null).toList();
  if (missing.isNotEmpty) {
    throw Exception('Missing environment variables: ${missing.join(', ')}');
  }

  // Initialize error tracking
  if (EnvConfig.enableCrashReporting) {
    await ErrorTracker.initialize();
  }

  runApp(const MyApp());
}
```

---

### 6.3 Secure Storage

**Recommendation:** Store sensitive data securely

```dart
// lib/services/secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Store auth tokens securely
  static Future<void> saveAuthToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> deleteAuthToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // User preferences that shouldn't be in plain text
  static Future<void> saveUserPreferences(Map<String, dynamic> prefs) async {
    await _storage.write(key: 'user_prefs', value: jsonEncode(prefs));
  }
}
```

---

## 7. Backend Improvements 🔧

### 7.1 Edge Function - Model Name Fix

**CRITICAL BUG**

**File:** `supabase/functions/analyze-product/index.ts:6`

**Current:**
```typescript
const MODEL_NAME = "gemini-3-flash-preview";
```

**Issue:** Wrong model name - should be "gemini-1.5-flash" or similar

**Fix:**
```typescript
// Use environment variable for flexibility
const MODEL_NAME = Deno.env.get("GEMINI_MODEL") || "gemini-1.5-flash";

// Or use the latest stable version:
const MODEL_NAME = "gemini-1.5-flash-002"; // Latest stable as of Jan 2026
```

---

### 7.2 API Timeout Configuration

**Current:** No timeout on Gemini API calls

**Recommendation:**
```typescript
// Add timeout to fetch calls
const controller = new AbortController();
const timeoutId = setTimeout(() => controller.abort(), 30000); // 30 second timeout

try {
  const response = await fetch(apiUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
    signal: controller.signal,
  });

  clearTimeout(timeoutId);

  // ... process response
} catch (error) {
  if (error.name === 'AbortError') {
    throw new Error('AI analysis timed out. Please try again.');
  }
  throw error;
}
```

---

### 7.3 Rate Limiting

**Current:** No rate limiting implemented

**Recommendation:**
```typescript
// supabase/functions/analyze-product/index.ts
import { Redis } from '@upstash/redis';

const redis = new Redis({...});

async function checkRateLimit(userId: string): Promise<void> {
  const key = `ratelimit:${userId}`;
  const limit = 10; // 10 requests
  const window = 60; // per minute

  const current = await redis.incr(key);

  if (current === 1) {
    await redis.expire(key, window);
  }

  if (current > limit) {
    const ttl = await redis.ttl(key);
    throw new Response(
      JSON.stringify({
        error: 'Rate limit exceeded',
        retryAfter: ttl,
      }),
      { status: 429 }
    );
  }
}

// Use in handler:
serve(async (req) => {
  const user = await authenticateUser(req);
  await checkRateLimit(user.id);

  // ... rest of handler
});
```

---

### 7.4 Remove Blocking URL Validation

**File:** `supabase/functions/analyze-product/index.ts:401-421`

**Current:**
```typescript
// Makes synchronous network requests to validate URLs
const isValidUrl = await fetch(url, { method: 'HEAD' });
```

**Recommendation:**
```typescript
// Option 1: Simple validation (no network call)
function isValidUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    return parsed.protocol === 'http:' || parsed.protocol === 'https:';
  } catch {
    return false;
  }
}

// Option 2: Return URLs immediately, validate asynchronously
// Just return the URLs from Gemini without validation
// If they're broken, the client will handle it gracefully

// Option 3: Domain whitelist
function isValidMarketplaceUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    const validDomains = ['ebay.com', 'amazon.com', 'walmart.com'];
    return validDomains.some(domain => parsed.hostname.includes(domain));
  } catch {
    return false;
  }
}
```

**Impact:** Reduce edge function execution time by 1-3 seconds

---

### 7.5 Response Streaming

**Current:** Wait for complete analysis before returning

**Recommendation:**
```typescript
// Stream results as they become available
serve(async (req) => {
  const stream = new TransformStream();
  const writer = stream.writable.getWriter();
  const encoder = new TextEncoder();

  // Start background processing
  processAnalysis(req).then(async (result) => {
    // Send product name first
    await writer.write(encoder.encode(JSON.stringify({
      type: 'product',
      data: { name: result.productName }
    }) + '\n'));

    // Send prices
    await writer.write(encoder.encode(JSON.stringify({
      type: 'prices',
      data: { ebay: result.ebayPrice, amazon: result.amazonPrice }
    }) + '\n'));

    // Send analysis
    await writer.write(encoder.encode(JSON.stringify({
      type: 'analysis',
      data: result.marketAnalysis
    }) + '\n'));

    // Send verdict
    await writer.write(encoder.encode(JSON.stringify({
      type: 'verdict',
      data: { verdict: result.verdict, profit: result.netProfit }
    }) + '\n'));

    await writer.close();
  });

  return new Response(stream.readable, {
    headers: { 'Content-Type': 'application/x-ndjson' }
  });
});
```

**Benefits:**
- Better perceived performance
- Progressive UI updates
- Can show partial results even if analysis fails partway

---

## 8. DevOps & Deployment 🚀

### 8.1 CI/CD Pipeline

**Current State:** No automated testing or deployment

**Recommendation:**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
  push:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Run analyzer
        run: flutter analyze

      - name: Run tests
        run: flutter test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: coverage/lcov.info

  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2

      - name: Build APK
        run: flutter build apk --release

      - name: Upload APK
        uses: actions/upload-artifact@v3
        with:
          name: app-release.apk
          path: build/app/outputs/flutter-apk/app-release.apk

  build-ios:
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2

      - name: Build iOS
        run: flutter build ios --release --no-codesign

      - name: Upload IPA
        uses: actions/upload-artifact@v3
        with:
          name: Runner.app
          path: build/ios/iphoneos/Runner.app
```

```yaml
# .github/workflows/deploy-edge-functions.yml
name: Deploy Edge Functions

on:
  push:
    branches: [main]
    paths:
      - 'supabase/functions/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: supabase/setup-cli@v1

      - name: Deploy functions
        run: |
          supabase functions deploy analyze-product \
            --project-ref ${{ secrets.SUPABASE_PROJECT_REF }}
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
```

---

### 8.2 Monitoring & Analytics

**Recommendation:**

```dart
// lib/services/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Track scan events
  static Future<void> logScanStarted() async {
    await _analytics.logEvent(name: 'scan_started');
  }

  static Future<void> logScanCompleted({
    required String verdict,
    required double profit,
    required String velocityScore,
  }) async {
    await _analytics.logEvent(
      name: 'scan_completed',
      parameters: {
        'verdict': verdict,
        'profit': profit,
        'velocity': velocityScore,
      },
    );
  }

  static Future<void> logScanFailed(String error) async {
    await _analytics.logEvent(
      name: 'scan_failed',
      parameters: {'error': error},
    );
  }

  // Track user behavior
  static Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // Track business metrics
  static Future<void> logPurchaseDecision(bool didBuy, double profit) async {
    await _analytics.logEvent(
      name: 'purchase_decision',
      parameters: {
        'did_buy': didBuy,
        'profit': profit,
      },
    );
  }
}
```

**Edge Function Monitoring:**
```typescript
// Add logging to edge function
console.log('Scan request:', {
  userId: user.id,
  timestamp: new Date().toISOString(),
  hasBarcode: !!barcode,
  condition,
});

// Track execution time
const startTime = Date.now();
const result = await analyzeWithGemini(...);
const duration = Date.now() - startTime;

console.log('Scan completed:', {
  userId: user.id,
  duration,
  verdict: result.verdict,
  profit: result.netProfit,
});
```

---

### 8.3 Performance Monitoring

**Recommendation:**

```dart
// lib/services/performance_service.dart
import 'package:firebase_performance/firebase_performance.dart';

class PerformanceService {
  static Future<T> trackOperation<T>(
    String name,
    Future<T> Function() operation,
  ) async {
    final trace = FirebasePerformance.instance.newTrace(name);
    await trace.start();

    try {
      final result = await operation();
      trace.putAttribute('success', 'true');
      return result;
    } catch (e) {
      trace.putAttribute('success', 'false');
      trace.putAttribute('error', e.toString());
      rethrow;
    } finally {
      await trace.stop();
    }
  }
}

// Usage:
final result = await PerformanceService.trackOperation(
  'analyze_product',
  () => supabaseService.analyzeItem(...),
);
```

---

## 9. Documentation 📚

### 9.1 Code Documentation

**Current State:** Minimal inline documentation

**Recommendations:**

```dart
// lib/services/supabase_service.dart

/// Service for interacting with Supabase backend
///
/// Provides methods for:
/// - Product analysis via edge functions
/// - Scan result persistence
/// - User scan history retrieval
class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  /// Analyzes a product image to determine profitability
  ///
  /// Sends the product image to the AI analysis edge function which:
  /// 1. Identifies the product
  /// 2. Researches market prices on eBay and Amazon
  /// 3. Calculates net profit after fees, taxes, and shipping
  /// 4. Provides a BUY/PASS verdict
  ///
  /// Parameters:
  /// - [image]: The product image file (mobile only)
  /// - [imageBytes]: The product image as bytes
  /// - [price]: The store price of the item
  /// - [barcode]: Optional barcode for more accurate identification
  /// - [condition]: Item condition ('Used', 'New', or 'New in Box')
  ///
  /// Returns: [ScanResult] containing the analysis
  ///
  /// Throws:
  /// - [NetworkException] if no internet connection
  /// - [AIAnalysisException] if the AI analysis fails
  /// - [RateLimitException] if too many requests
  ///
  /// Example:
  /// ```dart
  /// final result = await service.analyzeItem(
  ///   imageBytes: imageData,
  ///   price: 29.99,
  ///   condition: 'New',
  /// );
  /// print('Verdict: ${result.verdict}');
  /// ```
  Future<ScanResult> analyzeItem({...}) async {
    // ...
  }
}
```

---

### 9.2 API Documentation

**Create:** `docs/API.md`

```markdown
# Reseller Copilot API Documentation

## Edge Function: analyze-product

### Endpoint
POST /functions/v1/analyze-product

### Authentication
Requires Supabase JWT token in Authorization header:
```
Authorization: Bearer <token>
```

### Request Body
```json
{
  "imageData": "base64-encoded-image-data",
  "imageUrl": "https://...",  // Alternative to imageData
  "price": 29.99,
  "barcode": "012345678901",  // Optional
  "condition": "New"          // "Used" | "New" | "New in Box"
}
```

### Response
```json
{
  "product_name": "Nike Air Max 270",
  "buy_price": 29.99,
  "market_price": 89.99,
  "net_profit": 42.50,
  "verdict": "BUY",
  "velocity_score": "High",
  "ebay_price": 89.99,
  "ebay_url": "https://...",
  "amazon_price": 94.99,
  "amazon_url": "https://...",
  "fee_percentage": 15,
  "fees_amount": 13.50,
  "shipping_cost": 5.00,
  "sales_tax_rate": 8.0,
  "sales_tax_amount": 2.40,
  "market_analysis": "...",
  "product_image_url": "https://..."
}
```

### Error Responses

#### 401 Unauthorized
```json
{
  "error": "Invalid or expired token"
}
```

#### 429 Rate Limit Exceeded
```json
{
  "error": "Rate limit exceeded",
  "retryAfter": 45
}
```

#### 500 Internal Server Error
```json
{
  "error": "AI analysis failed",
  "details": "..."
}
```

### Rate Limits
- 10 requests per minute per user
- 100 requests per hour per user

### Timeouts
- Function timeout: 60 seconds
- AI API timeout: 30 seconds
```

---

## Priority Matrix

| Priority | Item | Effort | Impact | Category |
|----------|------|--------|--------|----------|
| **P0** | Fix Gemini model name (7.1) | Low | High | Backend |
| **P0** | Add unit tests (1.1) | High | High | Testing |
| **P0** | Extract scanner widgets (1.2) | Medium | High | Architecture |
| **P0** | Remove blocking URL validation (7.4) | Low | High | Performance |
| **P1** | Add scan history screen (4.1) | Medium | High | Features |
| **P1** | Implement caching (2.2) | Medium | High | Performance |
| **P1** | Add database indexes (2.3) | Low | High | Performance |
| **P1** | Migrate to Riverpod (1.3) | High | Medium | Architecture |
| **P1** | Image source options (3.2.1) | Low | Medium | UX |
| **P1** | Better error handling (5.2) | Medium | Medium | Quality |
| **P2** | Add barcode scanner (3.2.2) | Medium | Medium | UX |
| **P2** | Quick actions (3.2.3) | Medium | Medium | UX |
| **P2** | Offline support (4.2) | High | Medium | Features |
| **P2** | Settings screen (4.5) | Medium | Medium | Features |
| **P2** | Add monitoring (8.2) | Low | Medium | DevOps |
| **P2** | CI/CD pipeline (8.1) | Medium | Medium | DevOps |
| **P2** | Results improvements (3.2.4) | Medium | Medium | UX |
| **P3** | Dark mode (3.4.1) | Medium | Low | UX |
| **P3** | Product comparison (4.3) | Medium | Low | Features |
| **P3** | Batch scanning (4.4) | High | Low | Features |
| **P3** | Response streaming (7.5) | High | Low | Backend |

---

## Quick Wins

These items provide high impact with minimal effort. Recommend implementing immediately:

### 1. Fix Gemini Model Name (5 minutes)
**File:** `supabase/functions/analyze-product/index.ts:6`
```typescript
- const MODEL_NAME = "gemini-3-flash-preview";
+ const MODEL_NAME = "gemini-1.5-flash-002";
```

### 2. Create Constants File (30 minutes)
**File:** `lib/constants/app_constants.dart`
- Extract all magic numbers
- Define spacing, colors, durations
- Immediate code clarity improvement

### 3. Add Database Indexes (15 minutes)
**File:** `migrations/009_add_indexes.sql`
```sql
CREATE INDEX idx_scans_user_id_created_at ON scans(user_id, created_at DESC);
CREATE INDEX idx_scans_barcode ON scans(barcode) WHERE barcode IS NOT NULL;
```
Run: `supabase migration up`

### 4. Remove URL Validation (10 minutes)
**File:** `supabase/functions/analyze-product/index.ts:432-433`
- Replace network-based validation with simple URL parsing
- Instant 1-3 second performance improvement

### 5. Add Image Source Selection (20 minutes)
**File:** `lib/screens/scanner_screen.dart`
- Add gallery option to image picker
- Better testing experience

### 6. Add Error Tracking Setup (30 minutes)
- Add `sentry_flutter` dependency
- Initialize in `main.dart`
- Wrap `runApp` in error handler

### 7. Password Visibility Toggle (10 minutes)
**File:** `lib/screens/auth_screen.dart`
- Add visibility icon button
- Standard UX improvement

### 8. Add Web Image Compression (30 minutes)
**File:** `lib/services/supabase_service.dart:67`
- Use `image` package for web compression
- Reduce upload size and time

### 9. Create .env.example (5 minutes)
**File:** `.env.example`
```
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_anon_key_here
```

### 10. Add Input Validation (20 minutes)
**File:** `lib/utils/validators.dart`
- Price validation with max limits
- Barcode format validation
- Prevent invalid submissions

---

## Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
- ✅ Fix Gemini model name
- ✅ Add database indexes
- ✅ Remove blocking URL validation
- ✅ Create constants file
- ✅ Add error tracking
- ✅ Set up CI/CD pipeline
- ✅ Add basic unit tests

### Phase 2: Architecture (Week 3-4)
- Extract scanner screen widgets
- Migrate to Riverpod
- Implement caching
- Improve error handling
- Add code documentation

### Phase 3: Features (Week 5-6)
- Scan history screen
- Settings screen
- Image source options
- Barcode scanner
- Quick actions

### Phase 4: Polish (Week 7-8)
- Offline support
- Better loading states
- Accessibility improvements
- Dark mode
- Onboarding tutorial

### Phase 5: Advanced (Week 9-10)
- Product comparison
- Batch scanning
- Advanced analytics
- Performance optimizations

---

## Metrics for Success

Track these metrics to measure improvement impact:

### Performance Metrics
- Average scan time: Target < 5 seconds
- Cache hit rate: Target > 60%
- App startup time: Target < 2 seconds
- Image upload time: Target < 3 seconds

### Quality Metrics
- Code coverage: Target > 70%
- Linter warnings: Target 0
- Crash-free sessions: Target > 99.5%

### User Experience Metrics
- Scan success rate: Target > 95%
- Time to first scan: Target < 30 seconds
- User retention (Day 7): Target > 40%
- Feature adoption (history): Target > 50%

### Business Metrics
- Scans per user per session: Track trend
- BUY vs PASS ratio: Track trend
- Average profit per scan: Track trend

---

## 10. Web Application - Research & Marketplace Management 🌐

### Overview

The **Reseller Copilot Web Application** is a companion platform to the mobile app, focused on pre-purchase research, inventory management, and automated marketplace listing creation. While the mobile app excels at in-store scanning, the web app provides the research and post-purchase workflow tools that resellers need.

### Vision & Value Proposition

**Mobile App:** Quick in-store decisions ("Should I buy this?")
**Web App:** Strategic research and selling automation ("What should I look for?" + "How do I sell it?")

**Key Differentiators:**
- Research trending products before going to stores
- Import and manage scan history across devices
- Track inventory from purchase to sale
- Auto-generate marketplace listings with AI
- Multi-marketplace publishing (eBay, Amazon, Poshmark, Mercari, etc.)
- Analytics and profitability tracking

---

### 10.1 Architecture

#### Tech Stack

**Frontend:**
```
- Framework: Next.js 14+ (App Router)
- Language: TypeScript
- UI Library: React 18+
- Styling: Tailwind CSS + shadcn/ui components
- State Management: Zustand + React Query
- Charts: Recharts or Chart.js
- Tables: TanStack Table
- Forms: React Hook Form + Zod validation
```

**Backend:**
```
- Platform: Supabase (shared with mobile app)
- Database: PostgreSQL (extend existing schema)
- Edge Functions: Deno (for AI operations)
- Storage: Supabase Storage (product images)
- Real-time: Supabase Realtime (sync with mobile)
```

**External APIs:**
```
- Google Gemini API: Product research, listing generation
- eBay API: Browse, publish listings, get trends
- Amazon Product Advertising API: Product research
- Poshmark/Mercari APIs: Marketplace integration
- Google Trends API: Trending product data
- Web Scraping: Cheerio/Puppeteer for market research
```

**Deployment:**
```
- Web Hosting: Vercel or Netlify
- Edge Functions: Supabase Edge Functions
- CDN: Built-in with hosting platform
- Domain: Custom domain (e.g., app.resellercopilot.com)
```

---

### 10.2 Database Schema Extensions

Extend the existing mobile app database with new tables:

```sql
-- migrations/010_web_app_tables.sql

-- Product catalog for research
CREATE TABLE product_catalog (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),

  -- Product info
  product_name TEXT NOT NULL,
  category TEXT,
  brand TEXT,
  upc_code TEXT,

  -- Market data
  avg_sell_price DECIMAL(10,2),
  avg_buy_price DECIMAL(10,2),
  trend_score INTEGER, -- 1-100
  velocity_score TEXT, -- High/Med/Low

  -- Research metadata
  ebay_search_volume INTEGER,
  amazon_bsr INTEGER, -- Best seller rank
  google_trends_score INTEGER,

  -- Sources
  data_sources JSONB, -- {ebay: {...}, amazon: {...}, etc}

  -- Timestamps
  last_researched_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Indexes
  CONSTRAINT unique_user_product UNIQUE(user_id, product_name, brand)
);

CREATE INDEX idx_product_catalog_user_id ON product_catalog(user_id);
CREATE INDEX idx_product_catalog_trend_score ON product_catalog(trend_score DESC);
CREATE INDEX idx_product_catalog_category ON product_catalog(category);

-- Inventory management
CREATE TABLE inventory (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  scan_id UUID REFERENCES scans(id), -- Link to original scan

  -- Product info
  product_name TEXT NOT NULL,
  brand TEXT,
  condition TEXT NOT NULL,
  quantity INTEGER DEFAULT 1,

  -- Purchase details
  purchase_price DECIMAL(10,2) NOT NULL,
  purchase_location TEXT,
  purchase_date DATE NOT NULL,

  -- Storage
  storage_location TEXT, -- e.g., "Shelf A-3"

  -- Status
  status TEXT NOT NULL DEFAULT 'in_stock',
  -- 'in_stock', 'listed', 'sold', 'returned'

  -- Images
  images JSONB, -- Array of image URLs
  notes TEXT,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_inventory_user_status ON inventory(user_id, status);
CREATE INDEX idx_inventory_purchase_date ON inventory(purchase_date DESC);
CREATE INDEX idx_inventory_scan_id ON inventory(scan_id);

-- Marketplace listings
CREATE TABLE marketplace_listings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  inventory_id UUID REFERENCES inventory(id),

  -- Marketplace
  marketplace TEXT NOT NULL, -- 'ebay', 'amazon', 'poshmark', 'mercari'
  marketplace_listing_id TEXT, -- External ID from marketplace

  -- Listing details
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  category TEXT,
  images JSONB, -- Array of image URLs

  -- Generated content
  ai_generated_title TEXT,
  ai_generated_description TEXT,
  ai_generated_tags JSONB,

  -- Status
  status TEXT NOT NULL DEFAULT 'draft',
  -- 'draft', 'published', 'active', 'sold', 'ended'

  -- Marketplace specifics
  marketplace_data JSONB, -- Platform-specific fields

  -- Publishing
  published_at TIMESTAMP WITH TIME ZONE,
  sold_at TIMESTAMP WITH TIME ZONE,
  sold_price DECIMAL(10,2),

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_listings_user_status ON marketplace_listings(user_id, status);
CREATE INDEX idx_listings_marketplace ON marketplace_listings(marketplace, status);
CREATE INDEX idx_listings_inventory_id ON marketplace_listings(inventory_id);

-- Trending products watchlist
CREATE TABLE trending_products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Product info
  product_name TEXT NOT NULL,
  category TEXT,
  brand TEXT,

  -- Trend data
  trend_score INTEGER NOT NULL, -- 1-100
  search_volume INTEGER,
  price_trend TEXT, -- 'rising', 'stable', 'falling'

  -- Opportunities
  avg_profit_margin DECIMAL(5,2),
  recommended_buy_price DECIMAL(10,2),

  -- Data
  trend_data JSONB, -- Historical data

  -- Timestamps
  trending_since TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CONSTRAINT unique_trending_product UNIQUE(product_name, brand)
);

CREATE INDEX idx_trending_products_score ON trending_products(trend_score DESC);
CREATE INDEX idx_trending_products_category ON trending_products(category);

-- User watchlist (products they want to track)
CREATE TABLE user_watchlist (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,

  -- Product to watch
  product_name TEXT NOT NULL,
  brand TEXT,
  category TEXT,

  -- Alert settings
  alert_on_trend BOOLEAN DEFAULT true,
  alert_on_price_drop BOOLEAN DEFAULT true,
  target_buy_price DECIMAL(10,2),

  -- Status
  is_active BOOLEAN DEFAULT true,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CONSTRAINT unique_user_watchlist UNIQUE(user_id, product_name, brand)
);

CREATE INDEX idx_watchlist_user_active ON user_watchlist(user_id, is_active);

-- Sales tracking
CREATE TABLE sales (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  inventory_id UUID REFERENCES inventory(id),
  listing_id UUID REFERENCES marketplace_listings(id),

  -- Sale details
  marketplace TEXT NOT NULL,
  sale_price DECIMAL(10,2) NOT NULL,
  fees DECIMAL(10,2),
  shipping_cost DECIMAL(10,2),
  net_profit DECIMAL(10,2) NOT NULL,

  -- Timeline
  purchase_price DECIMAL(10,2) NOT NULL,
  purchase_date DATE NOT NULL,
  sale_date DATE NOT NULL,
  days_to_sell INTEGER,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_sales_user_date ON sales(user_id, sale_date DESC);
CREATE INDEX idx_sales_marketplace ON sales(marketplace);

-- Row Level Security
ALTER TABLE product_catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_watchlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own product catalog"
  ON product_catalog FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own product catalog"
  ON product_catalog FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own inventory"
  ON inventory FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own inventory"
  ON inventory FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own listings"
  ON marketplace_listings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own listings"
  ON marketplace_listings FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own watchlist"
  ON user_watchlist FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own watchlist"
  ON user_watchlist FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own sales"
  ON sales FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own sales"
  ON sales FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Trending products is public (read-only for all authenticated users)
CREATE POLICY "Authenticated users can view trending products"
  ON trending_products FOR SELECT
  TO authenticated
  USING (true);
```

---

### 10.3 Core Features

#### 10.3.1 Product Research Dashboard

**Purpose:** Help resellers discover profitable products before going to stores

**Features:**

1. **Trending Products Feed**
```typescript
// Components:
- Real-time trending products grid
- Filters: category, price range, profit margin, trend score
- Sort: by trend score, profit potential, recency
- Save to watchlist
- Get alerts when products trend
```

2. **Product Search & Analysis**
```typescript
interface ProductResearch {
  productName: string;
  brand?: string;

  // Market data
  ebayData: {
    averagePrice: number;
    soldListings: number;
    activeListings: number;
    topSellers: Listing[];
  };

  amazonData: {
    currentPrice: number;
    bestSellerRank: number;
    reviewCount: number;
    rating: number;
  };

  // Trends
  googleTrends: {
    interest: number; // 0-100
    relatedQueries: string[];
    risingQueries: string[];
  };

  // Profit analysis
  profitability: {
    avgBuyPrice: number;
    avgSellPrice: number;
    avgProfit: number;
    avgMargin: number;
    velocityScore: 'High' | 'Med' | 'Low';
  };

  // Recommendations
  recommendation: {
    shouldPursue: boolean;
    targetBuyPrice: number;
    estimatedProfit: number;
    reasoning: string;
  };
}
```

**UI Components:**
```tsx
// app/research/page.tsx
<ResearchDashboard>
  <TrendingProductsCarousel />
  <ProductSearchBar />
  <CategoryFilters />
  <ResearchResults>
    <ProductCard />
    <ProfitAnalysis />
    <MarketTrends />
  </ResearchResults>
</ResearchDashboard>
```

3. **What to Look For** Guide
```typescript
// Auto-generated based on user's history and trends
interface ShoppingList {
  categories: Category[];
  brands: Brand[];
  priceRanges: PriceRange[];
  locations: string[]; // "Check Ross for..."

  hotProducts: {
    name: string;
    targetPrice: number;
    estProfit: number;
    whereToFind: string[];
  }[];
}
```

---

#### 10.3.2 Scan Import & Sync

**Purpose:** Seamlessly sync mobile scan data to web dashboard

**Implementation:**

1. **Real-time Sync**
```typescript
// Use Supabase Realtime
const { data, error } = await supabase
  .from('scans')
  .select('*')
  .eq('user_id', userId)
  .order('created_at', { ascending: false });

// Subscribe to changes
const subscription = supabase
  .channel('scans')
  .on('postgres_changes',
    {
      event: 'INSERT',
      schema: 'public',
      table: 'scans',
      filter: `user_id=eq.${userId}`
    },
    (payload) => {
      // Auto-add new scan to dashboard
      addScanToUI(payload.new);
    }
  )
  .subscribe();
```

2. **Scan Management View**
```tsx
// app/scans/page.tsx
<ScanHistoryTable>
  <Filters>
    <VerdictFilter /> {/* BUY / PASS */}
    <DateRangeFilter />
    <LocationFilter />
    <ProfitRangeFilter />
  </Filters>

  <DataTable>
    <Column field="product_name" />
    <Column field="verdict" />
    <Column field="net_profit" />
    <Column field="created_at" />
    <Column field="actions">
      <AddToInventoryButton />
      <ViewDetailsButton />
      <DeleteButton />
    </Column>
  </DataTable>

  <BulkActions>
    <AddSelectedToInventory />
    <ExportSelected />
    <DeleteSelected />
  </BulkActions>
</ScanHistoryTable>
```

3. **Convert Scan to Inventory**
```typescript
async function addScanToInventory(scanId: string) {
  const scan = await getScan(scanId);

  // Pre-fill form with scan data
  const inventoryItem = {
    scan_id: scanId,
    product_name: scan.product_name,
    condition: scan.condition,
    purchase_price: scan.buy_price,
    purchase_date: new Date(),
    purchase_location: '', // User fills in
    storage_location: '', // User fills in
    quantity: 1,
    status: 'in_stock',
    images: [scan.product_image_url],
  };

  return await supabase
    .from('inventory')
    .insert(inventoryItem);
}
```

---

#### 10.3.3 Inventory Management

**Purpose:** Track products from purchase to sale

**Features:**

1. **Inventory Dashboard**
```tsx
// app/inventory/page.tsx
<InventoryDashboard>
  <MetricsCards>
    <Card title="Total Items" value={inventory.length} />
    <Card title="Total Value" value={totalValue} />
    <Card title="Listed Items" value={listedCount} />
    <Card title="Avg Days to Sell" value={avgDaysToSell} />
  </MetricsCards>

  <InventoryTable>
    <StatusFilter /> {/* in_stock, listed, sold */}
    <SearchBar />

    <ItemRow>
      <Image />
      <ProductName />
      <Condition />
      <PurchaseInfo />
      <Status />
      <Actions>
        <CreateListingButton />
        <EditButton />
        <MarkAsSoldButton />
      </Actions>
    </ItemRow>
  </InventoryTable>
</InventoryDashboard>
```

2. **Add to Inventory**
```tsx
// app/inventory/new/page.tsx
<AddInventoryForm>
  <ProductInfo>
    <Input name="product_name" required />
    <Input name="brand" />
    <Select name="condition" options={conditions} />
    <Input name="quantity" type="number" />
  </ProductInfo>

  <PurchaseInfo>
    <Input name="purchase_price" type="currency" required />
    <Input name="purchase_date" type="date" required />
    <Input name="purchase_location" />
  </PurchaseInfo>

  <Storage>
    <Input name="storage_location" placeholder="e.g., Shelf A-3" />
  </Storage>

  <Images>
    <ImageUploader multiple max={10} />
  </Images>

  <Notes>
    <Textarea name="notes" placeholder="Special details, flaws, etc." />
  </Notes>
</AddInventoryForm>
```

3. **Inventory Item Detail**
```tsx
// app/inventory/[id]/page.tsx
<InventoryDetailPage>
  <ImageGallery images={item.images} />

  <ProductDetails>
    <Title>{item.product_name}</Title>
    <Metadata>
      <Field label="Condition" value={item.condition} />
      <Field label="Purchase Price" value={item.purchase_price} />
      <Field label="Purchase Date" value={item.purchase_date} />
      <Field label="Location" value={item.storage_location} />
      <Field label="Status" value={item.status} />
    </Metadata>
  </ProductDetails>

  <Listings>
    {item.listings.map(listing => (
      <ListingCard
        marketplace={listing.marketplace}
        status={listing.status}
        price={listing.price}
      />
    ))}

    <CreateNewListingButton />
  </Listings>

  <Timeline>
    <Event type="purchased" date={item.purchase_date} />
    <Event type="added_to_inventory" date={item.created_at} />
    {item.listings.map(l => (
      <Event type="listed" date={l.published_at} marketplace={l.marketplace} />
    ))}
    {item.status === 'sold' && (
      <Event type="sold" date={item.sold_at} />
    )}
  </Timeline>
</InventoryDetailPage>
```

---

#### 10.3.4 AI-Powered Listing Generator

**Purpose:** Auto-generate optimized marketplace listings

**Implementation:**

1. **Listing Creator Wizard**
```tsx
// app/listings/create/page.tsx
<ListingWizard inventoryId={inventoryId}>
  <Step1SelectMarketplace>
    <MarketplaceCard
      name="eBay"
      icon={<EbayIcon />}
      description="Auction or Buy It Now"
    />
    <MarketplaceCard
      name="Amazon"
      icon={<AmazonIcon />}
      description="FBA or FBM"
    />
    <MarketplaceCard
      name="Poshmark"
      icon={<PoshmarkIcon />}
      description="Fashion & accessories"
    />
    <MarketplaceCard
      name="Mercari"
      icon={<MercariIcon />}
      description="General marketplace"
    />
  </Step1SelectMarketplace>

  <Step2GenerateListing>
    <AIGenerationPanel>
      <Button onClick={generateWithAI}>
        <SparklesIcon /> Generate with AI
      </Button>

      {loading && <LoadingState message="Analyzing product..." />}

      {generated && (
        <>
          <TitleField value={aiTitle} editable />
          <DescriptionEditor value={aiDescription} />
          <TagsInput value={aiTags} />
          <PriceInput value={suggestedPrice} />

          <CompetitorAnalysis>
            <SimilarListing price={comp.price} views={comp.views} />
          </CompetitorAnalysis>
        </>
      )}
    </AIGenerationPanel>
  </Step2GenerateListing>

  <Step3CustomizeDetails>
    <CategorySelector marketplace={marketplace} />
    <ShippingOptions />
    <ReturnPolicy />
    <MarketplaceSpecificFields marketplace={marketplace} />
  </Step3CustomizeDetails>

  <Step4Review>
    <ListingPreview marketplace={marketplace} data={listingData} />
    <ValidationChecklist>
      <CheckItem>Title length OK (80/80 characters)</CheckItem>
      <CheckItem>At least 1 image uploaded</CheckItem>
      <CheckItem>Price within competitive range</CheckItem>
    </ValidationChecklist>
  </Step4Review>

  <Step5Publish>
    <PublishOptions>
      <Radio value="draft" label="Save as draft" />
      <Radio value="schedule" label="Schedule for later" />
      <Radio value="publish" label="Publish now" />
    </PublishOptions>

    <Button onClick={publishListing}>
      Publish to {marketplace}
    </Button>
  </Step5Publish>
</ListingWizard>
```

2. **AI Listing Generation Edge Function**
```typescript
// supabase/functions/generate-listing/index.ts
import { serve } from 'std/server';
import Anthropic from '@anthropic-ai/sdk';

serve(async (req) => {
  const { inventoryItem, marketplace } = await req.json();

  // Get competitive data
  const competitors = await fetchCompetitors(
    inventoryItem.product_name,
    marketplace
  );

  // Generate with AI
  const prompt = `
You are an expert marketplace listing creator. Create an optimized ${marketplace} listing.

Product: ${inventoryItem.product_name}
Condition: ${inventoryItem.condition}
Purchase Price: $${inventoryItem.purchase_price}

Competitor Analysis:
${competitors.map(c => `- ${c.title}: $${c.price} (${c.sales} sold)`).join('\n')}

Generate:
1. Attention-grabbing title (${MARKETPLACE_LIMITS[marketplace].titleLength} chars max)
2. Detailed, compelling description with:
   - Key features and benefits
   - Condition details
   - Shipping info
   - Keywords for SEO
3. Relevant tags/keywords (10-15)
4. Suggested price based on competitive analysis
5. Category recommendation

Output JSON format:
{
  "title": "...",
  "description": "...",
  "tags": ["..."],
  "suggestedPrice": 0.00,
  "category": "...",
  "reasoning": "..."
}
`;

  const response = await anthropic.messages.create({
    model: 'claude-sonnet-4-5-20250929',
    max_tokens: 2000,
    messages: [{
      role: 'user',
      content: prompt
    }]
  });

  const listing = JSON.parse(response.content[0].text);

  return new Response(JSON.stringify(listing), {
    headers: { 'Content-Type': 'application/json' }
  });
});
```

3. **Marketplace Publishing**
```typescript
// lib/marketplace-integrations/ebay.ts
export async function publishToEbay(listing: Listing) {
  const ebayApi = new EbayAPI({
    clientId: process.env.EBAY_CLIENT_ID,
    clientSecret: process.env.EBAY_CLIENT_SECRET,
    refreshToken: user.ebayRefreshToken,
  });

  const item = {
    title: listing.title,
    description: listing.description,
    price: listing.price,
    categoryId: listing.marketplace_data.categoryId,
    images: listing.images,
    condition: mapCondition(listing.condition),
    shippingPolicy: listing.marketplace_data.shippingPolicy,
    returnPolicy: listing.marketplace_data.returnPolicy,
  };

  const result = await ebayApi.trading.AddFixedPriceItem(item);

  // Update listing with eBay ID
  await supabase
    .from('marketplace_listings')
    .update({
      marketplace_listing_id: result.ItemID,
      status: 'published',
      published_at: new Date(),
    })
    .eq('id', listing.id);

  return result;
}

// Similar implementations for:
// - lib/marketplace-integrations/amazon.ts
// - lib/marketplace-integrations/poshmark.ts
// - lib/marketplace-integrations/mercari.ts
```

---

#### 10.3.5 Multi-Marketplace Management

**Purpose:** Manage listings across multiple platforms from one dashboard

**Features:**

1. **Unified Listings Dashboard**
```tsx
// app/listings/page.tsx
<ListingsDashboard>
  <MetricsOverview>
    <Metric title="Active Listings" value={activeCount} />
    <Metric title="Total Views" value={totalViews} />
    <Metric title="Pending Sales" value={pendingSales} />
    <Metric title="Avg Price" value={avgPrice} />
  </MetricsOverview>

  <MarketplaceTabs>
    <Tab name="All" />
    <Tab name="eBay" icon={<EbayIcon />} count={ebayCount} />
    <Tab name="Amazon" icon={<AmazonIcon />} count={amazonCount} />
    <Tab name="Poshmark" icon={<PoshmarkIcon />} count={poshmarkCount} />
    <Tab name="Mercari" icon={<MercariIcon />} count={mercariCount} />
  </MarketplaceTabs>

  <ListingsTable>
    <Row>
      <Image />
      <Title />
      <Marketplace />
      <Status badge />
      <Price />
      <Views />
      <Actions>
        <ViewOnMarketplaceButton />
        <EditListingButton />
        <EndListingButton />
        <CrossListButton /> {/* List on another marketplace */}
      </Actions>
    </Row>
  </ListingsTable>
</ListingsDashboard>
```

2. **Cross-Listing Feature**
```typescript
// One-click list same product on multiple marketplaces
async function crossListProduct(
  sourceListingId: string,
  targetMarketplaces: string[]
) {
  const sourceListing = await getListing(sourceListingId);

  const crossListings = await Promise.all(
    targetMarketplaces.map(async (marketplace) => {
      // Adapt listing for each marketplace
      const adapted = await adaptListingForMarketplace(
        sourceListing,
        marketplace
      );

      // Create new listing
      const newListing = await createListing({
        ...adapted,
        inventory_id: sourceListing.inventory_id,
        marketplace,
      });

      // Optionally auto-publish
      if (autoPublish) {
        await publishListing(newListing.id, marketplace);
      }

      return newListing;
    })
  );

  return crossListings;
}
```

---

#### 10.3.6 Analytics & Reporting

**Purpose:** Track profitability and optimize reselling strategy

**Features:**

1. **Profitability Dashboard**
```tsx
// app/analytics/page.tsx
<AnalyticsDashboard>
  <KPICards>
    <Card title="Total Revenue" value={totalRevenue} trend="+12%" />
    <Card title="Total Profit" value={totalProfit} trend="+8%" />
    <Card title="Avg Profit/Item" value={avgProfit} />
    <Card title="ROI" value={roi} />
  </KPICards>

  <Charts>
    <RevenueChart
      data={monthlyRevenue}
      title="Revenue Over Time"
    />

    <ProfitByCategory
      data={categoryProfits}
      title="Most Profitable Categories"
    />

    <VelocityChart
      data={daysToSell}
      title="Average Days to Sell"
    />

    <MarketplaceComparison
      data={marketplaceMetrics}
      title="Performance by Marketplace"
    />
  </Charts>

  <TopPerformers>
    <Table title="Top Selling Products">
      {topProducts.map(p => (
        <Row>
          <Cell>{p.name}</Cell>
          <Cell>{p.unitsSold}</Cell>
          <Cell>${p.totalProfit}</Cell>
        </Row>
      ))}
    </Table>

    <Table title="Top Categories">
      {topCategories.map(c => (
        <Row>
          <Cell>{c.name}</Cell>
          <Cell>{c.itemsSold}</Cell>
          <Cell>${c.totalRevenue}</Cell>
        </Row>
      ))}
    </Table>
  </TopPerformers>

  <ExportButtons>
    <Button onClick={exportPDF}>Export PDF Report</Button>
    <Button onClick={exportCSV}>Export CSV</Button>
  </ExportButtons>
</AnalyticsDashboard>
```

2. **Inventory Performance**
```tsx
<InventoryAnalytics>
  <AgeAnalysis>
    <Chart data={inventoryAge} />
    <Alert type="warning">
      You have 12 items over 90 days old
    </Alert>
  </AgeAnalysis>

  <TurnoverRate>
    <Metric value={turnoverRate} label="Inventory Turnover" />
    <Comparison benchmark={industryAvg} />
  </TurnoverRate>

  <DeadStock>
    <List items={slowMovers}>
      <Suggestion>Consider price reduction</Suggestion>
      <Suggestion>Try different marketplace</Suggestion>
    </List>
  </DeadStock>
</InventoryAnalytics>
```

---

### 10.4 User Workflows

#### Workflow 1: Research Before Shopping

```
1. User logs into web app
2. Checks "Trending Products" feed
3. Finds "Nike Air Max" is trending high
4. Clicks to research product
5. Sees:
   - eBay avg sell price: $89
   - Amazon current price: $95
   - Google Trends: Rising
   - Recommended buy price: < $30
   - Estimated profit: $45
6. Adds to "Watchlist"
7. Gets shopping list: "Look for Nike Air Max at Ross, TJ Maxx"
8. Goes to store with mobile app
```

#### Workflow 2: Scan to Sale

```
1. In-store: Scan product with mobile app
2. Gets "BUY" verdict
3. Purchases item
4. Back home: Opens web app
5. Sees new scan auto-synced
6. Clicks "Add to Inventory"
7. Fills in:
   - Storage location: "Shelf A-3"
   - Photos: Upload 5 images
8. Clicks "Create Listing"
9. Selects "eBay"
10. Clicks "Generate with AI"
11. Reviews AI-generated:
    - Title: "Nike Air Max 270 Men's Size 10 Triple Black NEW"
    - Description: (optimized copy)
    - Price: $89.99
12. Makes minor edits
13. Clicks "Publish Now"
14. Listing goes live on eBay
15. (Optional) Clicks "Cross-list to Poshmark"
```

#### Workflow 3: Analytics Review

```
1. Weekly: Check analytics dashboard
2. Reviews:
   - Revenue this week: $450
   - Profit this week: $280
   - Items sold: 6
   - Avg days to sell: 12
3. Sees "Nike shoes" are top category
4. Sees "Electronics" have slow velocity
5. Adjusts strategy:
   - Focus more on Nike products
   - Price drop on old electronics
6. Exports monthly report PDF for taxes
```

---

### 10.5 Technical Implementation Details

#### 10.5.1 Project Structure

```
web-app/
├── app/                          # Next.js App Router
│   ├── (auth)/
│   │   ├── login/
│   │   └── signup/
│   ├── (dashboard)/
│   │   ├── layout.tsx           # Dashboard layout with sidebar
│   │   ├── page.tsx             # Dashboard home
│   │   ├── research/
│   │   │   ├── page.tsx         # Product research
│   │   │   └── [product]/
│   │   ├── scans/
│   │   │   ├── page.tsx         # Scan history
│   │   │   └── [id]/
│   │   ├── inventory/
│   │   │   ├── page.tsx         # Inventory list
│   │   │   ├── new/
│   │   │   └── [id]/
│   │   ├── listings/
│   │   │   ├── page.tsx         # All listings
│   │   │   ├── create/
│   │   │   └── [id]/
│   │   ├── analytics/
│   │   │   └── page.tsx
│   │   ├── watchlist/
│   │   │   └── page.tsx
│   │   └── settings/
│   ├── api/                      # API routes
│   │   ├── research/
│   │   ├── trending/
│   │   ├── listings/
│   │   └── webhooks/
│   ├── layout.tsx
│   └── globals.css
├── components/
│   ├── ui/                       # shadcn/ui components
│   ├── research/
│   │   ├── TrendingProducts.tsx
│   │   ├── ProductSearch.tsx
│   │   └── ResearchResults.tsx
│   ├── inventory/
│   │   ├── InventoryTable.tsx
│   │   ├── AddInventoryForm.tsx
│   │   └── InventoryCard.tsx
│   ├── listings/
│   │   ├── ListingWizard.tsx
│   │   ├── AIGenerator.tsx
│   │   └── MarketplaceSelector.tsx
│   └── analytics/
│       ├── Charts.tsx
│       └── Metrics.tsx
├── lib/
│   ├── supabase/
│   │   ├── client.ts
│   │   ├── server.ts
│   │   └── types.ts
│   ├── marketplace-integrations/
│   │   ├── ebay.ts
│   │   ├── amazon.ts
│   │   ├── poshmark.ts
│   │   └── mercari.ts
│   ├── api-clients/
│   │   ├── gemini.ts
│   │   └── trends.ts
│   ├── utils/
│   └── hooks/
├── stores/                       # Zustand stores
│   ├── useInventoryStore.ts
│   ├── useListingsStore.ts
│   └── useResearchStore.ts
├── supabase/
│   ├── functions/
│   │   ├── generate-listing/
│   │   ├── research-product/
│   │   └── sync-trending/
│   └── migrations/
│       └── 010_web_app_tables.sql
├── public/
├── styles/
├── types/
├── .env.local
├── next.config.js
├── tailwind.config.ts
└── package.json
```

#### 10.5.2 Key Dependencies

```json
{
  "dependencies": {
    "next": "^14.1.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "typescript": "^5.3.3",

    "@supabase/supabase-js": "^2.39.0",
    "@supabase/auth-helpers-nextjs": "^0.9.0",

    "@tanstack/react-query": "^5.17.0",
    "@tanstack/react-table": "^8.11.0",
    "zustand": "^4.4.7",

    "@radix-ui/react-*": "latest",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.1.0",
    "tailwind-merge": "^2.2.0",

    "react-hook-form": "^7.49.0",
    "zod": "^3.22.4",
    "@hookform/resolvers": "^3.3.4",

    "recharts": "^2.10.0",
    "date-fns": "^3.0.0",
    "lucide-react": "^0.309.0",

    "@anthropic-ai/sdk": "^0.12.0",
    "ebay-api": "^5.0.0",
    "cheerio": "^1.0.0-rc.12",
    "puppeteer": "^21.7.0"
  }
}
```

#### 10.5.3 Edge Functions

```typescript
// supabase/functions/research-product/index.ts
/**
 * Research a product across multiple sources
 * Returns comprehensive market analysis
 */
serve(async (req) => {
  const { productName, brand } = await req.json();

  // Parallel research across sources
  const [ebayData, amazonData, trendsData] = await Promise.all([
    researchEbay(productName, brand),
    researchAmazon(productName, brand),
    getGoogleTrends(productName),
  ]);

  // AI analysis
  const analysis = await analyzeWithAI({
    productName,
    brand,
    ebayData,
    amazonData,
    trendsData,
  });

  return new Response(JSON.stringify(analysis));
});

// supabase/functions/sync-trending/index.ts
/**
 * Cron job to update trending products daily
 */
Deno.cron("Update trending products", "0 0 * * *", async () => {
  const trendingProducts = await fetchTrendingFromAPIs();

  await supabase
    .from('trending_products')
    .upsert(trendingProducts);
});
```

---

### 10.6 Integration with Mobile App

**Shared Infrastructure:**
- Same Supabase project
- Same authentication system
- Same database (extended schema)
- Real-time sync via Supabase Realtime

**Data Flow:**
```
Mobile App → Supabase (scans table) → Real-time → Web App
Web App → Supabase (inventory) → Real-time → Mobile App (future)
```

**Future Mobile Features:**
- Show inventory count badge
- Quick lookup: "Do I already have this?"
- Sync shopping list from web research
- Alert when scanning watchlist items

---

### 10.7 MVP Features (Phase 1)

**Priority: P0 - Launch Blockers**

1. ✅ User authentication (shared with mobile)
2. ✅ Scan import and display
3. ✅ Basic inventory management (CRUD)
4. ✅ Simple listing creator (manual)
5. ✅ eBay integration (publish listings)
6. ✅ Basic analytics (revenue, profit)

**Priority: P1 - Core Value**

7. ✅ AI listing generator
8. ✅ Trending products feed
9. ✅ Product research tool
10. ✅ Multi-marketplace support (add Poshmark)
11. ✅ Advanced analytics

**Priority: P2 - Enhanced**

12. Watchlist & alerts
13. Cross-listing automation
14. Batch operations
15. Mobile app integration (show inventory)
16. Advanced reporting (PDF exports)

---

### 10.8 Development Roadmap

#### Phase 1: Foundation (Weeks 1-3)
```
Week 1:
- Set up Next.js project
- Configure Supabase client
- Create database migrations
- Build authentication pages

Week 2:
- Create dashboard layout
- Scan import page
- Basic inventory CRUD
- Image upload to Supabase Storage

Week 3:
- eBay API integration
- Manual listing creator
- Publish to eBay functionality
```

#### Phase 2: AI & Research (Weeks 4-6)
```
Week 4:
- AI listing generator edge function
- Listing wizard UI
- Competitor analysis

Week 5:
- Product research API integrations
- Research dashboard UI
- Trending products feed

Week 6:
- Google Trends integration
- Profitability calculator
- Product recommendations
```

#### Phase 3: Multi-Marketplace (Weeks 7-9)
```
Week 7:
- Poshmark API integration
- Marketplace adapter pattern
- Cross-listing UI

Week 8:
- Amazon integration (basic)
- Mercari integration
- Unified listings dashboard

Week 9:
- Marketplace sync (status updates)
- Webhook handlers
- Error handling & retries
```

#### Phase 4: Analytics & Polish (Weeks 10-12)
```
Week 10:
- Analytics dashboard
- Charts and reports
- Export functionality

Week 11:
- Watchlist feature
- Alerts system
- Email notifications

Week 12:
- Performance optimization
- Testing
- Bug fixes
- Documentation
```

---

### 10.9 Success Metrics

**User Engagement:**
- Daily active users (DAU)
- Time spent in app
- Features used per session
- Retention rate (Day 7, Day 30)

**Business Metrics:**
- Listings created per user
- Cross-listing adoption rate
- Average profit per listing
- Time saved vs manual listing

**Technical Metrics:**
- API response times < 2s
- AI generation time < 10s
- Listing publish success rate > 95%
- Uptime > 99.5%

---

### 10.10 Competitive Advantages

**vs. Manual Listing:**
- 10x faster with AI generation
- Better SEO optimization
- Consistent quality

**vs. Other Tools:**
- Integrated with in-store scanning
- AI-powered research & generation
- Multi-marketplace from single interface
- Profitability tracking built-in

**Unique Features:**
- Mobile-to-web workflow
- Trending products research
- AI listing optimization
- Comprehensive analytics

---

### 10.11 Monetization Strategy (Future)

**Free Tier:**
- Up to 10 active listings
- Basic AI generation (10/month)
- Single marketplace
- Basic analytics

**Pro Tier ($29/month):**
- Unlimited listings
- Unlimited AI generation
- All marketplaces
- Advanced analytics
- Priority support
- Cross-listing automation

**Enterprise Tier ($99/month):**
- Everything in Pro
- Team collaboration
- Bulk operations
- API access
- Custom integrations
- Dedicated support

---

## Conclusion

This comprehensive review identified **89 specific improvements** across 10 categories for the mobile app, plus a complete **Web Application architecture** for research and marketplace management. The codebase has a solid foundation but significant opportunities exist for:

1. **Code Quality** - Refactoring monolithic components, adding tests
2. **Performance** - Caching, optimization, database indexes
3. **User Experience** - Missing features, better UI/UX patterns
4. **Production Readiness** - Monitoring, error tracking, CI/CD

### Mobile App Improvements

Implementing the **Quick Wins** section first will provide immediate value with minimal effort. Following the phased roadmap will systematically improve the mobile application over 10 weeks.

**Estimated Effort:** 8-10 weeks (1 full-time developer)

**Expected Outcome:**
- More maintainable codebase
- Better user experience
- Production-ready mobile application
- Foundation for scaling

### Web Application

The proposed web application complements the mobile app by providing:

1. **Pre-Purchase Research** - Discover trending products and opportunities
2. **Inventory Management** - Track items from purchase to sale
3. **Listing Automation** - AI-generated marketplace listings
4. **Multi-Marketplace** - Publish to eBay, Amazon, Poshmark, Mercari
5. **Analytics** - Profitability tracking and business insights

**Estimated Effort:** 12 weeks (1 full-time developer)

**Tech Stack:**
- Next.js 14+ with TypeScript
- Supabase (shared with mobile)
- AI: Claude API for listing generation
- Integrations: eBay, Amazon, Poshmark, Mercari APIs

**Development Phases:**
- Phase 1 (Weeks 1-3): Foundation & inventory
- Phase 2 (Weeks 4-6): AI & research features
- Phase 3 (Weeks 7-9): Multi-marketplace integration
- Phase 4 (Weeks 10-12): Analytics & polish

### Complete Platform

**Combined Value:**
- **Mobile:** In-store scanning and instant profitability decisions
- **Web:** Research, inventory management, and selling automation
- **Together:** Complete reseller workflow from research → scan → inventory → list → sell → analyze

---

**Next Steps:**

**Mobile App:**
1. Fix critical bug (Gemini model name)
2. Implement Quick Wins
3. Begin phased improvements
4. Set up testing infrastructure

**Web App:**
1. Review web architecture proposal
2. Set up Next.js project
3. Create database migrations
4. Build MVP (inventory + basic listing)
5. Add AI features
6. Integrate marketplaces

**Both:**
1. Review and prioritize recommendations with team
2. Create GitHub issues for approved items
3. Track success metrics
4. Iterate based on user feedback

**Questions or feedback?** Contact the development team.
