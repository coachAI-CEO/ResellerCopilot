import 'package:flutter/material.dart';
import '../../models/scan_result.dart';
import '../../constants/app_constants.dart';
import 'product_image_widget.dart';
import 'price_breakdown_widget.dart';
import 'market_analysis_widget.dart';

/// Main verdict card displaying scan results
///
/// Shows:
/// - Product image
/// - BUY/PASS verdict with styling
/// - Price breakdown
/// - Market analysis
/// - Marketplace links
class VerdictCardWidget extends StatelessWidget {
  final ScanResult scanResult;

  const VerdictCardWidget({
    Key? key,
    required this.scanResult,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isBuy = scanResult.verdict == VerdictOptions.buy;

    return Container(
      padding: EdgeInsets.all(Spacing.base),
      decoration: BoxDecoration(
        color: isBuy ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(BorderRadii.lg),
        border: Border.all(
          color: isBuy ? Colors.green.shade300 : Colors.orange.shade300,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          if (scanResult.productImageUrl != null)
            ProductImageWidget(
              imageUrl: scanResult.productImageUrl!,
              productName: scanResult.productName,
            ),

          // Product Name
          Text(
            scanResult.productName,
            style: TextStyle(
              fontSize: FontSizes.xl,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Spacing.base),

          // Verdict Badge
          _buildVerdictBadge(isBuy),
          SizedBox(height: Spacing.base),

          // Key Metrics Row
          _buildMetricsRow(),
          SizedBox(height: Spacing.base),

          Divider(height: Spacing.lg),

          // Price Breakdown
          PriceBreakdownWidget(scanResult: scanResult),

          Divider(height: Spacing.lg),

          // Market Analysis
          if (scanResult.marketAnalysis != null)
            MarketAnalysisWidget(
              analysis: scanResult.marketAnalysis!,
            ),

          // Marketplace Links
          if (scanResult.ebayUrl != null || scanResult.amazonUrl != null) ...[
            Divider(height: Spacing.lg),
            _buildMarketplaceLinks(context),
          ],
        ],
      ),
    );
  }

  Widget _buildVerdictBadge(bool isBuy) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.base,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: isBuy ? Colors.green.shade700 : Colors.orange.shade700,
        borderRadius: BorderRadius.circular(BorderRadii.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBuy ? Icons.thumb_up : Icons.warning,
            color: Colors.white,
            size: IconSizes.lg,
          ),
          SizedBox(width: Spacing.sm),
          Text(
            scanResult.verdict,
            style: TextStyle(
              color: Colors.white,
              fontSize: FontSizes.heading,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetric(
          label: 'Net Profit',
          value: '\$${scanResult.netProfit.toStringAsFixed(2)}',
          color: scanResult.netProfit >= 0 ? Colors.green : Colors.red,
        ),
        _buildMetric(
          label: 'Buy Price',
          value: '\$${scanResult.buyPrice.toStringAsFixed(2)}',
        ),
        _buildMetric(
          label: 'Sell Price',
          value: '\$${scanResult.marketPrice.toStringAsFixed(2)}',
        ),
        _buildMetric(
          label: 'Velocity',
          value: scanResult.velocityScore,
          tooltip: _getVelocityTooltip(scanResult.velocityScore),
        ),
      ],
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    Color? color,
    String? tooltip,
  }) {
    final widget = Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: FontSizes.sm,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: Spacing.xs),
        Text(
          value,
          style: TextStyle(
            fontSize: FontSizes.md,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        child: widget,
      );
    }

    return widget;
  }

  String _getVelocityTooltip(String velocity) {
    switch (velocity) {
      case VelocityScores.high:
        return 'Sells quickly (< ${BusinessConstants.velocityHighDays} days)';
      case VelocityScores.medium:
        return 'Moderate sales (< ${BusinessConstants.velocityMediumDays} days)';
      case VelocityScores.low:
        return 'Slow sales (< ${BusinessConstants.velocityLowDays} days)';
      default:
        return velocity;
    }
  }

  Widget _buildMarketplaceLinks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'View on Marketplace',
          style: TextStyle(
            fontSize: FontSizes.base,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: Spacing.sm),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            if (scanResult.ebayUrl != null)
              _buildMarketplaceButton(
                context,
                label: 'eBay',
                url: scanResult.ebayUrl!,
                color: Colors.blue.shade700,
                icon: Icons.shopping_cart,
              ),
            if (scanResult.amazonUrl != null)
              _buildMarketplaceButton(
                context,
                label: 'Amazon',
                url: scanResult.amazonUrl!,
                color: Colors.orange.shade700,
                icon: Icons.shopping_bag,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMarketplaceButton(
    BuildContext context, {
    required String label,
    required String url,
    required Color color,
    required IconData icon,
  }) {
    return OutlinedButton.icon(
      onPressed: () => _launchUrl(context, url),
      icon: Icon(icon, size: IconSizes.sm),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    // Note: url_launcher package is already imported in scanner_screen
    // This is a placeholder - actual implementation would use url_launcher
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening: $url')),
    );
  }
}
