/// Application-wide constants for the Reseller Copilot app
///
/// This file contains all magic numbers and configuration values
/// used throughout the application. Centralizing these values:
/// - Makes the code more maintainable
/// - Provides single source of truth for configuration
/// - Makes it easy to adjust values globally
library app_constants;

// =============================================================================
// Image Settings
// =============================================================================

class ImageConstants {
  /// Quality for image compression (0-100)
  /// Lower = smaller file size, higher = better quality
  static const int compressionQuality = 85;

  /// Quality for picked images from camera (0-100)
  static const int pickerImageQuality = 85;

  /// Compression quality for image processing (0-100)
  static const int processingQuality = 70;

  /// Maximum image size in bytes (5MB)
  static const int maxImageSizeBytes = 5 * 1024 * 1024;

  /// Image preview height in scanner screen
  static const double previewHeight = 300.0;

  /// Product image display height in results
  static const double productImageHeight = 200.0;
}

// =============================================================================
// Spacing Constants
// =============================================================================

class Spacing {
  /// Extra small spacing (4px)
  static const double xs = 4.0;

  /// Small spacing (8px)
  static const double sm = 8.0;

  /// Medium spacing (12px)
  static const double md = 12.0;

  /// Default spacing (16px)
  static const double base = 16.0;

  /// Large spacing (24px)
  static const double lg = 24.0;

  /// Extra large spacing (32px)
  static const double xl = 32.0;

  /// Extra extra large spacing (48px)
  static const double xxl = 48.0;
}

// =============================================================================
// Border Radius
// =============================================================================

class BorderRadii {
  /// Small border radius (4px)
  static const double sm = 4.0;

  /// Medium border radius (8px)
  static const double md = 8.0;

  /// Large border radius (12px)
  static const double lg = 12.0;

  /// Extra large border radius (16px)
  static const double xl = 16.0;

  /// Extra extra large border radius (20px)
  static const double xxl = 20.0;
}

// =============================================================================
// Typography / Font Sizes
// =============================================================================

class FontSizes {
  /// Extra small text (11px)
  static const double xs = 11.0;

  /// Small text (12px)
  static const double sm = 12.0;

  /// Base text (14px)
  static const double base = 14.0;

  /// Medium text (16px)
  static const double md = 16.0;

  /// Large text (18px)
  static const double lg = 18.0;

  /// Extra large text (20px)
  static const double xl = 20.0;

  /// Heading text (24px)
  static const double heading = 24.0;

  /// Display text (48px)
  static const double display = 48.0;
}

// =============================================================================
// Icon Sizes
// =============================================================================

class IconSizes {
  /// Small icon (14px)
  static const double sm = 14.0;

  /// Medium icon (16px)
  static const double md = 16.0;

  /// Base icon (20px)
  static const double base = 20.0;

  /// Large icon (48px)
  static const double lg = 48.0;

  /// Extra large icon (64px)
  static const double xl = 64.0;

  /// Logo size (80px)
  static const double logo = 80.0;
}

// =============================================================================
// Durations (for animations and timeouts)
// =============================================================================

class Durations {
  /// Short animation duration
  static const Duration short = Duration(milliseconds: 150);

  /// Medium animation duration
  static const Duration medium = Duration(milliseconds: 300);

  /// Long animation duration
  static const Duration long = Duration(milliseconds: 500);

  /// API request timeout
  static const Duration apiTimeout = Duration(seconds: 30);

  /// Long API timeout (for AI operations)
  static const Duration longApiTimeout = Duration(seconds: 60);

  /// Retry delay for failed operations
  static const Duration retryDelay = Duration(seconds: 2);

  /// Cache duration
  static const Duration cacheDuration = Duration(hours: 24);

  /// Session refresh interval
  static const Duration sessionRefreshInterval = Duration(minutes: 45);
}

// =============================================================================
// Business Logic Constants
// =============================================================================

class BusinessConstants {
  /// Default sales tax rate (percentage)
  static const double defaultSalesTaxRate = 8.0;

  /// Default platform fee percentage
  static const double defaultPlatformFee = 15.0;

  /// Default shipping cost (USD)
  static const double defaultShippingCost = 5.0;

  /// Minimum profit threshold for BUY recommendation (USD)
  static const double minProfitThreshold = 10.0;

  /// Minimum ROI percentage for BUY recommendation
  static const double minRoiPercentage = 50.0;

  /// Maximum price for auto-approval (USD)
  static const double maxAutoApprovePrice = 100.0;

  /// Velocity score thresholds (days)
  static const int velocityHighDays = 14;
  static const int velocityMediumDays = 30;
  static const int velocityLowDays = 90;
}

// =============================================================================
// Validation Constants
// =============================================================================

class ValidationConstants {
  /// Minimum password length
  static const int minPasswordLength = 6;

  /// Maximum password length
  static const int maxPasswordLength = 128;

  /// Maximum price value (USD)
  static const double maxPrice = 10000.0;

  /// Minimum price value (USD)
  static const double minPrice = 0.01;

  /// Maximum barcode length
  static const int maxBarcodeLength = 20;

  /// Minimum barcode length (EAN-8)
  static const int minBarcodeLength = 8;

  /// Email regex pattern
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
}

// =============================================================================
// Storage Keys (for shared preferences / local storage)
// =============================================================================

class StorageKeys {
  /// Last used condition preference
  static const String lastCondition = 'last_condition';

  /// Preferred currency
  static const String preferredCurrency = 'preferred_currency';

  /// Enable notifications
  static const String notificationsEnabled = 'notifications_enabled';

  /// Theme mode (light/dark)
  static const String themeMode = 'theme_mode';

  /// Last sync timestamp
  static const String lastSyncTimestamp = 'last_sync_timestamp';

  /// Onboarding completed flag
  static const String onboardingCompleted = 'onboarding_completed';

  /// Cached user profile
  static const String cachedUserProfile = 'cached_user_profile';
}

// =============================================================================
// API Endpoints & Configuration
// =============================================================================

class ApiConstants {
  /// Analyze product edge function name
  static const String analyzeProductFunction = 'analyze-product';

  /// Scans table name
  static const String scansTable = 'scans';

  /// Storage bucket for scan images
  static const String scansBucket = 'scans-temp';

  /// Signed URL expiration (seconds)
  static const int signedUrlExpiration = 60;

  /// Maximum retry attempts for failed requests
  static const int maxRetryAttempts = 3;

  /// Retry delay multiplier (exponential backoff)
  static const double retryDelayMultiplier = 2.0;
}

// =============================================================================
// Condition Options
// =============================================================================

class ConditionOptions {
  static const String used = 'Used';
  static const String new_ = 'New';
  static const String newInBox = 'New in Box';

  static const List<String> all = [used, new_, newInBox];
}

// =============================================================================
// Verdict Options
// =============================================================================

class VerdictOptions {
  static const String buy = 'BUY';
  static const String pass = 'PASS';
  static const String maybe = 'MAYBE';

  static const List<String> all = [buy, pass, maybe];
}

// =============================================================================
// Velocity Scores
// =============================================================================

class VelocityScores {
  static const String high = 'High';
  static const String medium = 'Med';
  static const String low = 'Low';

  static const List<String> all = [high, medium, low];
}

// =============================================================================
// Color Values (hex codes for custom colors)
// =============================================================================

class ColorValues {
  /// Success green
  static const int successGreen = 0xFF2E7D32;

  /// Warning orange
  static const int warningOrange = 0xFFF57C00;

  /// Error red
  static const int errorRed = 0xFFD32F2F;

  /// Primary blue
  static const int primaryBlue = 0xFF1976D2;

  /// Secondary blue
  static const int secondaryBlue = 0xFF1565C0;
}

// =============================================================================
// Z-Index / Elevation
// =============================================================================

class Elevation {
  static const double none = 0.0;
  static const double sm = 1.0;
  static const double md = 2.0;
  static const double lg = 4.0;
  static const double xl = 8.0;
  static const double xxl = 16.0;
}

// =============================================================================
// Grid / Layout
// =============================================================================

class LayoutConstants {
  /// Maximum content width for wide screens
  static const double maxContentWidth = 1200.0;

  /// Breakpoint for mobile screens
  static const double mobileBreakpoint = 600.0;

  /// Breakpoint for tablet screens
  static const double tabletBreakpoint = 900.0;

  /// Breakpoint for desktop screens
  static const double desktopBreakpoint = 1200.0;

  /// Standard card aspect ratio
  static const double cardAspectRatio = 16 / 9;

  /// Grid column count for mobile
  static const int mobileGridColumns = 1;

  /// Grid column count for tablet
  static const int tabletGridColumns = 2;

  /// Grid column count for desktop
  static const int desktopGridColumns = 3;
}

// =============================================================================
// Analytics Event Names
// =============================================================================

class AnalyticsEvents {
  static const String scanStarted = 'scan_started';
  static const String scanCompleted = 'scan_completed';
  static const String scanFailed = 'scan_failed';
  static const String userSignedUp = 'user_signed_up';
  static const String userLoggedIn = 'user_logged_in';
  static const String userLoggedOut = 'user_logged_out';
  static const String productViewed = 'product_viewed';
  static const String marketplaceLinkClicked = 'marketplace_link_clicked';
}
