import 'package:freezed_annotation/freezed_annotation.dart';

part 'scan_result.freezed.dart';
part 'scan_result.g.dart';

@freezed
abstract class ScanResult with _$ScanResult {
  const factory ScanResult({
    String? id,
    @JsonKey(name: 'user_id') String? userId,
    String? barcode,
    @JsonKey(name: 'product_name') required String productName,
    @JsonKey(name: 'buy_price') required double buyPrice,
    @JsonKey(name: 'market_price') required double marketPrice,
    @JsonKey(name: 'net_profit') required double netProfit,
    required String verdict, // 'BUY' or 'PASS'
    @JsonKey(name: 'velocity_score') required String velocityScore, // 'High', 'Med', 'Low'
    @JsonKey(name: 'ebay_price') double? ebayPrice,
    @JsonKey(name: 'ebay_url') String? ebayUrl,
  @JsonKey(name: 'ebay_search_url') String? ebaySearchUrl,
    @JsonKey(name: 'amazon_price') double? amazonPrice,
    @JsonKey(name: 'amazon_url') String? amazonUrl,
  @JsonKey(name: 'amazon_search_url') String? amazonSearchUrl,
    @JsonKey(name: 'current_price') double? currentPrice,
    @JsonKey(name: 'market_price_source') String? marketPriceSource,
    @JsonKey(name: 'fee_percentage') double? feePercentage,
    @JsonKey(name: 'fees_amount') double? feesAmount,
    @JsonKey(name: 'shipping_cost') double? shippingCost,
    @JsonKey(name: 'sales_tax_rate') double? salesTaxRate,
    @JsonKey(name: 'sales_tax_amount') double? salesTaxAmount,
    @JsonKey(name: 'profit_calculation') String? profitCalculation,
    @JsonKey(name: 'market_analysis') String? marketAnalysis,
    @JsonKey(name: 'condition') String? condition,
    @JsonKey(name: 'product_image_url') String? productImageUrl,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ScanResult;

  factory ScanResult.fromJson(Map<String, dynamic> json) =>
      _$ScanResultFromJson(json);
}
