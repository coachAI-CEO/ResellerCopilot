import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';
import '../models/scan_result.dart';

class ScannerScreen extends StatefulWidget {
  final SupabaseService supabaseService;

  const ScannerScreen({
    Key? key,
    required this.supabaseService,
  }) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _barcode;
  final TextEditingController _priceController = TextEditingController();
  String _condition = 'Used'; // Default to 'Used'
  bool _isAnalyzing = false;
  ScanResult? _scanResult;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        final imageBytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = imageBytes;
          if (!kIsWeb) {
          _selectedImage = File(image.path);
          }
          _scanResult = null; // Clear previous result
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _scanProduct() async {
    if (_selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a photo first')),
      );
      return;
    }

    final priceText = _priceController.text.trim();
    if (priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the store price')),
      );
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _scanResult = null;
    });

    try {
      // Analyze the product
      final result = await widget.supabaseService.analyzeItem(
        image: kIsWeb ? null : _selectedImage!,
        imageBytes: _selectedImageBytes!,
        barcode: _barcode,
        price: price,
        condition: _condition,
      );

      // Save the scan to the database
      final savedResult = await widget.supabaseService.saveScan(result);

      setState(() {
        _scanResult = savedResult;
        _isAnalyzing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis complete: ${savedResult.verdict}'),
            backgroundColor: savedResult.verdict == 'BUY' 
                ? Colors.green 
                : Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing product: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reseller Copilot'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Camera Preview Section
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _selectedImageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? Image.memory(
                              _selectedImageBytes!,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No image selected',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Camera Button
            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Price Input
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Store Price (\$)',
                hintText: 'Enter the price',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !_isAnalyzing,
            ),
            const SizedBox(height: 16),

            // Barcode Input (Optional)
            TextField(
              onChanged: (value) => _barcode = value.isEmpty ? null : value,
              decoration: InputDecoration(
                labelText: 'Barcode (Optional)',
                hintText: 'Enter barcode if available',
                prefixIcon: const Icon(Icons.qr_code_scanner),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              enabled: !_isAnalyzing,
            ),
            const SizedBox(height: 16),

            // Condition Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Item Condition',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildConditionButton('Used', Icons.shopping_bag),
                      ),
                      Expanded(
                        child: _buildConditionButton('New', Icons.new_releases),
                      ),
                      Expanded(
                        child: _buildConditionButton('New in Box', Icons.inventory_2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Scan Button
            ElevatedButton(
              onPressed: _isAnalyzing ? null : _scanProduct,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: _isAnalyzing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Analyze Product',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 24),

            // Results Section
            if (_scanResult != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _scanResult!.verdict == 'BUY'
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _scanResult!.verdict == 'BUY'
                        ? Colors.green.shade300
                        : Colors.orange.shade300,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Photo from Marketplace
                    if (_scanResult!.productImageUrl != null) ...[
                      Container(
                        width: double.infinity,
                        height: 200,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _scanResult!.productImageUrl!,
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
                                color: Colors.grey.shade200,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported, 
                                         size: 48, 
                                         color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Image not available',
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ] else if (_selectedImageBytes != null) ...[
                      // Fallback to scanned photo if product image not available
                      Container(
                        width: double.infinity,
                        height: 200,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              kIsWeb
                                  ? Image.memory(
                                      _selectedImageBytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : _selectedImage != null
                                      ? Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.memory(
                                          _selectedImageBytes!,
                                          fit: BoxFit.cover,
                                        ),
                              // Overlay label
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Scanned Photo',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Verdict: ${_scanResult!.verdict}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _scanResult!.verdict == 'BUY'
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                        Tooltip(
                          message: _scanResult!.velocityScore == 'High'
                              ? 'High Velocity: Sells quickly (days/weeks). Fast inventory turnover, high demand items.'
                              : _scanResult!.velocityScore == 'Med'
                                  ? 'Med Velocity: Sells at moderate pace (weeks/months). Steady demand, average inventory turnover.'
                                  : 'Low Velocity: Sells slowly (months+). Limited demand, may take longer to sell.',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _scanResult!.velocityScore == 'High'
                                  ? Colors.green.shade200
                                  : _scanResult!.velocityScore == 'Med'
                                      ? Colors.orange.shade200
                                      : Colors.red.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Velocity: ${_scanResult!.velocityScore}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.info_outline,
                                  size: 14,
                                  color: _scanResult!.velocityScore == 'High'
                                      ? Colors.green.shade700
                                      : _scanResult!.velocityScore == 'Med'
                                          ? Colors.orange.shade700
                                          : Colors.red.shade700,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Product', _scanResult!.productName, allowWrap: true),
                    if (_scanResult!.condition != null)
                      _buildInfoRow('Condition', _scanResult!.condition!),
                    _buildInfoRow('Buy Price', '\$${_scanResult!.buyPrice.toStringAsFixed(2)}'),
                    const Divider(height: 24),
                    _buildInfoRow(
                      'eBay Price', 
                      _scanResult!.ebayPrice != null 
                        ? '\$${_scanResult!.ebayPrice!.toStringAsFixed(2)}'
                        : 'N/A',
                      isMissing: _scanResult!.ebayPrice == null,
                      url: _scanResult!.ebayUrl,
                    ),
                    _buildInfoRow(
                      'Amazon Price', 
                      _scanResult!.amazonPrice != null 
                        ? '\$${_scanResult!.amazonPrice!.toStringAsFixed(2)}'
                        : 'Not available',
                      isMissing: _scanResult!.amazonPrice == null,
                      url: _scanResult!.amazonUrl,
                    ),
                    if (_scanResult!.currentPrice != null)
                      _buildInfoRow(
                        'Current Listing Price', 
                        '\$${_scanResult!.currentPrice!.toStringAsFixed(2)}',
                        tooltip: 'Lowest price you could buy this item for right now',
                      ),
                    _buildInfoRow(
                      'Market Price (Sell Price)', 
                      '\$${_scanResult!.marketPrice.toStringAsFixed(2)}',
                      tooltip: 'Estimated price you can sell this for (based on recent sold listings)',
                      isImportant: true,
                    ),
                    if (_scanResult!.marketPriceSource != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Source: ${_scanResult!.marketPriceSource}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Divider(height: 24),
                    // Profit Calculation Breakdown
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profit Calculation',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_scanResult!.salesTaxAmount != null)
                            _buildCalculationRow(
                              'Sales Tax (${_scanResult!.salesTaxRate?.toStringAsFixed(1) ?? 8}%)',
                              '-\$${_scanResult!.salesTaxAmount!.toStringAsFixed(2)}',
                            ),
                          if (_scanResult!.feesAmount != null)
                            _buildCalculationRow(
                              'Platform Fees (${_scanResult!.feePercentage?.toStringAsFixed(0) ?? 15}%)',
                              '-\$${_scanResult!.feesAmount!.toStringAsFixed(2)}',
                            ),
                          if (_scanResult!.shippingCost != null)
                            _buildCalculationRow(
                              'Shipping Cost',
                              '-\$${_scanResult!.shippingCost!.toStringAsFixed(2)}',
                            ),
                          const Divider(height: 16),
                          _buildInfoRow(
                            'Net Profit',
                            '\$${_scanResult!.netProfit.toStringAsFixed(2)}',
                            isProfit: true,
                          ),
                          if (_scanResult!.profitCalculation != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calculate, size: 14, color: Colors.blue.shade700),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _scanResult!.profitCalculation!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue.shade700,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Market Analysis Section
              if (_scanResult!.marketAnalysis != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Market Analysis',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMarketAnalysisText(_scanResult!.marketAnalysis!),
                  ],
                ),
              ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMarketAnalysisText(String analysis) {
    // Parse and format the market analysis text
    final lines = analysis.split('\n');
    final List<Widget> widgets = [];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }
      
      // Check for section headers (lines ending with ':' or specific section names)
      final sectionHeaders = ['Market Analysis', 'The Item', 'Why it\'s good', 'Why it\'s good:', 
                              'Scarcity', 'Scarcity:', 'The Data', 'The Data:', 
                              'The Buy Cost', 'The Buy Cost:', 'Strategy', 'Strategy:',
                              'Warnings', 'Warnings:', 'Warning', 'Warning:',
                              'Summary', 'Summary:'];
      final isSectionHeader = (line.endsWith(':') && line.length < 50) || 
                              sectionHeaders.any((header) => line == header || line == '$header:');
      
      if (isSectionHeader) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              line.endsWith(':') ? line : '$line:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        );
      } else if (line.startsWith('- ') || line.startsWith('• ')) {
        // Bullet points
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: Colors.blue.shade700, fontSize: 16)),
                Expanded(
                  child: Text(
                    line.substring(2),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Regular text
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              line,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                height: 1.5,
              ),
            ),
          ),
        );
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isProfit = false, bool isMissing = false, String? tooltip, bool isImportant = false, bool allowWrap = false, String? url}) {
    Widget labelWidget = Text(
      label,
      style: TextStyle(
        fontSize: isImportant ? 17 : 16,
        color: Colors.grey.shade700,
        fontWeight: isImportant ? FontWeight.w600 : FontWeight.normal,
      ),
    );
    
    if (tooltip != null) {
      labelWidget = Tooltip(
        message: tooltip,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            labelWidget,
            const SizedBox(width: 4),
            Icon(Icons.info_outline, size: 14, color: Colors.grey.shade500),
          ],
        ),
      );
    }
    
    // If wrapping is allowed (like for product names), use Column layout
    if (allowWrap) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labelWidget,
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: isImportant ? 17 : 16,
                fontWeight: FontWeight.bold,
                color: isProfit
                    ? (_scanResult!.netProfit >= 0
                        ? Colors.green.shade700
                        : Colors.red.shade700)
                    : isMissing
                        ? Colors.grey.shade500
                        : isImportant
                            ? Colors.blue.shade700
                            : Colors.black87,
                fontStyle: isMissing ? FontStyle.italic : FontStyle.normal,
              ),
              maxLines: null,
              softWrap: true,
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: labelWidget,
            flex: 1,
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: url != null && url.isNotEmpty
                ? InkWell(
                    onTap: () async {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: isImportant ? 17 : 16,
                              fontWeight: FontWeight.bold,
                              color: isProfit
                                  ? (_scanResult!.netProfit >= 0
                                      ? Colors.green.shade700
                                      : Colors.red.shade700)
                                  : isMissing
                                      ? Colors.grey.shade500
                                      : isImportant
                                          ? Colors.blue.shade700
                                          : Colors.blue.shade600,
                              fontStyle: isMissing ? FontStyle.italic : FontStyle.normal,
                              decoration: TextDecoration.underline,
                              decorationColor: isMissing ? Colors.grey.shade500 : Colors.blue.shade600,
                            ),
                            textAlign: TextAlign.end,
                            maxLines: null,
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.open_in_new,
                          size: 14,
                          color: isMissing ? Colors.grey.shade500 : Colors.blue.shade600,
                        ),
                      ],
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: isImportant ? 17 : 16,
                      fontWeight: FontWeight.bold,
                      color: isProfit
                          ? (_scanResult!.netProfit >= 0
                              ? Colors.green.shade700
                              : Colors.red.shade700)
                          : isMissing
                              ? Colors.grey.shade500
                              : isImportant
                                  ? Colors.blue.shade700
                                  : Colors.black87,
                      fontStyle: isMissing ? FontStyle.italic : FontStyle.normal,
                    ),
                    textAlign: TextAlign.end,
                    maxLines: null,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionButton(String condition, IconData icon) {
    final isSelected = _condition == condition;
    return GestureDetector(
      onTap: _isAnalyzing ? null : () {
        setState(() {
          _condition = condition;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade700 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(height: 4),
            Text(
              condition,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
