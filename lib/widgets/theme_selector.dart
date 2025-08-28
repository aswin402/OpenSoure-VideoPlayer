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
        return SingleChildScrollView(
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      Provider.of<ThemeProvider>(context).primaryColor,
                      Provider.of<ThemeProvider>(context).secondaryColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.white24,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : Colors.white70,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Colors.white.withOpacity(0.8)
                      : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetGrid(BuildContext context, ThemeProvider themeProvider) {
    final presets = settings_service.ThemePreset.values;
    return LayoutBuilder(
      builder: (context, constraints) {
        final int count = (constraints.maxWidth / 200).clamp(2, 6).floor();
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemCount: presets.length,
          itemBuilder: (context, index) {
            final preset = presets[index];
            final colors = _getPresetColors(preset);
            final isSelected = themeProvider.preset == preset;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => themeProvider.setPreset(preset),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: isSelected ? 2 : 0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colors.first.withOpacity(0.25),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        const SizedBox(height: 2),
                        Text(
                          _getPresetName(preset),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(color: Colors.black26, blurRadius: 2),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
      case settings_service.ThemePreset.auroraBorealis:
        return [const Color(0xFF00C6FF), const Color(0xFF0072FF)];
      case settings_service.ThemePreset.royalAmethyst:
        return [const Color(0xFF9D50BB), const Color(0xFF6E48AA)];
      case settings_service.ThemePreset.lavaSunrise:
        return [const Color(0xFFFF512F), const Color(0xFFF09819)];
      case settings_service.ThemePreset.aquaMarine:
        return [const Color(0xFF00B4DB), const Color(0xFF0083B0)];
      case settings_service.ThemePreset.steelMidnight:
        return [const Color(0xFF232526), const Color(0xFF414345)];
      case settings_service.ThemePreset.cherryBlossom:
        return [const Color(0xFFFFA4B7), const Color(0xFFFF4E50)];
      case settings_service.ThemePreset.amberTeal:
        return [const Color(0xFFFFC371), const Color(0xFF00C6A7)];
      case settings_service.ThemePreset.graphiteBlue:
        return [const Color(0xFF283048), const Color(0xFF859398)];
      case settings_service.ThemePreset.electricViolet:
        return [const Color(0xFF7F00FF), const Color(0xFFE100FF)];
      case settings_service.ThemePreset.cyberPunk:
        return [const Color(0xFF0f0c29), const Color(0xFFf72585)];
      case settings_service.ThemePreset.arcticSky:
        return [const Color(0xFF1e3c72), const Color(0xFF2a5298)];
      case settings_service.ThemePreset.emeraldWave:
        return [const Color(0xFF0bab64), const Color(0xFF3bb78f)];
      case settings_service.ThemePreset.citrusPop:
        return [const Color(0xFFf7971e), const Color(0xFFffd200)];
      case settings_service.ThemePreset.roseGold:
        return [const Color(0xFFb24592), const Color(0xFFf15f79)];
      case settings_service.ThemePreset.desertDusk:
        return [const Color(0xFF3E5151), const Color(0xFFDECBA4)];
      case settings_service.ThemePreset.oceanSunrise:
        return [const Color(0xFF2BC0E4), const Color(0xFFEAECC6)];
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
      case settings_service.ThemePreset.auroraBorealis:
        return 'Aurora\nBorealis';
      case settings_service.ThemePreset.royalAmethyst:
        return 'Royal\nAmethyst';
      case settings_service.ThemePreset.lavaSunrise:
        return 'Lava\nSunrise';
      case settings_service.ThemePreset.aquaMarine:
        return 'Aqua\nMarine';
      case settings_service.ThemePreset.steelMidnight:
        return 'Steel\nMidnight';
      case settings_service.ThemePreset.cherryBlossom:
        return 'Cherry\nBlossom';
      case settings_service.ThemePreset.amberTeal:
        return 'Amber\nTeal';
      case settings_service.ThemePreset.graphiteBlue:
        return 'Graphite\nBlue';
      case settings_service.ThemePreset.electricViolet:
        return 'Electric\nViolet';
      case settings_service.ThemePreset.cyberPunk:
        return 'Cyber\nPunk';
      case settings_service.ThemePreset.arcticSky:
        return 'Arctic\nSky';
      case settings_service.ThemePreset.emeraldWave:
        return 'Emerald\nWave';
      case settings_service.ThemePreset.citrusPop:
        return 'Citrus\nPop';
      case settings_service.ThemePreset.roseGold:
        return 'Rose\nGold';
      case settings_service.ThemePreset.desertDusk:
        return 'Desert\nDusk';
      case settings_service.ThemePreset.oceanSunrise:
        return 'Ocean\nSunrise';
    }
  }
}
