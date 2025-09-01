import 'package:flutter/material.dart' as flutter;
import '../services/settings_service.dart' as settings_service;

class ThemeProvider extends flutter.ChangeNotifier {
  final settings_service.SettingsService _settings =
      settings_service.SettingsService();

  bool _initialized = false;
  settings_service.ThemeMode _mode = settings_service.ThemeMode.dark;
  settings_service.ThemePreset _preset = settings_service.ThemePreset.deepSpace;

  // Non-blocking initialization for better startup performance
  void initializeAsync() {
    if (_initialized) return;

    Future.microtask(() async {
      try {
        await _settings.initialize();
        _mode = _settings.themeMode;
        _preset = _settings.getThemePreset();
        _initialized = true;
        notifyListeners();
      } catch (e) {
        flutter.debugPrint('ThemeProvider initialization error: $e');
      }
    });
  }

  Future<void> initialize() async {
    if (_initialized) return;

    await _settings.initialize();
    _mode = _settings.themeMode;
    _preset = _settings.getThemePreset();
    _initialized = true;
    notifyListeners();
  }

  bool get initialized => _initialized;
  settings_service.ThemeMode get mode => _mode;
  settings_service.ThemePreset get preset => _preset;

  // Primary/Secondary derived from preset
  flutter.Color get primaryColor => _mapPreset(_preset).$1;
  flutter.Color get secondaryColor => _mapPreset(_preset).$2;

  // Map preset to colors
  (flutter.Color, flutter.Color) _mapPreset(
    settings_service.ThemePreset preset,
  ) {
    switch (preset) {
      case settings_service.ThemePreset.oceanicCalm:
        return (
          const flutter.Color(0xFF0052D4),
          const flutter.Color(0xFF65C7F7),
        );
      case settings_service.ThemePreset.sereneTwilight:
        return (
          const flutter.Color(0xFF4776E6),
          const flutter.Color(0xFF8E54E9),
        );
      case settings_service.ThemePreset.deepSpace:
        return (
          const flutter.Color(0xFF2C3E50),
          const flutter.Color(0xFF4CA1AF),
        );
      case settings_service.ThemePreset.mangoPassion:
        return (
          const flutter.Color(0xFFF5AF19),
          const flutter.Color(0xFFF12711),
        );
      case settings_service.ThemePreset.sunsetBlaze:
        return (
          const flutter.Color(0xFFF953C6),
          const flutter.Color(0xFFB91D73),
        );
      case settings_service.ThemePreset.neonGlow:
        return (
          const flutter.Color(0xFFEE0979),
          const flutter.Color(0xFFFF6A00),
        );
      case settings_service.ThemePreset.lushMeadow:
        return (
          const flutter.Color(0xFF11998E),
          const flutter.Color(0xFF38EF7D),
        );
      case settings_service.ThemePreset.digitalMint:
        return (
          const flutter.Color(0xFF134E5E),
          const flutter.Color(0xFF71B280),
        );
      case settings_service.ThemePreset.gentleOcean:
        return (
          const flutter.Color(0xFF43C6AC),
          const flutter.Color(0xFFF8FFAE),
        );
      case settings_service.ThemePreset.auroraBorealis:
        return (
          const flutter.Color(0xFF00C6FF),
          const flutter.Color(0xFF0072FF),
        );
      case settings_service.ThemePreset.royalAmethyst:
        return (
          const flutter.Color(0xFF9D50BB),
          const flutter.Color(0xFF6E48AA),
        );
      case settings_service.ThemePreset.lavaSunrise:
        return (
          const flutter.Color(0xFFFF512F),
          const flutter.Color(0xFFF09819),
        );
      case settings_service.ThemePreset.aquaMarine:
        return (
          const flutter.Color(0xFF00B4DB),
          const flutter.Color(0xFF0083B0),
        );
      case settings_service.ThemePreset.steelMidnight:
        return (
          const flutter.Color(0xFF232526),
          const flutter.Color(0xFF414345),
        );
      case settings_service.ThemePreset.cherryBlossom:
        return (
          const flutter.Color(0xFFFFA4B7),
          const flutter.Color(0xFFFF4E50),
        );
      case settings_service.ThemePreset.amberTeal:
        return (
          const flutter.Color(0xFFFFC371),
          const flutter.Color(0xFF00C6A7),
        );
      case settings_service.ThemePreset.graphiteBlue:
        return (
          const flutter.Color(0xFF283048),
          const flutter.Color(0xFF859398),
        );
      case settings_service.ThemePreset.electricViolet:
        return (
          const flutter.Color(0xFF7F00FF),
          const flutter.Color(0xFFE100FF),
        );
      case settings_service.ThemePreset.cyberPunk:
        return (
          const flutter.Color(0xFF0f0c29),
          const flutter.Color(0xFFf72585),
        );
      case settings_service.ThemePreset.arcticSky:
        return (
          const flutter.Color(0xFF1e3c72),
          const flutter.Color(0xFF2a5298),
        );
      case settings_service.ThemePreset.emeraldWave:
        return (
          const flutter.Color(0xFF0bab64),
          const flutter.Color(0xFF3bb78f),
        );
      case settings_service.ThemePreset.citrusPop:
        return (
          const flutter.Color(0xFFf7971e),
          const flutter.Color(0xFFffd200),
        );
      case settings_service.ThemePreset.roseGold:
        return (
          const flutter.Color(0xFFb24592),
          const flutter.Color(0xFFf15f79),
        );
      case settings_service.ThemePreset.desertDusk:
        return (
          const flutter.Color(0xFF3E5151),
          const flutter.Color(0xFFDECBA4),
        );
      case settings_service.ThemePreset.oceanSunrise:
        return (
          const flutter.Color(0xFF2BC0E4),
          const flutter.Color(0xFFEAECC6),
        );
    }
  }

  Future<void> setThemeMode(settings_service.ThemeMode mode) async {
    _mode = mode;
    await _settings.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setPreset(settings_service.ThemePreset preset) async {
    _preset = preset;
    await _settings.setThemePreset(preset);
    notifyListeners();
  }

  flutter.ThemeMode get materialThemeMode {
    switch (_mode) {
      case settings_service.ThemeMode.system:
        return flutter.ThemeMode.system;
      case settings_service.ThemeMode.light:
        return flutter.ThemeMode.light;
      case settings_service.ThemeMode.dark:
        return flutter.ThemeMode.dark;
    }
  }
}
