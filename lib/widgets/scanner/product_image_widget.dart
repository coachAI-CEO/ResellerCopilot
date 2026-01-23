import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

/// Widget displaying product image from marketplace
///
/// Shows the product image retrieved from eBay/Amazon
/// with loading and error states
class ProductImageWidget extends StatelessWidget {
  final String imageUrl;
  final String productName;

  const ProductImageWidget({
    Key? key,
    required this.imageUrl,
    required this.productName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: ImageConstants.productImageHeight,
      margin: EdgeInsets.only(bottom: Spacing.base),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BorderRadii.md),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BorderRadii.md),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;

            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: IconSizes.lg,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: Spacing.sm),
                  Text(
                    'Image not available',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: FontSizes.sm,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
