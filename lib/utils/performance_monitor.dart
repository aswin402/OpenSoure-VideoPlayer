import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Performance monitoring utility for tracking app performance
class PerformanceMonitor {
  static PerformanceMonitor? _instance;
  static PerformanceMonitor get instance =>
      _instance ??= PerformanceMonitor._();

  PerformanceMonitor._();

  final Map<String, DateTime> _operationStartTimes = {};
  final Map<String, List<Duration>> _operationDurations = {};
  final Map<String, int> _operationCounts = {};

  Timer? _memoryMonitorTimer;
  int _lastMemoryUsage = 0;

  /// Start monitoring an operation
  void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
  }

  /// End monitoring an operation and record its duration
  void endOperation(String operationName) {
    final startTime = _operationStartTimes.remove(operationName);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);

      _operationDurations.putIfAbsent(operationName, () => []);
      _operationDurations[operationName]!.add(duration);

      _operationCounts[operationName] =
          (_operationCounts[operationName] ?? 0) + 1;

      // Log slow operations in debug mode
      if (kDebugMode && duration.inMilliseconds > 1000) {
        debugPrint(
          'SLOW OPERATION: $operationName took ${duration.inMilliseconds}ms',
        );
      }
    }
  }

  /// Time an operation using a callback
  Future<T> timeOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    startOperation(operationName);
    try {
      final result = await operation();
      endOperation(operationName);
      return result;
    } catch (e) {
      endOperation(operationName);
      rethrow;
    }
  }

  /// Start memory monitoring
  void startMemoryMonitoring() {
    if (_memoryMonitorTimer != null) return;

    _memoryMonitorTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkMemoryUsage(),
    );
  }

  /// Stop memory monitoring
  void stopMemoryMonitoring() {
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = null;
  }

  /// Check current memory usage
  void _checkMemoryUsage() {
    if (!kDebugMode) return;

    try {
      final info = ProcessInfo.currentRss;
      final memoryMB = info ~/ (1024 * 1024);

      if (memoryMB > _lastMemoryUsage + 50) {
        // Alert on 50MB+ increase
        debugPrint('MEMORY ALERT: Usage increased to ${memoryMB}MB');
      }

      _lastMemoryUsage = memoryMB;
    } catch (e) {
      // Memory monitoring not available on this platform
    }
  }

  /// Get performance statistics
  Map<String, dynamic> getStats() {
    final stats = <String, dynamic>{};

    for (final operation in _operationDurations.keys) {
      final durations = _operationDurations[operation]!;
      final count = _operationCounts[operation]!;

      if (durations.isNotEmpty) {
        final totalMs = durations.fold<int>(
          0,
          (sum, duration) => sum + duration.inMilliseconds,
        );
        final avgMs = totalMs / durations.length;
        final maxMs = durations
            .map((d) => d.inMilliseconds)
            .reduce((a, b) => a > b ? a : b);
        final minMs = durations
            .map((d) => d.inMilliseconds)
            .reduce((a, b) => a < b ? a : b);

        stats[operation] = {
          'count': count,
          'avgMs': avgMs.round(),
          'maxMs': maxMs,
          'minMs': minMs,
          'totalMs': totalMs,
        };
      }
    }

    return stats;
  }

  /// Print performance report
  void printReport() {
    if (!kDebugMode) return;

    final stats = getStats();
    if (stats.isEmpty) {
      debugPrint('No performance data collected');
      return;
    }

    debugPrint('=== PERFORMANCE REPORT ===');
    for (final entry in stats.entries) {
      final operation = entry.key;
      final data = entry.value as Map<String, dynamic>;

      debugPrint(
        '$operation: ${data['count']} calls, '
        'avg: ${data['avgMs']}ms, '
        'max: ${data['maxMs']}ms, '
        'min: ${data['minMs']}ms',
      );
    }
    debugPrint('========================');
  }

  /// Clear all collected data
  void clear() {
    _operationStartTimes.clear();
    _operationDurations.clear();
    _operationCounts.clear();
  }

  /// Get slow operations (> threshold)
  List<String> getSlowOperations({int thresholdMs = 1000}) {
    final slowOps = <String>[];

    for (final entry in _operationDurations.entries) {
      final operation = entry.key;
      final durations = entry.value;

      final hasSlowCalls = durations.any(
        (duration) => duration.inMilliseconds > thresholdMs,
      );

      if (hasSlowCalls) {
        slowOps.add(operation);
      }
    }

    return slowOps;
  }
}

/// Mixin for classes that want to monitor their performance
mixin PerformanceMonitored {
  final PerformanceMonitor _monitor = PerformanceMonitor.instance;

  /// Time an operation
  Future<T> timeOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) {
    return _monitor.timeOperation(operationName, operation);
  }

  /// Start timing an operation
  void startTiming(String operationName) {
    _monitor.startOperation(operationName);
  }

  /// End timing an operation
  void endTiming(String operationName) {
    _monitor.endOperation(operationName);
  }
}
