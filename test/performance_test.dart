import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mxclone/utils/performance_utils.dart';
import 'package:mxclone/utils/performance_monitor.dart';
import 'package:mxclone/services/thumbnail_cache_service.dart';

void main() {
  group('Performance Utils Tests', () {
    test('batched processing should work correctly', () async {
      final items = List.generate(100, (i) => i);
      final processed = <int>[];

      await PerformanceUtils.processBatched(
        items,
        (item) async {
          processed.add(item);
          await Future.delayed(Duration(milliseconds: 1));
        },
        batchSize: 10,
        batchDelay: Duration(milliseconds: 5),
      );

      expect(processed.length, equals(100));
      expect(processed, equals(items));
    });

    test('debounce should work correctly', () async {
      int callCount = 0;
      Timer? timer;

      // Rapid calls should be debounced
      for (int i = 0; i < 5; i++) {
        timer = PerformanceUtils.debounce(
          timer,
          Duration(milliseconds: 100),
          () => callCount++,
        );
        await Future.delayed(Duration(milliseconds: 10));
      }

      // Wait for debounce to complete
      await Future.delayed(Duration(milliseconds: 150));

      expect(callCount, equals(1));
    });

    test('throttle should limit call frequency', () {
      final lastCalls = <String, DateTime>{};

      // First call should succeed
      expect(
        PerformanceUtils.throttle(
          lastCalls,
          'test',
          Duration(milliseconds: 100),
        ),
        isTrue,
      );

      // Immediate second call should be throttled
      expect(
        PerformanceUtils.throttle(
          lastCalls,
          'test',
          Duration(milliseconds: 100),
        ),
        isFalse,
      );
    });

    test('lazy loading should cache results', () async {
      final cache = <String, String>{};
      final timestamps = <String, DateTime>{};
      int loadCount = 0;

      // First load
      final result1 = await PerformanceUtils.lazyLoad(
        'test',
        () async {
          loadCount++;
          return 'loaded_data';
        },
        cache,
        timestamps: timestamps,
      );

      // Second load should use cache
      final result2 = await PerformanceUtils.lazyLoad(
        'test',
        () async {
          loadCount++;
          return 'loaded_data';
        },
        cache,
        timestamps: timestamps,
      );

      expect(result1, equals('loaded_data'));
      expect(result2, equals('loaded_data'));
      expect(loadCount, equals(1)); // Should only load once
    });
  });

  group('Performance Monitor Tests', () {
    late PerformanceMonitor monitor;

    setUp(() {
      monitor = PerformanceMonitor.instance;
      monitor.clear();
    });

    test('should track operation timing', () async {
      await monitor.timeOperation('test_op', () async {
        await Future.delayed(Duration(milliseconds: 50));
      });

      final stats = monitor.getStats();
      expect(stats.containsKey('test_op'), isTrue);
      expect(stats['test_op']['count'], equals(1));
      expect(stats['test_op']['avgMs'], greaterThan(40));
    });

    test('should identify slow operations', () async {
      // Fast operation
      await monitor.timeOperation('fast_op', () async {
        await Future.delayed(Duration(milliseconds: 10));
      });

      // Slow operation
      await monitor.timeOperation('slow_op', () async {
        await Future.delayed(Duration(milliseconds: 1100));
      });

      final slowOps = monitor.getSlowOperations(thresholdMs: 1000);
      expect(slowOps, contains('slow_op'));
      expect(slowOps, isNot(contains('fast_op')));
    });
  });

  group('Thumbnail Cache Tests', () {
    late ThumbnailCacheService cache;

    setUp(() {
      cache = ThumbnailCacheService.instance;
    });

    test('should generate correct cache keys', () {
      // Using reflection to test private method would require additional setup
      // For now, test the public interface
      expect(
        cache.hasCachedThumbnail('/test/file.mp4', 1024, 1234567890),
        isFalse,
      );
    });

    test('should return null for non-existent thumbnails', () {
      final path = cache.getCachedThumbnailPath(
        '/non/existent/file.mp4',
        1024,
        1234567890,
      );
      expect(path, isNull);
    });

    test('should provide cache statistics', () {
      final stats = cache.getCacheStats();
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('memoryCache'), isTrue);
      expect(stats.containsKey('diskCache'), isTrue);
      expect(stats.containsKey('maxMemorySize'), isTrue);
    });
  });
}
