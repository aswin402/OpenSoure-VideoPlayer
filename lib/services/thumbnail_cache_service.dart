import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Optimized thumbnail caching service for better performance
class ThumbnailCacheService {
  static ThumbnailCacheService? _instance;
  static ThumbnailCacheService get instance =>
      _instance ??= ThumbnailCacheService._();

  ThumbnailCacheService._();

  Directory? _cacheDir;
  final Map<String, String> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  static const Duration _maxCacheAge = Duration(days: 7);
  static const int _maxMemoryCacheSize = 100;

  /// Initialize the cache service
  Future<void> initialize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      _cacheDir = Directory(p.join(tempDir.path, 'mxclone_thumbs'));

      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }

      // Clean up old cache entries on startup
      _cleanupOldEntries();
    } catch (e) {
      debugPrint('Failed to initialize thumbnail cache: $e');
    }
  }

  /// Get cache key for a file
  String _getCacheKey(String filePath, int fileSize, int lastModified) {
    final baseName = p.basenameWithoutExtension(filePath);
    return '${baseName}_${fileSize}_$lastModified.jpg';
  }

  /// Check if thumbnail exists in cache
  bool hasCachedThumbnail(String filePath, int fileSize, int lastModified) {
    if (_cacheDir == null) return false;

    final key = _getCacheKey(filePath, fileSize, lastModified);

    // Check memory cache first
    if (_memoryCache.containsKey(key)) {
      return true;
    }

    // Check disk cache
    final file = File(p.join(_cacheDir!.path, key));
    return file.existsSync();
  }

  /// Get cached thumbnail path
  String? getCachedThumbnailPath(
    String filePath,
    int fileSize,
    int lastModified,
  ) {
    if (_cacheDir == null) return null;

    final key = _getCacheKey(filePath, fileSize, lastModified);

    // Check memory cache first
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }

    // Check disk cache
    final file = File(p.join(_cacheDir!.path, key));
    if (file.existsSync()) {
      final path = file.path;

      // Add to memory cache
      _addToMemoryCache(key, path);

      return path;
    }

    return null;
  }

  /// Cache a thumbnail
  Future<String?> cacheThumbnail(
    String filePath,
    int fileSize,
    int lastModified,
    String thumbnailPath,
  ) async {
    if (_cacheDir == null) return null;

    try {
      final key = _getCacheKey(filePath, fileSize, lastModified);
      final targetPath = p.join(_cacheDir!.path, key);

      // Copy thumbnail to cache directory
      final sourceFile = File(thumbnailPath);
      if (await sourceFile.exists()) {
        final targetFile = await sourceFile.copy(targetPath);

        // Add to memory cache
        _addToMemoryCache(key, targetFile.path);

        // Update timestamp
        _cacheTimestamps[key] = DateTime.now();

        return targetFile.path;
      }
    } catch (e) {
      debugPrint('Failed to cache thumbnail: $e');
    }

    return null;
  }

  /// Add to memory cache with size limit
  void _addToMemoryCache(String key, String path) {
    // Remove oldest entries if cache is full
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      final oldestKey = _memoryCache.keys.first;
      _memoryCache.remove(oldestKey);
    }

    _memoryCache[key] = path;
  }

  /// Clean up old cache entries
  void _cleanupOldEntries() {
    if (_cacheDir == null) return;

    try {
      final now = DateTime.now();
      final files = _cacheDir!.listSync();

      for (final file in files) {
        if (file is File) {
          final stat = file.statSync();
          final age = now.difference(stat.modified);

          if (age > _maxCacheAge) {
            file.deleteSync();

            // Remove from memory cache if present
            final fileName = p.basename(file.path);
            _memoryCache.remove(fileName);
            _cacheTimestamps.remove(fileName);
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to cleanup old cache entries: $e');
    }
  }

  /// Clear all cached thumbnails
  Future<void> clearCache() async {
    try {
      if (_cacheDir != null && await _cacheDir!.exists()) {
        await _cacheDir!.delete(recursive: true);
        await _cacheDir!.create(recursive: true);
      }

      _memoryCache.clear();
      _cacheTimestamps.clear();
    } catch (e) {
      debugPrint('Failed to clear thumbnail cache: $e');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final diskFiles = _cacheDir?.listSync().length ?? 0;

    return {
      'memoryCache': _memoryCache.length,
      'diskCache': diskFiles,
      'maxMemorySize': _maxMemoryCacheSize,
      'cacheDir': _cacheDir?.path,
    };
  }
}
