import 'package:flutter/material.dart' as flutter;
import '../services/settings_service.dart' as settings_service;

class ThemeProvider extends flutter.ChangeNotifier {
  final settings_service.SettingsService _settings =
      settings_service.SettingsService();

  bool _initialized = false;
  settings_service.ThemeMode _mode = settings_service.ThemeMode.dark;
  settings_service.ThemePreset _preset = settings_service.ThemePreset.deepSpace;

  Future<void> initialize() async {
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
