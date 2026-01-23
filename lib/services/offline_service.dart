import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/scan_result.dart';
import 'supabase_service.dart';

/// Service for handling offline functionality
///
/// Features:
/// - Queues failed scans for retry when online
/// - Monitors network connectivity
/// - Automatically retries queued scans when connection is restored
/// - Persists queue across app restarts
class OfflineService {
  static const String _queueKey = 'offline_scan_queue';
  static const String _failedScansKey = 'failed_scans_count';

  final SupabaseService _supabaseService;
  final Connectivity _connectivity = Connectivity();

  // Stream controller for network status
  final _networkStatusController = StreamController<bool>.broadcast();
  Stream<bool> get networkStatus => _networkStatusController.stream;

  // Stream controller for queue updates
  final _queueUpdateController = StreamController<int>.broadcast();
  Stream<int> get queueSize => _queueUpdateController.stream;

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;
  bool _isRetrying = false;

  OfflineService(this._supabaseService) {
    _initializeConnectivity();
  }

  /// Initializes connectivity monitoring
  Future<void> _initializeConnectivity() async {
    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _isOnline = result != ConnectivityResult.none;
      _networkStatusController.add(_isOnline);

      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (ConnectivityResult result) {
          final wasOnline = _isOnline;
          _isOnline = result != ConnectivityResult.none;
          _networkStatusController.add(_isOnline);

          debugPrint('Connectivity changed: ${result.name} (online: $_isOnline)');

          // If we just came online, retry queued scans
          if (!wasOnline && _isOnline && !_isRetrying) {
            _retryQueuedScans();
          }
        },
      );
    } catch (e) {
      debugPrint('Error initializing connectivity: $e');
      // Assume online if we can't check
      _isOnline = true;
      _networkStatusController.add(true);
    }
  }

  /// Checks if device is currently online
  bool get isOnline => _isOnline;

  /// Gets the current queue size
  Future<int> getQueueSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);
      if (queueJson == null) return 0;

      final queue = jsonDecode(queueJson) as List;
      return queue.length;
    } catch (e) {
      debugPrint('Error getting queue size: $e');
      return 0;
    }
  }

  /// Adds a scan to the offline queue
  Future<void> queueScan(QueuedScan queuedScan) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load existing queue
      final queueJson = prefs.getString(_queueKey);
      List<dynamic> queue = queueJson != null ? jsonDecode(queueJson) : [];

      // Add new scan
      queue.add(queuedScan.toJson());

      // Save queue
      await prefs.setString(_queueKey, jsonEncode(queue));

      // Update queue size stream
      _queueUpdateController.add(queue.length);

      // Increment failed scans count
      final failedCount = prefs.getInt(_failedScansKey) ?? 0;
      await prefs.setInt(_failedScansKey, failedCount + 1);

      debugPrint('Queued scan: ${queuedScan.scanResult.productName} (Queue size: ${queue.length})');
    } catch (e) {
      debugPrint('Error queueing scan: $e');
    }
  }

  /// Gets all queued scans
  Future<List<QueuedScan>> getQueuedScans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);
      if (queueJson == null) return [];

      final queue = jsonDecode(queueJson) as List;
      return queue
          .map((json) => QueuedScan.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting queued scans: $e');
      return [];
    }
  }

  /// Retries all queued scans
  Future<RetryResult> retryQueuedScans() async {
    return await _retryQueuedScans();
  }

  Future<RetryResult> _retryQueuedScans() async {
    if (_isRetrying) {
      debugPrint('Already retrying queued scans');
      return RetryResult(
        successful: 0,
        failed: 0,
        message: 'Retry already in progress',
      );
    }

    _isRetrying = true;
    debugPrint('Starting retry of queued scans');

    try {
      final queuedScans = await getQueuedScans();
      if (queuedScans.isEmpty) {
        debugPrint('No scans in queue');
        _isRetrying = false;
        return RetryResult(
          successful: 0,
          failed: 0,
          message: 'No scans to retry',
        );
      }

      int successful = 0;
      int failed = 0;
      final failedScans = <QueuedScan>[];

      for (final queuedScan in queuedScans) {
        try {
          // Attempt to save the scan
          await _supabaseService.saveScan(queuedScan.scanResult);
          successful++;
          debugPrint('Successfully saved queued scan: ${queuedScan.scanResult.productName}');
        } catch (e) {
          failed++;
          failedScans.add(queuedScan);
          debugPrint('Failed to save queued scan: ${queuedScan.scanResult.productName} - $e');
        }
      }

      // Update queue with only failed scans
      await _saveQueue(failedScans);
      _queueUpdateController.add(failedScans.length);

      debugPrint('Retry complete: $successful successful, $failed failed');

      _isRetrying = false;
      return RetryResult(
        successful: successful,
        failed: failed,
        message: successful > 0
            ? 'Successfully saved $successful scan(s)'
            : 'Failed to save scans. Will retry when online.',
      );
    } catch (e) {
      debugPrint('Error during retry: $e');
      _isRetrying = false;
      return RetryResult(
        successful: 0,
        failed: 0,
        message: 'Retry failed: $e',
      );
    }
  }

  /// Saves the queue to persistent storage
  Future<void> _saveQueue(List<QueuedScan> queue) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (queue.isEmpty) {
        await prefs.remove(_queueKey);
      } else {
        final queueJson = jsonEncode(queue.map((s) => s.toJson()).toList());
        await prefs.setString(_queueKey, queueJson);
      }
    } catch (e) {
      debugPrint('Error saving queue: $e');
    }
  }

  /// Clears the entire queue
  Future<void> clearQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_queueKey);
      _queueUpdateController.add(0);
      debugPrint('Queue cleared');
    } catch (e) {
      debugPrint('Error clearing queue: $e');
    }
  }

  /// Removes a specific scan from the queue
  Future<void> removeFromQueue(String scanId) async {
    try {
      final queuedScans = await getQueuedScans();
      final updatedQueue = queuedScans
          .where((scan) => scan.scanResult.id != scanId)
          .toList();

      await _saveQueue(updatedQueue);
      _queueUpdateController.add(updatedQueue.length);
      debugPrint('Removed scan from queue: $scanId');
    } catch (e) {
      debugPrint('Error removing scan from queue: $e');
    }
  }

  /// Gets statistics about offline operations
  Future<OfflineStatistics> getStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueSize = await getQueueSize();
      final failedCount = prefs.getInt(_failedScansKey) ?? 0;

      return OfflineStatistics(
        queueSize: queueSize,
        totalFailedScans: failedCount,
        isOnline: _isOnline,
      );
    } catch (e) {
      debugPrint('Error getting offline statistics: $e');
      return OfflineStatistics(
        queueSize: 0,
        totalFailedScans: 0,
        isOnline: _isOnline,
      );
    }
  }

  /// Resets offline statistics
  Future<void> resetStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_failedScansKey);
      debugPrint('Offline statistics reset');
    } catch (e) {
      debugPrint('Error resetting statistics: $e');
    }
  }

  /// Disposes resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _networkStatusController.close();
    _queueUpdateController.close();
  }
}

/// Represents a scan that is queued for retry
class QueuedScan {
  final ScanResult scanResult;
  final DateTime queuedAt;
  final int retryCount;

  QueuedScan({
    required this.scanResult,
    required this.queuedAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'scan_result': scanResult.toJson(),
      'queued_at': queuedAt.toIso8601String(),
      'retry_count': retryCount,
    };
  }

  factory QueuedScan.fromJson(Map<String, dynamic> json) {
    return QueuedScan(
      scanResult: ScanResult.fromJson(json['scan_result'] as Map<String, dynamic>),
      queuedAt: DateTime.parse(json['queued_at'] as String),
      retryCount: json['retry_count'] as int? ?? 0,
    );
  }
}

/// Result of a retry operation
class RetryResult {
  final int successful;
  final int failed;
  final String message;

  RetryResult({
    required this.successful,
    required this.failed,
    required this.message,
  });
}

/// Statistics about offline operations
class OfflineStatistics {
  final int queueSize;
  final int totalFailedScans;
  final bool isOnline;

  OfflineStatistics({
    required this.queueSize,
    required this.totalFailedScans,
    required this.isOnline,
  });

  @override
  String toString() {
    return 'OfflineStatistics(queue: $queueSize, total failed: $totalFailedScans, online: $isOnline)';
  }
}
