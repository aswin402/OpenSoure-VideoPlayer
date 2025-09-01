import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/media_file.dart';
import '../models/playlist.dart' as mx;
import '../services/file_service.dart';
import '../services/settings_service.dart';
import '../utils/performance_utils.dart';
import '../utils/performance_monitor.dart';

class MediaProvider extends ChangeNotifier
    with PerformanceOptimizedProvider, PerformanceMonitored {
  final FileService _fileService = FileService();
  final SettingsService _settingsService = SettingsService();

  List<MediaFile> _allFiles = [];
  List<MediaFile> _filteredFiles = [];
  final List<mx.Playlist> _playlists = [];
  MediaFile? _currentFile;
  mx.Playlist? _currentPlaylist;
  int _currentIndex = 0;
  bool _isLoading = false;
  String _searchQuery = '';
  MediaType _filterType = MediaType.video;
  SortBy _sortBy = SortBy.name;
  bool _sortAscending = true;
  Timer? _debounce;

  // Background enrichment control
  bool _enrichmentCancelled = false;
  bool _isInitialized = false;
  bool _isInitializing = false;

  // Getters
  List<MediaFile> get allFiles => _allFiles;
  List<MediaFile> get filteredFiles => _filteredFiles;
  List<mx.Playlist> get playlists => _playlists;
  MediaFile? get currentFile => _currentFile;
  mx.Playlist? get currentPlaylist => _currentPlaylist;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  MediaType get filterType => _filterType;
  SortBy get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;
  bool get isInitialized => _isInitialized;

  // Recently played cache
  List<MediaFile> _recentFiles = [];
  List<MediaFile> get recentFiles => _recentFiles;

  bool get hasNext =>
      _currentPlaylist != null &&
      _currentIndex < _currentPlaylist!.files.length - 1;
  bool get hasPrevious => _currentPlaylist != null && _currentIndex > 0;

  // Non-blocking initialization for better startup performance
  void initializeAsync() {
    if (_isInitialized || _isInitializing) return;
    _isInitializing = true;

    // Initialize in background without blocking UI
    Future.microtask(() async {
      try {
        await _settingsService.initialize();
        debugPrint('MediaProvider: SettingsService initialized');

        // Load recent files first (faster)
        await _loadRecentFiles();

        // Then load cached files or scan
        await loadFiles();

        _isInitialized = true;
        debugPrint('MediaProvider: Initialization complete');
      } catch (e) {
        debugPrint('MediaProvider: Error during initialization: $e');
      } finally {
        _isInitializing = false;
      }
    });
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_isInitializing) {
      // Wait for async initialization to complete
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    debugPrint('MediaProvider: Starting synchronous initialization...');
    _isInitializing = true;
    try {
      await _settingsService.initialize();
      debugPrint('MediaProvider: SettingsService initialized');
      // Load from cache if available, otherwise scan
      await loadFiles();
      // Load recent files list
      await _loadRecentFiles();
      _isInitialized = true;
      debugPrint('MediaProvider: Initialization complete');
    } catch (e) {
      debugPrint('MediaProvider: Error during initialization: $e');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _loadRecentFiles() async {
    final recentPaths = _settingsService.recentFiles;
    final existing = <MediaFile>[];
    for (final path in recentPaths) {
      try {
        final file = MediaFile.fromFile(File(path));
        existing.add(file);
      } catch (_) {}
    }
    _recentFiles = existing;
    // Enrich recent files quickly in background
    _backgroundEnrich(_recentFiles);
    notifyListeners();
  }

  Future<void> loadFiles({
    bool force = false,
    bool regenerateThumbnails = false,
  }) async {
    return timeOperation('loadFiles', () async {
      debugPrint(
        'MediaProvider: Loading files (force: $force, regenThumbs: $regenerateThumbnails)...',
      );
      _setLoading(true);
      try {
        if (force || _settingsService.shouldRescan()) {
          await timeOperation('scanDirectories', () async {
            debugPrint('MediaProvider: Scanning directories...');
            _allFiles = await _fileService.getCommonMediaDirectories()
              ..addAll(await _fileService.scanCustomFormats());
            debugPrint('MediaProvider: Found ${_allFiles.length} files');
            await _settingsService.setLastScanTime(DateTime.now());
            await _settingsService.setCachedFiles(
              _allFiles.map((f) => f.path).toList(),
            );
          });
        } else {
          await timeOperation('loadFromCache', () async {
            debugPrint('MediaProvider: Loading from cache...');
            final cachedFiles = _settingsService.getCachedFiles();
            _allFiles = cachedFiles
                .map((path) {
                  try {
                    return MediaFile.fromFile(File(path));
                  } catch (e) {
                    debugPrint(
                      'Error creating MediaFile from cached path $path: $e',
                    );
                    return null;
                  }
                })
                .where((file) => file != null)
                .cast<MediaFile>()
                .toList();

            // Enrich cached entries (duration + thumbnails for videos) in background
            _backgroundEnrich(_allFiles, forceThumbnails: regenerateThumbnails);

            debugPrint(
              'MediaProvider: Loaded ${_allFiles.length} files from cache',
            );
          });
        }
        _applyFilters();
        debugPrint(
          'MediaProvider: Applied filters, ${_filteredFiles.length} files visible',
        );
      } catch (e) {
        debugPrint('Error loading files: $e');
      } finally {
        _setLoading(false);
      }
    });
  }

  Future<void> scanDirectory(String path) async {
    _setLoading(true);
    try {
      final files = await _fileService.scanDirectory(path);
      _allFiles.addAll(files);
      // Persist cache so it survives restarts
      await _settingsService.setCachedFiles(
        _allFiles.map((f) => f.path).toList(),
      );
      await _settingsService.setLastScanTime(DateTime.now());
      // Enrich newly scanned entries in background
      _backgroundEnrich(files);
      _removeDuplicates();
      _applyFilters();
    } catch (e) {
      debugPrint('Error scanning directory: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> selectAndScanDirectory() async {
    try {
      final path = await _fileService.pickDirectory();
      if (path != null && path.isNotEmpty) {
        await scanDirectory(path);
      }
    } catch (e) {
      debugPrint('Error selecting or scanning directory: $e');
    }
  }

  Future<void> addFiles() async {
    try {
      final files = await _fileService.pickFiles();
      _allFiles.addAll(files);
      // Persist cache so it survives restarts
      await _settingsService.setCachedFiles(
        _allFiles.map((f) => f.path).toList(),
      );
      await _settingsService.setLastScanTime(DateTime.now());
      // Enrich newly added entries in background
      _backgroundEnrich(files);
      _removeDuplicates();
      _applyFilters();
    } catch (e) {
      debugPrint('Error adding files: $e');
    }
  }

  void _removeDuplicates() {
    final seen = <String>{};
    _allFiles = _allFiles.where((file) => seen.add(file.path)).toList();
  }

  // Rename a media file and update collections/cache
  Future<bool> rename(MediaFile file, String newName) async {
    final newPath = await _fileService.renameFile(file.path, newName);
    if (newPath == null) return false;

    final updated = MediaFile.fromFile(File(newPath));

    // Update all references
    final idx = _allFiles.indexWhere((f) => f.path == file.path);
    if (idx != -1) _allFiles[idx] = updated;
    final fidx = _filteredFiles.indexWhere((f) => f.path == file.path);
    if (fidx != -1) _filteredFiles[fidx] = updated;
    final ridx = _recentFiles.indexWhere((f) => f.path == file.path);
    if (ridx != -1) _recentFiles[ridx] = updated;

    // Update playlists
    for (final pl in _playlists) {
      final pidx = pl.files.indexWhere((f) => f.path == file.path);
      if (pidx != -1) pl.files[pidx] = updated;
    }

    // Persist cache
    await _settingsService.setCachedFiles(
      _allFiles.map((f) => f.path).toList(),
    );

    // If currently playing
    if (_currentFile?.path == file.path) {
      _currentFile = updated;
    }

    _applyFilters();
    notifyListeners();
    return true;
  }

  // Delete a media file and remove from collections/cache
  Future<bool> delete(MediaFile file) async {
    final ok = await _fileService.deleteFile(file.path);
    if (!ok) return false;

    _allFiles.removeWhere((f) => f.path == file.path);
    _filteredFiles.removeWhere((f) => f.path == file.path);
    _recentFiles.removeWhere((f) => f.path == file.path);

    for (final pl in _playlists) {
      pl.files.removeWhere((f) => f.path == file.path);
    }

    // Persist cache
    await _settingsService.setCachedFiles(
      _allFiles.map((f) => f.path).toList(),
    );

    // If deleting current file, clear current selection
    if (_currentFile?.path == file.path) {
      _currentFile = null;
      _currentPlaylist = null;
      _currentIndex = 0;
    }

    _applyFilters();
    notifyListeners();
    return true;
  }

  void setCurrentFile(MediaFile file, {mx.Playlist? playlist}) {
    _currentFile = file;
    _currentPlaylist = playlist;

    if (playlist != null) {
      _currentIndex = playlist.files.indexOf(file);
    } else {
      // Create a temporary playlist with current filtered files
      _currentPlaylist = mx.Playlist.create('Current Queue');
      _currentPlaylist!.files.addAll(_filteredFiles);
      _currentIndex = _filteredFiles.indexOf(file);
    }

    _settingsService.addRecentFile(file.path);
    // Update in-memory recent list too
    _recentFiles.removeWhere((f) => f.path == file.path);
    _recentFiles.insert(0, file);
    if (_recentFiles.length > 20) {
      _recentFiles.removeRange(20, _recentFiles.length);
    }

    notifyListeners();
  }

  void playNext() {
    if (hasNext) {
      _currentIndex++;
      _currentFile = _currentPlaylist!.files[_currentIndex];
      notifyListeners();
    }
  }

  void playPrevious() {
    if (hasPrevious) {
      _currentIndex--;
      _currentFile = _currentPlaylist!.files[_currentIndex];
      notifyListeners();
    }
  }

  Future<void> clearRecentFiles() async {
    try {
      await _settingsService.clearRecentFiles();
    } catch (_) {}
    _recentFiles.clear();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    // Use performance utility for debouncing
    debounceCallback(
      'search_filter',
      const Duration(
        milliseconds: 300,
      ), // Reduced delay for better responsiveness
      _applyFilters,
    );
  }

  void setFilterType(MediaType type) {
    _filterType = type;
    _applyFilters();
  }

  void setSorting(SortBy sortBy, bool ascending) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredFiles = _allFiles.where((file) {
      // Filter by type
      if (_filterType != MediaType.unknown && file.type != _filterType) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        return file.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }

      return true;
    }).toList();

    // Apply sorting
    _filteredFiles.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case SortBy.name:
          comparison = a.name.compareTo(b.name);
          break;
        case SortBy.size:
          comparison = a.size.compareTo(b.size);
          break;
        case SortBy.date:
          comparison = a.lastModified.compareTo(b.lastModified);
          break;
        case SortBy.duration:
          // Handle duration sorting - files without duration go to the end
          final aDuration = a.duration.value ?? Duration.zero;
          final bDuration = b.duration.value ?? Duration.zero;

          // If both have no duration, sort by name as fallback
          if (aDuration == Duration.zero && bDuration == Duration.zero) {
            comparison = a.name.compareTo(b.name);
          } else if (aDuration == Duration.zero) {
            comparison = 1; // a goes after b
          } else if (bDuration == Duration.zero) {
            comparison = -1; // a goes before b
          } else {
            comparison = aDuration.compareTo(bDuration);
          }
          break;
        case SortBy.type:
          comparison = a.extension.compareTo(b.extension);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    notifyListeners();
  }

  // Enrich files in background with optimized batching
  Future<void> _backgroundEnrich(
    List<MediaFile> files, {
    bool forceThumbnails = false,
  }) async {
    if (files.isEmpty) return;

    // Use performance utility for batched processing
    await PerformanceUtils.processBatched(
      files,
      (file) => _fileService
          .enrichMediaFile(file, forceThumbnail: forceThumbnails)
          .catchError((_) {
            // Silently handle errors to prevent crashes
          }),
      batchSize: 3, // Smaller batches for better responsiveness
      batchDelay: const Duration(milliseconds: 32), // ~30fps update rate
      shouldCancel: () => _enrichmentCancelled,
    );

    // Final UI update
    if (!_enrichmentCancelled) {
      notifyListeners();
    }
  }

  // Playlist management
  void createPlaylist(String name) {
    final playlist = mx.Playlist.create(name);
    _playlists.add(playlist);
    notifyListeners();
  }

  void addToPlaylist(mx.Playlist playlist, MediaFile file) {
    playlist.addFile(file);
    notifyListeners();
  }

  void addFilesToPlaylist(mx.Playlist playlist, List<MediaFile> files) {
    for (final f in files) {
      playlist.addFile(f);
    }
    notifyListeners();
  }

  void removeFromPlaylist(mx.Playlist playlist, MediaFile file) {
    playlist.removeFile(file);
    notifyListeners();
  }

  void clearPlaylist(mx.Playlist playlist) {
    playlist.files.clear();
    playlist.lastModified = DateTime.now();
    notifyListeners();
  }

  Future<void> pickAndAddFilesToPlaylist(mx.Playlist playlist) async {
    try {
      // Pick files from system
      final picked = await _fileService.pickFiles();
      if (picked.isEmpty) return;

      // Merge into library
      _allFiles.addAll(picked);
      _removeDuplicates();

      // Persist cache so it survives restarts
      await _settingsService.setCachedFiles(
        _allFiles.map((f) => f.path).toList(),
      );
      await _settingsService.setLastScanTime(DateTime.now());

      // Enrich in background and refresh filters
      _backgroundEnrich(picked);
      _applyFilters();

      // Add to playlist
      addFilesToPlaylist(playlist, picked);
    } catch (e) {
      debugPrint('Error picking/adding files to playlist: $e');
    }
  }

  void deletePlaylist(mx.Playlist playlist) {
    _playlists.remove(playlist);
    if (_currentPlaylist == playlist) {
      _currentPlaylist = null;
    }
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Expose saved position for a file (used for Continue Watching & progress UI)
  Duration getSavedPosition(MediaFile file) {
    try {
      return _settingsService.getLastPlayedPosition(file.path);
    } catch (_) {
      return Duration.zero;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _currentPlaylist?.dispose();
    _currentPlaylist = null;
    _enrichmentCancelled = true;
    disposePerformanceUtils(); // Clean up performance utilities
    super.dispose();
  }
}

enum SortBy { name, size, date, duration, type }
