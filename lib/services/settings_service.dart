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
  static const String _keyThemePreset = 'theme_preset';
  static const String _keyResumePlayback = 'resume_playback';
  // Linux desktop extras
  static const String _keySeekStepSeconds = 'seek_step_seconds';
  static const String _keyMiniPlayerEnabled = 'mini_player_enabled';
  static const String _keyRescanHours = 'rescan_hours';
  static const String _keySubtitleBgOpacity = 'subtitle_bg_opacity';
  static const String _keySubtitleOutline = 'subtitle_outline';
  static const String _keySubtitleShadow = 'subtitle_shadow';
  static const String _keyDefaultAspectRatio = 'default_aspect_ratio';
  static const String _keyDefaultVideoFit = 'default_video_fit';
  static const String _keyLanguage = 'language_pref';

  // Equalizer
  static const String _keyEqEnabled = 'eq_enabled';
  static const String _keyEqPreset =
      'eq_preset'; // normal, bass, treble, vocal, custom
  static const String _keyEqBass = 'eq_bass';
  static const String _keyEqLowMid = 'eq_low_mid';
  static const String _keyEqMid = 'eq_mid';
  static const String _keyEqHighMid = 'eq_high_mid';
  static const String _keyEqTreble = 'eq_treble';

  // Audio enhancements
  static const String _keyBassBoostEnabled = 'bass_boost_enabled';
  static const String _keyBassBoostStrength = 'bass_boost_strength';
  static const String _keyVirtualizerEnabled = 'virtualizer_enabled';
  static const String _keyVirtualizerStrength = 'virtualizer_strength';

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

  Future<void> clearRecentFiles() async {
    await _prefs.setStringList(_keyRecentFiles, []);
  }

  // Last played position
  Duration getLastPlayedPosition(String filePath) {
    final key = '$_keyLastPlayedPosition$filePath';
    final milliseconds = _prefs.getInt(key) ?? 0;
    final duration = Duration(milliseconds: milliseconds);
    print(
      'DEBUG: Retrieved position ${duration.inSeconds}s for $filePath with key: $key',
    );
    return duration;
  }

  Future<void> setLastPlayedPosition(String filePath, Duration position) async {
    final key = '$_keyLastPlayedPosition$filePath';
    await _prefs.setInt(key, position.inMilliseconds);
    print(
      'DEBUG: Saved position ${position.inSeconds}s for $filePath with key: $key',
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

  // Theme preset (custom)
  ThemePreset getThemePreset() {
    final index = _prefs.getInt(_keyThemePreset) ?? ThemePreset.deepSpace.index;
    return ThemePreset.values[index];
  }

  Future<void> setThemePreset(ThemePreset preset) async {
    await _prefs.setInt(_keyThemePreset, preset.index);
  }

  // Hardware acceleration
  bool get hardwareAcceleration =>
      _prefs.getBool(_keyHardwareAcceleration) ?? true;
  Future<void> setHardwareAcceleration(bool value) async {
    await _prefs.setBool(_keyHardwareAcceleration, value);
  }

  // Resume playback
  bool get resumePlayback => _prefs.getBool(_keyResumePlayback) ?? true;
  Future<void> setResumePlayback(bool value) async {
    await _prefs.setBool(_keyResumePlayback, value);
  }

  // File scanning and caching
  bool shouldRescan() {
    final lastScanTime = _prefs.getInt(_keyLastScanTime);
    if (lastScanTime == null) return true;

    final lastScan = DateTime.fromMillisecondsSinceEpoch(lastScanTime);
    final now = DateTime.now();
    final difference = now.difference(lastScan);

    final hours = rescanIntervalHours; // user-configurable
    return difference.inHours >= hours;
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

  // Linux desktop extras: getters/setters
  int get seekStepSeconds => _prefs.getInt(_keySeekStepSeconds) ?? 5;
  Future<void> setSeekStepSeconds(int seconds) async {
    await _prefs.setInt(_keySeekStepSeconds, seconds.clamp(1, 30));
  }

  bool get miniPlayerEnabled => _prefs.getBool(_keyMiniPlayerEnabled) ?? true;
  Future<void> setMiniPlayerEnabled(bool enabled) async {
    await _prefs.setBool(_keyMiniPlayerEnabled, enabled);
  }

  int get rescanIntervalHours => _prefs.getInt(_keyRescanHours) ?? 24;
  Future<void> setRescanIntervalHours(int hours) async {
    await _prefs.setInt(_keyRescanHours, hours.clamp(1, 168));
  }

  double get subtitleBgOpacity =>
      _prefs.getDouble(_keySubtitleBgOpacity) ?? 0.0;
  Future<void> setSubtitleBgOpacity(double value) async {
    await _prefs.setDouble(_keySubtitleBgOpacity, value.clamp(0.0, 1.0));
  }

  double get subtitleOutline => _prefs.getDouble(_keySubtitleOutline) ?? 0.0;
  Future<void> setSubtitleOutline(double value) async {
    await _prefs.setDouble(_keySubtitleOutline, value.clamp(0.0, 5.0));
  }

  bool get subtitleShadow => _prefs.getBool(_keySubtitleShadow) ?? true;
  Future<void> setSubtitleShadow(bool value) async {
    await _prefs.setBool(_keySubtitleShadow, value);
  }

  // Aspect ratio enum persisted as index
  DefaultAspectRatio get defaultAspectRatio {
    final idx = _prefs.getInt(_keyDefaultAspectRatio) ?? 0;
    return DefaultAspectRatio.values[idx];
  }

  Future<void> setDefaultAspectRatio(DefaultAspectRatio v) async {
    await _prefs.setInt(_keyDefaultAspectRatio, v.index);
  }

  DefaultVideoFit get defaultVideoFit {
    final idx = _prefs.getInt(_keyDefaultVideoFit) ?? 0;
    return DefaultVideoFit.values[idx];
  }

  Future<void> setDefaultVideoFit(DefaultVideoFit v) async {
    await _prefs.setInt(_keyDefaultVideoFit, v.index);
  }

  String get languagePref => _prefs.getString(_keyLanguage) ?? 'en';
  Future<void> setLanguagePref(String code) async {
    await _prefs.setString(_keyLanguage, code);
  }

  // Equalizer getters/setters
  bool get eqEnabled => _prefs.getBool(_keyEqEnabled) ?? false;
  Future<void> setEqEnabled(bool v) async {
    await _prefs.setBool(_keyEqEnabled, v);
  }

  EqPreset get eqPreset {
    final idx = _prefs.getInt(_keyEqPreset) ?? EqPreset.normal.index;
    return EqPreset.values[idx];
  }

  Future<void> setEqPreset(EqPreset p) async {
    await _prefs.setInt(_keyEqPreset, p.index);
  }

  // Slider values are stored -1.0..+1.0
  double get eqBass => _prefs.getDouble(_keyEqBass) ?? 0.0;
  Future<void> setEqBass(double v) async {
    await _prefs.setDouble(_keyEqBass, v.clamp(-1.0, 1.0));
  }

  double get eqLowMid => _prefs.getDouble(_keyEqLowMid) ?? 0.0;
  Future<void> setEqLowMid(double v) async {
    await _prefs.setDouble(_keyEqLowMid, v.clamp(-1.0, 1.0));
  }

  double get eqMid => _prefs.getDouble(_keyEqMid) ?? 0.0;
  Future<void> setEqMid(double v) async {
    await _prefs.setDouble(_keyEqMid, v.clamp(-1.0, 1.0));
  }

  double get eqHighMid => _prefs.getDouble(_keyEqHighMid) ?? 0.0;
  Future<void> setEqHighMid(double v) async {
    await _prefs.setDouble(_keyEqHighMid, v.clamp(-1.0, 1.0));
  }

  double get eqTreble => _prefs.getDouble(_keyEqTreble) ?? 0.0;
  Future<void> setEqTreble(double v) async {
    await _prefs.setDouble(_keyEqTreble, v.clamp(-1.0, 1.0));
  }

  // Bass boost settings
  bool get bassBoostEnabled => _prefs.getBool(_keyBassBoostEnabled) ?? false;
  Future<void> setBassBoostEnabled(bool v) async {
    await _prefs.setBool(_keyBassBoostEnabled, v);
  }

  double get bassBoostStrength =>
      _prefs.getDouble(_keyBassBoostStrength) ?? 0.0;
  Future<void> setBassBoostStrength(double v) async {
    await _prefs.setDouble(_keyBassBoostStrength, v.clamp(0.0, 1.0));
  }

  // Virtualizer settings
  bool get virtualizerEnabled =>
      _prefs.getBool(_keyVirtualizerEnabled) ?? false;
  Future<void> setVirtualizerEnabled(bool v) async {
    await _prefs.setBool(_keyVirtualizerEnabled, v);
  }

  double get virtualizerStrength =>
      _prefs.getDouble(_keyVirtualizerStrength) ?? 0.0;
  Future<void> setVirtualizerStrength(double v) async {
    await _prefs.setDouble(_keyVirtualizerStrength, v.clamp(0.0, 1.0));
  }

  // Clear all settings
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

// New enums for persisted defaults
enum DefaultAspectRatio { auto, r16_9, r4_3, r1_1 }

enum DefaultVideoFit { contain, cover, fill }

enum RepeatMode { none, one, all }

enum ThemeMode { system, light, dark }

// Mirror enum used by ThemeProvider presets
enum ThemePreset {
  oceanicCalm,
  sereneTwilight,
  deepSpace,
  mangoPassion,
  sunsetBlaze,
  neonGlow,
  lushMeadow,
  digitalMint,
  gentleOcean,
  // New presets (appended to preserve existing saved indices)
  auroraBorealis,
  royalAmethyst,
  lavaSunrise,
  aquaMarine,
  steelMidnight,
  cherryBlossom,
  amberTeal,
  graphiteBlue,
  // More presets (keep appending to maintain saved indices)
  electricViolet,
  cyberPunk,
  arcticSky,
  emeraldWave,
  citrusPop,
  roseGold,
  desertDusk,
  oceanSunrise,
}

// Equalizer Presets
enum EqPreset { normal, bassBoost, trebleBoost, vocal, custom }
