import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/scan_result.dart';

class SupabaseService {
  final SupabaseClient _supabase;

  SupabaseService(this._supabase);

  /// Analyzes a product using the analyze-product edge function
  /// 
  /// [image] - The image file of the product (null on web)
  /// [imageBytes] - The image bytes (required on web, optional on mobile)
  /// [barcode] - Optional barcode string
  /// [price] - The store price of the product
  /// [condition] - Item condition: 'Used', 'New', or 'New in Box'
  /// 
  /// Returns a [ScanResult] with the analysis
  Future<ScanResult> analyzeItem({
    File? image,
    Uint8List? imageBytes,
    String? barcode,
    required double price,
    String condition = 'Used',
  }) async {
    try {
      // Verify user is authenticated and get fresh session
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('User not authenticated. Please log in first.');
      }

      // Refresh session to ensure we have a valid token
      try {
        final refreshedSession = await _supabase.auth.refreshSession();
        if (refreshedSession.session == null) {
          throw Exception('Failed to refresh session. Please log in again.');
        }
        // Verify the refreshed token is valid
        if (refreshedSession.session!.accessToken.isEmpty) {
          throw Exception('Invalid session token. Please log in again.');
        }
      } catch (e) {
        // If refresh fails, check if current session is still valid
        final currentSession = _supabase.auth.currentSession;
        if (currentSession == null || currentSession.accessToken.isEmpty) {
          throw Exception('Session expired. Please log in again.');
        }
        // Log the refresh error but continue with current session
        debugPrint('Session refresh warning: $e');
      }

      // Convert image to base64
      Uint8List bytes;
      if (imageBytes != null) {
        bytes = imageBytes;
      } else if (image != null) {
        bytes = await image.readAsBytes();
      } else {
        throw Exception('Either image or imageBytes must be provided');
      }
      final imageBase64 = base64Encode(bytes);

      // Prepare the request payload
      final payload = {
        'image_base64': imageBase64,
        if (barcode != null) 'barcode': barcode,
        'store_price': price,
        'condition': condition,
      };

      // Get the latest session token after potential refresh
      final currentSession = _supabase.auth.currentSession;
      if (currentSession == null || currentSession.accessToken.isEmpty) {
        throw Exception('No valid session token available. Please log in again.');
      }

      // Call the edge function
      // Supabase Flutter SDK automatically includes auth headers, but we can verify
      final response = await _supabase.functions.invoke(
        'analyze-product',
        body: payload,
      );

      if (response.status != 200) {
        final errorMessage = response.data is Map 
            ? (response.data as Map)['error']?.toString() ?? 
              (response.data as Map)['details']?.toString() ?? 
              'Unknown error'
            : response.data?.toString() ?? 'Unknown error';
        throw Exception('Failed to analyze product (${response.status}): $errorMessage');
      }

      final data = response.data as Map<String, dynamic>;

      // Create ScanResult from the response
      return ScanResult(
        productName: data['product_name'] as String? ?? 'Unknown Product',
        buyPrice: price,
        marketPrice: (data['market_price'] as num?)?.toDouble() ?? 0.0,
        netProfit: (data['net_profit'] as num?)?.toDouble() ?? 0.0,
        verdict: data['verdict'] as String? ?? 'PASS',
        velocityScore: data['velocity_score'] as String? ?? 'Med',
        barcode: barcode,
        ebayPrice: (data['ebay_price'] as num?)?.toDouble(),
        amazonPrice: (data['amazon_price'] as num?)?.toDouble(),
        currentPrice: (data['current_price'] as num?)?.toDouble(),
        marketPriceSource: data['market_price_source'] as String?,
        salesTaxRate: (data['sales_tax_rate'] as num?)?.toDouble(),
        salesTaxAmount: (data['sales_tax_amount'] as num?)?.toDouble(),
        feePercentage: (data['fee_percentage'] as num?)?.toDouble(),
        feesAmount: (data['fees_amount'] as num?)?.toDouble(),
        shippingCost: (data['shipping_cost'] as num?)?.toDouble(),
        profitCalculation: data['profit_calculation'] as String?,
        marketAnalysis: data['market_analysis'] as String?,
        condition: data['condition'] as String?,
      );
    } catch (e) {
      throw Exception('Error analyzing item: $e');
    }
  }

  /// Saves a scan result to the scans table
  /// 
  /// [scan] - The ScanResult to save
  /// 
  /// Returns the saved ScanResult with the generated id
  Future<ScanResult> saveScan(ScanResult scan) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Prepare the data for insertion
      final scanData = {
        'user_id': user.id,
        if (scan.barcode != null) 'barcode': scan.barcode,
        'product_name': scan.productName,
        'buy_price': scan.buyPrice,
        'market_price': scan.marketPrice,
        'net_profit': scan.netProfit,
        'verdict': scan.verdict,
        'velocity_score': scan.velocityScore,
        if (scan.ebayPrice != null) 'ebay_price': scan.ebayPrice,
        if (scan.amazonPrice != null) 'amazon_price': scan.amazonPrice,
        if (scan.currentPrice != null) 'current_price': scan.currentPrice,
        if (scan.marketPriceSource != null) 'market_price_source': scan.marketPriceSource,
        if (scan.salesTaxRate != null) 'sales_tax_rate': scan.salesTaxRate,
        if (scan.salesTaxAmount != null) 'sales_tax_amount': scan.salesTaxAmount,
        if (scan.feePercentage != null) 'fee_percentage': scan.feePercentage,
        if (scan.feesAmount != null) 'fees_amount': scan.feesAmount,
        if (scan.shippingCost != null) 'shipping_cost': scan.shippingCost,
        if (scan.profitCalculation != null) 'profit_calculation': scan.profitCalculation,
        if (scan.marketAnalysis != null) 'market_analysis': scan.marketAnalysis,
        if (scan.condition != null) 'condition': scan.condition,
      };

      // Insert into the scans table
      final response = await _supabase
          .from('scans')
          .insert(scanData)
          .select()
          .single();

      // Parse the response and return the ScanResult with id
      return ScanResult.fromJson(response);
    } catch (e) {
      throw Exception('Error saving scan: $e');
    }
  }

  /// Gets all scans for the current user
  Future<List<ScanResult>> getScans() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('scans')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ScanResult.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching scans: $e');
    }
  }
}
