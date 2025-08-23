import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyVolume = 'volume';
  static const String _keyBrightness = 'brightness';
  static const String _keyPlaybackSpeed = 'playback_speed';
  static const String _keySubtitleSize = 'subtitle_size';
  static const String _keySubtitleColor = 'subtitle_color';
  static const String _keyAutoPlay = 'auto_play';
  static const String _keyRepeatMode = 'repeat_mode';
  static const String _keyRecentFiles = 'recent_files';
  static const String _keyLastPlayedPosition = 'last_played_position_';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyHardwareAcceleration = 'hardware_acceleration';
  static const String _keyLastScanTime = 'last_scan_time';
  static const String _keyCachedFiles = 'cached_files';

  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Volume settings
  double get volume => _prefs.getDouble(_keyVolume) ?? 1.0;
  Future<void> setVolume(double value) async {
    await _prefs.setDouble(_keyVolume, value);
  }

  // Brightness settings
  double get brightness => _prefs.getDouble(_keyBrightness) ?? 0.0;
  Future<void> setBrightness(double value) async {
    await _prefs.setDouble(_keyBrightness, value);
  }

  // Playback speed
  double get playbackSpeed => _prefs.getDouble(_keyPlaybackSpeed) ?? 1.0;
  Future<void> setPlaybackSpeed(double value) async {
    await _prefs.setDouble(_keyPlaybackSpeed, value);
  }

  // Subtitle settings
  double get subtitleSize => _prefs.getDouble(_keySubtitleSize) ?? 16.0;
  Future<void> setSubtitleSize(double value) async {
    await _prefs.setDouble(_keySubtitleSize, value);
  }

  int get subtitleColor => _prefs.getInt(_keySubtitleColor) ?? 0xFFFFFFFF;
  Future<void> setSubtitleColor(int value) async {
    await _prefs.setInt(_keySubtitleColor, value);
  }

  // Auto play
  bool get autoPlay => _prefs.getBool(_keyAutoPlay) ?? true;
  Future<void> setAutoPlay(bool value) async {
    await _prefs.setBool(_keyAutoPlay, value);
  }

  // Repeat mode
  RepeatMode get repeatMode {
    final index = _prefs.getInt(_keyRepeatMode) ?? 0;
    return RepeatMode.values[index];
  }

  Future<void> setRepeatMode(RepeatMode mode) async {
    await _prefs.setInt(_keyRepeatMode, mode.index);
  }

  // Recent files
  List<String> get recentFiles => _prefs.getStringList(_keyRecentFiles) ?? [];
  Future<void> addRecentFile(String filePath) async {
    final recent = recentFiles;
    recent.remove(filePath); // Remove if already exists
    recent.insert(0, filePath); // Add to beginning
    if (recent.length > 20) {
      recent.removeRange(20, recent.length); // Keep only last 20
    }
    await _prefs.setStringList(_keyRecentFiles, recent);
  }

  // Last played position
  Duration getLastPlayedPosition(String filePath) {
    final milliseconds = _prefs.getInt('$_keyLastPlayedPosition$filePath') ?? 0;
    return Duration(milliseconds: milliseconds);
  }

  Future<void> setLastPlayedPosition(String filePath, Duration position) async {
    await _prefs.setInt(
      '$_keyLastPlayedPosition$filePath',
      position.inMilliseconds,
    );
  }

  // Theme mode
  ThemeMode get themeMode {
    final index = _prefs.getInt(_keyThemeMode) ?? 0;
    return ThemeMode.values[index];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setInt(_keyThemeMode, mode.index);
  }

  // Hardware acceleration
  bool get hardwareAcceleration =>
      _prefs.getBool(_keyHardwareAcceleration) ?? true;
  Future<void> setHardwareAcceleration(bool value) async {
    await _prefs.setBool(_keyHardwareAcceleration, value);
  }

  // File scanning and caching
  bool shouldRescan() {
    final lastScanTime = _prefs.getInt(_keyLastScanTime);
    if (lastScanTime == null) return true;

    final lastScan = DateTime.fromMillisecondsSinceEpoch(lastScanTime);
    final now = DateTime.now();
    final difference = now.difference(lastScan);

    // Rescan if it's been more than 24 hours
    return difference.inHours > 24;
  }

  Future<void> setLastScanTime(DateTime time) async {
    await _prefs.setInt(_keyLastScanTime, time.millisecondsSinceEpoch);
  }

  List<String> getCachedFiles() {
    return _prefs.getStringList(_keyCachedFiles) ?? [];
  }

  Future<void> setCachedFiles(List<String> files) async {
    await _prefs.setStringList(_keyCachedFiles, files);
  }

  // Clear all settings
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

enum RepeatMode { none, one, all }

enum ThemeMode { system, light, dark }
