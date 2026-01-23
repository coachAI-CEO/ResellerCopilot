import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/cache_service.dart';
import '../services/offline_service.dart';
import '../constants/app_constants.dart';

/// Screen for app settings and preferences
///
/// Features:
/// - Cache management (view stats, clear cache)
/// - Offline queue management (view queue, retry, clear)
/// - User preferences
/// - Account settings (logout)
/// - About section
class SettingsScreen extends StatefulWidget {
  final CacheService cacheService;
  final OfflineService offlineService;

  const SettingsScreen({
    Key? key,
    required this.cacheService,
    required this.offlineService,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  CacheStatistics? _cacheStats;
  OfflineStatistics? _offlineStats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();

    // Listen to offline queue updates
    widget.offlineService.queueSize.listen((size) {
      _loadStatistics();
    });

    // Listen to network status changes
    widget.offlineService.networkStatus.listen((isOnline) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _loadStatistics() async {
    try {
      final cacheStats = await widget.cacheService.getStatistics();
      final offlineStats = await widget.offlineService.getStatistics();

      if (mounted) {
        setState(() {
          _cacheStats = cacheStats;
          _offlineStats = offlineStats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will remove all cached scan results. You may need to wait longer for future scans of the same products.',
        ),
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
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.cacheService.clearCache();
        await _loadStatistics();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cache cleared successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear cache: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _clearExpiredCache() async {
    try {
      await widget.cacheService.clearExpiredCache();
      await _loadStatistics();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expired cache entries removed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear expired cache: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _retryQueuedScans() async {
    if (!widget.offlineService.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot retry: Device is offline'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Retrying queued scans...'),
        ),
      );

      final result = await widget.offlineService.retryQueuedScans();
      await _loadStatistics();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.successful > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Retry failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearQueue() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Queue'),
        content: const Text(
          'This will permanently remove all queued scans. They will not be saved to your history.',
        ),
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
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.offlineService.clearQueue();
        await _loadStatistics();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Queue cleared successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear queue: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _viewQueuedScans() async {
    try {
      final queuedScans = await widget.offlineService.getQueuedScans();

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(BorderRadii.xl),
          ),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Padding(
                padding: EdgeInsets.all(Spacing.base),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Queued Scans',
                      style: TextStyle(
                        fontSize: FontSizes.lg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: queuedScans.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: IconSizes.xl,
                              color: Colors.green.shade300,
                            ),
                            SizedBox(height: Spacing.base),
                            const Text('No scans in queue'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.all(Spacing.md),
                        itemCount: queuedScans.length,
                        itemBuilder: (context, index) {
                          final queued = queuedScans[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: Spacing.md),
                            child: ListTile(
                              title: Text(queued.scanResult.productName),
                              subtitle: Text(
                                'Queued: ${_formatDateTime(queued.queuedAt)}',
                                style: TextStyle(fontSize: FontSizes.xs),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await widget.offlineService.removeFromQueue(
                                    queued.scanResult.id ?? '',
                                  );
                                  Navigator.pop(context);
                                  _loadStatistics();
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load queued scans: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
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
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.auth.signOut();
        // Navigation is handled by AuthWrapper
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Network Status Banner
          if (!widget.offlineService.isOnline)
            Container(
              color: Colors.orange.shade100,
              padding: EdgeInsets.all(Spacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off,
                    color: Colors.orange.shade700,
                  ),
                  SizedBox(width: Spacing.md),
                  Expanded(
                    child: Text(
                      'You are offline. Scans will be queued for retry.',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Account Section
          _buildSectionHeader('Account'),
          if (user != null) ...[
            ListTile(
              leading: CircleAvatar(
                child: Text(user.email?.substring(0, 1).toUpperCase() ?? 'U'),
              ),
              title: Text(user.email ?? 'Unknown'),
              subtitle: const Text('Logged in'),
            ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: _logout,
          ),

          const Divider(height: 32, thickness: 2),

          // Cache Management Section
          _buildSectionHeader('Cache Management'),
          if (_isLoadingStats)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('Cache Statistics'),
              subtitle: _cacheStats != null
                  ? Text(
                      'Total: ${_cacheStats!.totalEntries} | '
                      'Valid: ${_cacheStats!.validEntries} | '
                      'Expired: ${_cacheStats!.expiredEntries}\n'
                      'Hit Rate: ${(_cacheStats!.hitRate * 100).toStringAsFixed(1)}%',
                    )
                  : const Text('No statistics available'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('Clear Expired Cache'),
              subtitle: const Text('Remove only expired cache entries'),
              onTap: _clearExpiredCache,
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Clear All Cache'),
              subtitle: const Text('Remove all cached scan results'),
              onTap: _clearCache,
            ),
          ],

          const Divider(height: 32, thickness: 2),

          // Offline Queue Section
          _buildSectionHeader('Offline Queue'),
          if (_isLoadingStats)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            ListTile(
              leading: const Icon(Icons.queue),
              title: const Text('Queue Statistics'),
              subtitle: _offlineStats != null
                  ? Text(
                      'Queued Scans: ${_offlineStats!.queueSize}\n'
                      'Total Failed: ${_offlineStats!.totalFailedScans}\n'
                      'Status: ${_offlineStats!.isOnline ? "Online" : "Offline"}',
                    )
                  : const Text('No statistics available'),
            ),
            if (_offlineStats != null && _offlineStats!.queueSize > 0) ...[
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('View Queued Scans'),
                subtitle: Text('${_offlineStats!.queueSize} scans in queue'),
                onTap: _viewQueuedScans,
              ),
              ListTile(
                leading: Icon(
                  Icons.sync,
                  color: widget.offlineService.isOnline ? Colors.blue : Colors.grey,
                ),
                title: const Text('Retry Queued Scans'),
                subtitle: const Text('Attempt to save all queued scans'),
                enabled: widget.offlineService.isOnline,
                onTap: widget.offlineService.isOnline ? _retryQueuedScans : null,
              ),
              ListTile(
                leading: const Icon(Icons.clear_all, color: Colors.red),
                title: const Text('Clear Queue'),
                subtitle: const Text('Permanently remove all queued scans'),
                onTap: _clearQueue,
              ),
            ],
          ],

          const Divider(height: 32, thickness: 2),

          // About Section
          _buildSectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Version'),
            subtitle: const Text('1.0.0+1'),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Report an Issue'),
            subtitle: const Text('Help us improve the app'),
            onTap: () {
              // TODO: Open issue reporting
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            onTap: () {
              // TODO: Open privacy policy
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            onTap: () {
              // TODO: Open terms of service
            },
          ),

          SizedBox(height: Spacing.xl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Spacing.base,
        Spacing.base,
        Spacing.base,
        Spacing.xs,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: FontSizes.sm,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
