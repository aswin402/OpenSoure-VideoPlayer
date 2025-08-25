import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/settings_service.dart' as settings_service;

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Theme Mode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _buildThemeModeSelector(context, themeProvider),
              const SizedBox(height: 24),
              const Text(
                'Color Preset',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _buildPresetGrid(context, themeProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeModeSelector(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildThemeModeCard(
            context,
            title: 'System',
            subtitle: 'Follow system',
            icon: Icons.brightness_auto_rounded,
            isSelected: themeProvider.mode == settings_service.ThemeMode.system,
            onTap: () =>
                themeProvider.setThemeMode(settings_service.ThemeMode.system),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildThemeModeCard(
            context,
            title: 'Light',
            subtitle: 'Always light',
            icon: Icons.light_mode_rounded,
            isSelected: themeProvider.mode == settings_service.ThemeMode.light,
            onTap: () =>
                themeProvider.setThemeMode(settings_service.ThemeMode.light),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildThemeModeCard(
            context,
            title: 'Dark',
            subtitle: 'Always dark',
            icon: Icons.dark_mode_rounded,
            isSelected: themeProvider.mode == settings_service.ThemeMode.dark,
            onTap: () =>
                themeProvider.setThemeMode(settings_service.ThemeMode.dark),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeModeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        themeProvider.primaryColor,
                        themeProvider.secondaryColor,
                      ],
                    )
                  : null,
              color: isSelected ? null : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.7),
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.9),
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white.withOpacity(0.8)
                        : Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPresetGrid(BuildContext context, ThemeProvider themeProvider) {
    final presets = settings_service.ThemePreset.values;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: presets.length,
      itemBuilder: (context, index) {
        final preset = presets[index];
        final colors = _getPresetColors(preset);
        final isSelected = themeProvider.preset == preset;

        return GestureDetector(
          onTap: () => themeProvider.setPreset(preset),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: isSelected ? 3 : 0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colors.first.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        _getPresetName(preset),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(color: Colors.black26, blurRadius: 2),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Color> _getPresetColors(settings_service.ThemePreset preset) {
    switch (preset) {
      case settings_service.ThemePreset.oceanicCalm:
        return [const Color(0xFF0052D4), const Color(0xFF65C7F7)];
      case settings_service.ThemePreset.sereneTwilight:
        return [const Color(0xFF4776E6), const Color(0xFF8E54E9)];
      case settings_service.ThemePreset.deepSpace:
        return [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)];
      case settings_service.ThemePreset.mangoPassion:
        return [const Color(0xFFF5AF19), const Color(0xFFF12711)];
      case settings_service.ThemePreset.sunsetBlaze:
        return [const Color(0xFFF953C6), const Color(0xFFB91D73)];
      case settings_service.ThemePreset.neonGlow:
        return [const Color(0xFFEE0979), const Color(0xFFFF6A00)];
      case settings_service.ThemePreset.lushMeadow:
        return [const Color(0xFF11998E), const Color(0xFF38EF7D)];
      case settings_service.ThemePreset.digitalMint:
        return [const Color(0xFF134E5E), const Color(0xFF71B280)];
      case settings_service.ThemePreset.gentleOcean:
        return [const Color(0xFF43C6AC), const Color(0xFFF8FFAE)];
    }
  }

  String _getPresetName(settings_service.ThemePreset preset) {
    switch (preset) {
      case settings_service.ThemePreset.oceanicCalm:
        return 'Oceanic\nCalm';
      case settings_service.ThemePreset.sereneTwilight:
        return 'Serene\nTwilight';
      case settings_service.ThemePreset.deepSpace:
        return 'Deep\nSpace';
      case settings_service.ThemePreset.mangoPassion:
        return 'Mango\nPassion';
      case settings_service.ThemePreset.sunsetBlaze:
        return 'Sunset\nBlaze';
      case settings_service.ThemePreset.neonGlow:
        return 'Neon\nGlow';
      case settings_service.ThemePreset.lushMeadow:
        return 'Lush\nMeadow';
      case settings_service.ThemePreset.digitalMint:
        return 'Digital\nMint';
      case settings_service.ThemePreset.gentleOcean:
        return 'Gentle\nOcean';
    }
  }
}
