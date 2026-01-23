import 'package:flutter/material.dart';
import '../../models/scan_result.dart';
import '../../constants/app_constants.dart';

/// Widget displaying detailed price breakdown
///
/// Shows all components of the profit calculation:
/// - Market price
/// - Buy price
/// - Sales tax
/// - Platform fees
/// - Shipping cost
/// - Net profit
class PriceBreakdownWidget extends StatelessWidget {
  final ScanResult scanResult;

  const PriceBreakdownWidget({
    Key? key,
    required this.scanResult,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.calculate,
              size: IconSizes.base,
              color: Colors.blue.shade700,
            ),
            SizedBox(width: Spacing.sm),
            Text(
              'Profit Breakdown',
              style: TextStyle(
                fontSize: FontSizes.md,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: Spacing.md),

        // Price components
        _buildPriceRow(
          label: 'Market Price',
          value: scanResult.marketPrice,
          isPositive: true,
          tooltip: scanResult.marketPriceSource ?? 'Average selling price',
        ),
        _buildPriceRow(
          label: 'Buy Price',
          value: -scanResult.buyPrice,
          isNegative: true,
        ),
        if (scanResult.salesTaxAmount != null)
          _buildPriceRow(
            label: 'Sales Tax (${scanResult.salesTaxRate?.toStringAsFixed(1) ?? '8.0'}%)',
            value: -scanResult.salesTaxAmount!,
            isNegative: true,
          ),
        if (scanResult.feesAmount != null)
          _buildPriceRow(
            label: 'Platform Fees (${scanResult.feePercentage?.toStringAsFixed(1) ?? '15.0'}%)',
            value: -scanResult.feesAmount!,
            isNegative: true,
          ),
        if (scanResult.shippingCost != null && scanResult.shippingCost! > 0)
          _buildPriceRow(
            label: 'Shipping Cost',
            value: -scanResult.shippingCost!,
            isNegative: true,
          ),

        Divider(height: Spacing.base),

        // Net Profit
        _buildPriceRow(
          label: 'Net Profit',
          value: scanResult.netProfit,
          isTotal: true,
          isPositive: scanResult.netProfit >= 0,
          isNegative: scanResult.netProfit < 0,
        ),

        // Detailed calculation (expandable)
        if (scanResult.profitCalculation != null) ...[
          SizedBox(height: Spacing.sm),
          _buildCalculationDetails(context),
        ],
      ],
    );
  }

  Widget _buildPriceRow({
    required String label,
    required double value,
    bool isTotal = false,
    bool isPositive = false,
    bool isNegative = false,
    String? tooltip,
  }) {
    final widget = Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? FontSizes.md : FontSizes.base,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? null : Colors.grey.shade700,
            ),
          ),
          Text(
            '${value >= 0 ? '+' : ''}\$${value.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? FontSizes.md : FontSizes.base,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isPositive
                  ? Colors.green.shade700
                  : isNegative
                      ? Colors.red.shade700
                      : null,
            ),
          ),
        ],
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        child: widget,
      );
    }

    return widget;
  }

  Widget _buildCalculationDetails(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.all(Spacing.sm),
      title: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: IconSizes.sm,
            color: Colors.blue.shade700,
          ),
          SizedBox(width: Spacing.sm),
          Text(
            'See Calculation',
            style: TextStyle(
              fontSize: FontSizes.sm,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
      children: [
        Container(
          padding: EdgeInsets.all(Spacing.sm),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(BorderRadii.sm),
          ),
          child: Text(
            scanResult.profitCalculation!,
            style: TextStyle(
              fontSize: FontSizes.xs,
              fontFamily: 'monospace',
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
