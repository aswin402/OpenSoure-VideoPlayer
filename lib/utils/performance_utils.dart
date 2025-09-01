import 'dart:async';
import 'package:flutter/foundation.dart';

/// Performance utilities for better app responsiveness
class PerformanceUtils {
  static const int _defaultBatchSize = 10;
  static const Duration _defaultBatchDelay = Duration(milliseconds: 16);

  /// Process items in batches to avoid blocking the UI thread
  static Future<void> processBatched<T>(
    List<T> items,
    Future<void> Function(T item) processor, {
    int batchSize = _defaultBatchSize,
    Duration batchDelay = _defaultBatchDelay,
    bool Function()? shouldCancel,
  }) async {
    for (int i = 0; i < items.length; i += batchSize) {
      if (shouldCancel?.call() == true) break;

      final batch = items.skip(i).take(batchSize);
      final futures = batch.map(processor).toList();

      try {
        await Future.wait(futures);
      } catch (e) {
        debugPrint('Batch processing error: $e');
      }

      // Yield control back to the UI thread
      if (i + batchSize < items.length) {
        await Future.delayed(batchDelay);
      }
    }
  }

  /// Debounce function calls to reduce frequency
  static Timer? debounce(
    Timer? previous,
    Duration delay,
    VoidCallback callback,
  ) {
    previous?.cancel();
    return Timer(delay, callback);
  }

  /// Throttle function calls to limit frequency
  static bool throttle(
    Map<String, DateTime> lastCalls,
    String key,
    Duration minInterval,
  ) {
    final now = DateTime.now();
    final lastCall = lastCalls[key];

    if (lastCall == null || now.difference(lastCall) >= minInterval) {
      lastCalls[key] = now;
      return true;
    }

    return false;
  }

  /// Memory-efficient lazy loading helper
  static Future<T> lazyLoad<T>(
    String key,
    Future<T> Function() loader,
    Map<String, T> cache, {
    Duration? maxAge,
    Map<String, DateTime>? timestamps,
  }) async {
    // Check if cached and still valid
    if (cache.containsKey(key)) {
      if (maxAge == null || timestamps == null) {
        return cache[key]!;
      }

      final timestamp = timestamps[key];
      if (timestamp != null && DateTime.now().difference(timestamp) < maxAge) {
        return cache[key]!;
      }
    }

    // Load and cache
    final result = await loader();
    cache[key] = result;
    timestamps?[key] = DateTime.now();

    return result;
  }

  /// Clean up old cache entries
  static void cleanupCache<T>(
    Map<String, T> cache,
    Map<String, DateTime> timestamps,
    Duration maxAge,
  ) {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final entry in timestamps.entries) {
      if (now.difference(entry.value) > maxAge) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      cache.remove(key);
      timestamps.remove(key);
    }
  }

  /// Execute with timeout and fallback
  static Future<T> withTimeout<T>(
    Future<T> future,
    Duration timeout,
    T fallback,
  ) async {
    try {
      return await future.timeout(timeout);
    } catch (e) {
      debugPrint('Operation timed out: $e');
      return fallback;
    }
  }

  /// Rate limiter for expensive operations
  static Future<T?> rateLimit<T>(
    String key,
    Future<T> Function() operation,
    Duration minInterval,
    Map<String, DateTime> lastExecutions,
  ) async {
    final now = DateTime.now();
    final lastExecution = lastExecutions[key];

    if (lastExecution != null && now.difference(lastExecution) < minInterval) {
      return null; // Rate limited
    }

    lastExecutions[key] = now;
    return await operation();
  }
}

/// Mixin for providers that need performance optimizations
mixin PerformanceOptimizedProvider {
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, DateTime> _throttleTimestamps = {};
  final Map<String, DateTime> _rateLimitTimestamps = {};

  /// Debounce a callback
  void debounceCallback(String key, Duration delay, VoidCallback callback) {
    final timer = PerformanceUtils.debounce(
      _debounceTimers[key],
      delay,
      callback,
    );
    if (timer != null) {
      _debounceTimers[key] = timer;
    }
  }

  /// Check if operation should be throttled
  bool shouldThrottle(String key, Duration minInterval) {
    return !PerformanceUtils.throttle(_throttleTimestamps, key, minInterval);
  }

  /// Execute with rate limiting
  Future<T?> executeRateLimited<T>(
    String key,
    Future<T> Function() operation,
    Duration minInterval,
  ) {
    return PerformanceUtils.rateLimit(
      key,
      operation,
      minInterval,
      _rateLimitTimestamps,
    );
  }

  /// Clean up timers and timestamps
  void disposePerformanceUtils() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _throttleTimestamps.clear();
    _rateLimitTimestamps.clear();
  }
}
