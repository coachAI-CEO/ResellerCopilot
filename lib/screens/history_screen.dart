import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/scan_result.dart';
import '../services/supabase_service.dart';
import '../constants/app_constants.dart';
import '../widgets/scanner/scanner_widgets.dart';

/// Screen displaying user's scan history
///
/// Features:
/// - Filter by verdict (All/Buy/Pass)
/// - Search by product name
/// - Sort by date, profit, or name
/// - Swipe to delete
/// - Export to CSV
class HistoryScreen extends StatefulWidget {
  final SupabaseService supabaseService;

  const HistoryScreen({
    Key? key,
    required this.supabaseService,
  }) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScanResult> _allScans = [];
  List<ScanResult> _filteredScans = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filter and sort state
  String _selectedFilter = 'All'; // All, BUY, PASS
  String _searchQuery = '';
  SortOption _sortOption = SortOption.date;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadScans();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadScans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final scans = await widget.supabaseService.getScans();
      setState(() {
        _allScans = scans;
        _applyFiltersAndSort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    var filtered = List<ScanResult>.from(_allScans);

    // Apply verdict filter
    if (_selectedFilter != 'All') {
      filtered = filtered.where((scan) => scan.verdict == _selectedFilter).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((scan) {
        return scan.productName.toLowerCase().contains(query) ||
            (scan.barcode?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply sorting
    switch (_sortOption) {
      case SortOption.date:
        filtered.sort((a, b) {
          final aDate = a.createdAt ?? DateTime.now();
          final bDate = b.createdAt ?? DateTime.now();
          return bDate.compareTo(aDate); // Newest first
        });
        break;
      case SortOption.profit:
        filtered.sort((a, b) => b.netProfit.compareTo(a.netProfit)); // Highest first
        break;
      case SortOption.name:
        filtered.sort((a, b) => a.productName.compareTo(b.productName)); // A-Z
        break;
    }

    setState(() {
      _filteredScans = filtered;
    });
  }

  Future<void> _deleteScan(ScanResult scan) async {
    try {
      if (scan.id != null) {
        await widget.supabaseService.deleteScan(scan.id!);
      }

      setState(() {
        _allScans.removeWhere((s) => s.id == scan.id);
        _applyFiltersAndSort();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${scan.productName} deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete scan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final csv = _generateCSV(_filteredScans);

      // TODO: Implement file saving with path_provider and share
      // For now, just show a dialog with the CSV content
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export to CSV'),
            content: SingleChildScrollView(
              child: SelectableText(
                csv,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${_filteredScans.length} scans to CSV'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _generateCSV(List<ScanResult> scans) {
    final buffer = StringBuffer();

    // Header row
    buffer.writeln(
      'Date,Product Name,Barcode,Condition,Buy Price,Market Price,Net Profit,Verdict,Velocity Score'
    );

    // Data rows
    for (final scan in scans) {
      final date = scan.createdAt != null
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(scan.createdAt!)
          : 'N/A';

      buffer.writeln(
        '"$date","${_escapeCsv(scan.productName)}","${scan.barcode ?? ''}","${scan.condition ?? ''}",${scan.buyPrice},${scan.marketPrice},${scan.netProfit},${scan.verdict},${scan.velocityScore}'
      );
    }

    return buffer.toString();
  }

  String _escapeCsv(String value) {
    return value.replaceAll('"', '""');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          // Export button
          if (_filteredScans.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportToCSV,
              tooltip: 'Export to CSV',
            ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadScans,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(Spacing.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by product name or barcode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _applyFiltersAndSort();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(BorderRadii.lg),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: Spacing.base,
                  vertical: Spacing.md,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFiltersAndSort();
                });
              },
            ),
          ),

          // Filter chips and sort dropdown
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Spacing.md),
            child: Row(
              children: [
                // Filter chips
                Expanded(
                  child: Wrap(
                    spacing: Spacing.sm,
                    children: [
                      FilterChip(
                        label: Text('All (${_allScans.length})'),
                        selected: _selectedFilter == 'All',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedFilter = 'All';
                              _applyFiltersAndSort();
                            });
                          }
                        },
                      ),
                      FilterChip(
                        label: Text(
                          'Buy (${_allScans.where((s) => s.verdict == 'BUY').length})',
                        ),
                        selected: _selectedFilter == 'BUY',
                        selectedColor: Colors.green.shade100,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedFilter = 'BUY';
                              _applyFiltersAndSort();
                            });
                          }
                        },
                      ),
                      FilterChip(
                        label: Text(
                          'Pass (${_allScans.where((s) => s.verdict == 'PASS').length})',
                        ),
                        selected: _selectedFilter == 'PASS',
                        selectedColor: Colors.red.shade100,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedFilter = 'PASS';
                              _applyFiltersAndSort();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Sort dropdown
                SizedBox(width: Spacing.sm),
                DropdownButton<SortOption>(
                  value: _sortOption,
                  icon: const Icon(Icons.sort),
                  underline: Container(),
                  items: const [
                    DropdownMenuItem(
                      value: SortOption.date,
                      child: Text('Date'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.profit,
                      child: Text('Profit'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.name,
                      child: Text('Name'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortOption = value;
                        _applyFiltersAndSort();
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: Spacing.sm),

          // Results count
          if (!_isLoading && _filteredScans.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Spacing.md),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Showing ${_filteredScans.length} of ${_allScans.length} scans',
                  style: TextStyle(
                    fontSize: FontSizes.sm,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),

          SizedBox(height: Spacing.sm),

          // Scan list
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: IconSizes.xl,
              color: Colors.red.shade300,
            ),
            SizedBox(height: Spacing.base),
            Text(
              'Failed to load scans',
              style: TextStyle(
                fontSize: FontSizes.md,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Spacing.sm),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Spacing.xl),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: FontSizes.sm,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            SizedBox(height: Spacing.base),
            ElevatedButton.icon(
              onPressed: _loadScans,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredScans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty || _selectedFilter != 'All'
                  ? Icons.search_off
                  : Icons.history,
              size: IconSizes.xl,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: Spacing.base),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'All'
                  ? 'No matching scans found'
                  : 'No scan history yet',
              style: TextStyle(
                fontSize: FontSizes.md,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Spacing.sm),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'All'
                  ? 'Try adjusting your filters'
                  : 'Start scanning products to see them here',
              style: TextStyle(
                fontSize: FontSizes.sm,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadScans,
      child: ListView.builder(
        padding: EdgeInsets.all(Spacing.md),
        itemCount: _filteredScans.length,
        itemBuilder: (context, index) {
          final scan = _filteredScans[index];
          return _buildScanCard(scan);
        },
      ),
    );
  }

  Widget _buildScanCard(ScanResult scan) {
    return Dismissible(
      key: Key(scan.id ?? 'scan_$scan.productName'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: Spacing.base),
        margin: EdgeInsets.only(bottom: Spacing.md),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(BorderRadii.lg),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Scan'),
            content: Text('Delete "${scan.productName}" from history?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => _deleteScan(scan),
      child: Card(
        margin: EdgeInsets.only(bottom: Spacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BorderRadii.lg),
        ),
        elevation: 2,
        child: InkWell(
          onTap: () => _showScanDetails(scan),
          borderRadius: BorderRadius.circular(BorderRadii.lg),
          child: Padding(
            padding: EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Product name and verdict
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image thumbnail
                    if (scan.productImageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(BorderRadii.sm),
                        child: Image.network(
                          scan.productImageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey.shade400,
                              ),
                            );
                          },
                        ),
                      ),
                    if (scan.productImageUrl != null) SizedBox(width: Spacing.md),

                    // Product info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scan.productName,
                            style: TextStyle(
                              fontSize: FontSizes.md,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: Spacing.xs),
                          if (scan.barcode != null)
                            Text(
                              'Barcode: ${scan.barcode}',
                              style: TextStyle(
                                fontSize: FontSizes.xs,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          if (scan.condition != null)
                            Text(
                              'Condition: ${scan.condition}',
                              style: TextStyle(
                                fontSize: FontSizes.xs,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Verdict badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Spacing.md,
                        vertical: Spacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: scan.verdict == 'BUY'
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(BorderRadii.lg),
                      ),
                      child: Text(
                        scan.verdict,
                        style: TextStyle(
                          fontSize: FontSizes.sm,
                          fontWeight: FontWeight.bold,
                          color: scan.verdict == 'BUY'
                              ? Colors.green.shade900
                              : Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: Spacing.md),

                // Price info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPriceInfo(
                      label: 'Buy Price',
                      value: scan.buyPrice,
                      color: Colors.grey.shade700,
                    ),
                    _buildPriceInfo(
                      label: 'Market Price',
                      value: scan.marketPrice,
                      color: Colors.blue.shade700,
                    ),
                    _buildPriceInfo(
                      label: 'Net Profit',
                      value: scan.netProfit,
                      color: scan.netProfit >= 0
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ],
                ),

                SizedBox(height: Spacing.sm),

                // Footer: Date and velocity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.speed,
                          size: IconSizes.sm,
                          color: _getVelocityColor(scan.velocityScore),
                        ),
                        SizedBox(width: Spacing.xs),
                        Text(
                          '${scan.velocityScore} Velocity',
                          style: TextStyle(
                            fontSize: FontSizes.xs,
                            color: _getVelocityColor(scan.velocityScore),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (scan.createdAt != null)
                      Text(
                        _formatDate(scan.createdAt!),
                        style: TextStyle(
                          fontSize: FontSizes.xs,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInfo({
    required String label,
    required double value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: FontSizes.xs,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: Spacing.xs),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: FontSizes.md,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getVelocityColor(String velocity) {
    switch (velocity.toLowerCase()) {
      case 'high':
        return Colors.green.shade700;
      case 'med':
      case 'medium':
        return Colors.orange.shade700;
      case 'low':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  void _showScanDetails(ScanResult scan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BorderRadii.xl),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(Spacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      scan.productName,
                      style: TextStyle(
                        fontSize: FontSizes.lg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              SizedBox(height: Spacing.base),

              // Product image
              if (scan.productImageUrl != null)
                ProductImageWidget(imageUrl: scan.productImageUrl!),

              SizedBox(height: Spacing.base),

              // Price breakdown
              PriceBreakdownWidget(scanResult: scan),

              SizedBox(height: Spacing.base),

              // Market analysis
              if (scan.marketAnalysis != null)
                MarketAnalysisWidget(analysis: scan.marketAnalysis!),

              SizedBox(height: Spacing.base),

              // Marketplace links
              if (scan.ebayUrl != null || scan.amazonUrl != null) ...[
                Text(
                  'Marketplace Links',
                  style: TextStyle(
                    fontSize: FontSizes.md,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: Spacing.sm),
                if (scan.ebayUrl != null)
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: const Text('View on eBay'),
                    subtitle: scan.ebayPrice != null
                        ? Text('\$${scan.ebayPrice!.toStringAsFixed(2)}')
                        : null,
                    onTap: () {
                      // TODO: Launch URL
                    },
                  ),
                if (scan.amazonUrl != null)
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: const Text('View on Amazon'),
                    subtitle: scan.amazonPrice != null
                        ? Text('\$${scan.amazonPrice!.toStringAsFixed(2)}')
                        : null,
                    onTap: () {
                      // TODO: Launch URL
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum SortOption {
  date,
  profit,
  name,
}
