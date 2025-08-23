import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/media_file.dart';
import '../models/playlist.dart' as mx;
import '../services/file_service.dart';
import '../services/settings_service.dart';

class MediaProvider extends ChangeNotifier {
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

  bool get hasNext =>
      _currentPlaylist != null &&
      _currentIndex < _currentPlaylist!.files.length - 1;
  bool get hasPrevious => _currentPlaylist != null && _currentIndex > 0;

  Future<void> initialize() async {
    debugPrint('MediaProvider: Starting initialization...');
    try {
      await _settingsService.initialize();
      debugPrint('MediaProvider: SettingsService initialized');
      // Skip file loading for now to test basic functionality
      // await loadFiles();
      debugPrint(
        'MediaProvider: Initialization complete (files loading skipped)',
      );
    } catch (e) {
      debugPrint('MediaProvider: Error during initialization: $e');
      rethrow;
    }
  }

  Future<void> loadFiles({bool force = false}) async {
    debugPrint('MediaProvider: Loading files (force: $force)...');
    _setLoading(true);
    try {
      if (force || _settingsService.shouldRescan()) {
        debugPrint('MediaProvider: Scanning directories...');
        _allFiles = await _fileService.getCommonMediaDirectories()
          ..addAll(await _fileService.scanCustomFormats());
        debugPrint('MediaProvider: Found ${_allFiles.length} files');
        await _settingsService.setLastScanTime(DateTime.now());
        await _settingsService.setCachedFiles(
          _allFiles.map((f) => f.path).toList(),
        );
      } else {
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
        debugPrint(
          'MediaProvider: Loaded ${_allFiles.length} files from cache',
        );
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
  }

  Future<void> scanDirectory(String path) async {
    _setLoading(true);
    try {
      final files = await _fileService.scanDirectory(path);
      _allFiles.addAll(files);
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

  void setSearchQuery(String query) {
    _searchQuery = query;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _applyFilters();
    });
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
        case SortBy.type:
          comparison = a.extension.compareTo(b.extension);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    notifyListeners();
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

  void removeFromPlaylist(mx.Playlist playlist, MediaFile file) {
    playlist.removeFile(file);
    notifyListeners();
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

  @override
  void dispose() {
    _debounce?.cancel();
    _currentPlaylist?.dispose();
    _currentPlaylist = null;
    // _fileService disposal handled by its owner
    super.dispose();
  }
}

enum SortBy { name, size, date, type }
