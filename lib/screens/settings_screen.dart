import 'package:flutter/material.dart' hide ThemeMode;
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/theme_provider.dart';
import '../services/settings_service.dart' as settings_service;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final settings_service.SettingsService _settingsService =
      settings_service.SettingsService();
  bool _settingsReady = false;

  final List<Color> _subtitleColors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.cyan,
    Colors.lime,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  Future<void> _initSettings() async {
    await _settingsService.initialize();
    if (!mounted) return;
    setState(() => _settingsReady = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        flexibleSpace: Consumer<ThemeProvider>(
          builder: (context, theme, _) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [theme.primaryColor, theme.secondaryColor],
              ),
            ),
          ),
        ),
      ),
      body: !_settingsReady
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildPlaybackSection(),
                const Divider(),
                _buildVideoSection(),
                const Divider(),
                _buildAudioSection(),
                const Divider(),
                _buildSubtitleSection(),
                const Divider(),
                _buildGeneralSection(),
                const Divider(),
                _buildAboutSection(),
              ],
            ),
    );
  }

  Widget _buildPlaybackSection() {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        return ExpansionTile(
          leading: const Icon(Icons.play_circle_outline),
          title: const Text('Playback'),
          children: [
            ListTile(
              title: const Text('Auto Play'),
              subtitle: const Text('Automatically play next file'),
              trailing: Switch(
                value: _settingsService.autoPlay,
                onChanged: (value) {
                  _settingsService.setAutoPlay(value);
                  setState(() {});
                },
              ),
            ),
            ListTile(
              title: const Text('Repeat Mode'),
              subtitle: Text(
                _getRepeatModeText(
                  playerProvider.repeatMode as settings_service.RepeatMode,
                ),
              ),
              trailing: IconButton(
                icon: _getRepeatModeIcon(
                  playerProvider.repeatMode as settings_service.RepeatMode,
                ),
                onPressed: () {
                  playerProvider.toggleRepeatMode();
                },
              ),
            ),
            ListTile(
              title: const Text('Playback Speed'),
              subtitle: Text('${playerProvider.playbackSpeed}x'),
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: playerProvider.playbackSpeed,
                  min: 0.25,
                  max: 3.0,
                  divisions: 11,
                  label: '${playerProvider.playbackSpeed}x',
                  onChanged: (value) {
                    playerProvider.setPlaybackSpeed(value);
                  },
                ),
              ),
            ),
            ListTile(
              title: const Text('Hardware Acceleration'),
              subtitle: const Text('Use GPU for video decoding'),
              trailing: Switch(
                value: _settingsService.hardwareAcceleration,
                onChanged: (value) {
                  _settingsService.setHardwareAcceleration(value);
                  setState(() {});
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVideoSection() {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        return ExpansionTile(
          leading: const Icon(Icons.video_settings),
          title: const Text('Video'),
          children: [
            ListTile(
              title: const Text('Brightness'),
              subtitle: Text('${(playerProvider.brightness * 100).round()}%'),
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: playerProvider.brightness,
                  min: -1.0,
                  max: 1.0,
                  divisions: 20,
                  label: '${(playerProvider.brightness * 100).round()}%',
                  onChanged: (value) {
                    playerProvider.setBrightness(value);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAudioSection() {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        return ExpansionTile(
          leading: const Icon(Icons.volume_up),
          title: const Text('Audio'),
          children: [
            ListTile(
              title: const Text('Volume'),
              subtitle: Text('${(playerProvider.volume * 100).round()}%'),
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: playerProvider.volume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  label: '${(playerProvider.volume * 100).round()}%',
                  onChanged: (value) {
                    playerProvider.setVolume(value);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubtitleSection() {
    return ExpansionTile(
      leading: const Icon(Icons.subtitles),
      title: const Text('Subtitles'),
      children: [
        ListTile(
          title: const Text('Font Size'),
          subtitle: Text('${_settingsService.subtitleSize.round()}px'),
          trailing: SizedBox(
            width: 150,
            child: Slider(
              value: _settingsService.subtitleSize,
              min: 12.0,
              max: 32.0,
              divisions: 20,
              label: '${_settingsService.subtitleSize.round()}px',
              onChanged: (value) {
                _settingsService.setSubtitleSize(value);
                setState(() {});
              },
            ),
          ),
        ),
        ListTile(
          title: const Text('Font Color'),
          subtitle: const Text('Subtitle text color'),
          trailing: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(_settingsService.subtitleColor),
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onTap: () {
            _showColorPicker();
          },
        ),
      ],
    );
  }

  Widget _buildGeneralSection() {
    return ExpansionTile(
      leading: const Icon(Icons.settings),
      title: const Text('General'),
      children: [
        ListTile(
          title: const Text('Theme Mode'),
          subtitle: Text(
            _getThemeModeText(
              _settingsService.themeMode as settings_service.ThemeMode,
            ),
          ),
          trailing: DropdownButton<settings_service.ThemeMode>(
            value: _settingsService.themeMode as settings_service.ThemeMode,
            onChanged: (settings_service.ThemeMode? value) {
              if (value != null) {
                _settingsService.setThemeMode(value);
                setState(() {});
              }
            },
            items: settings_service.ThemeMode.values.map((
              settings_service.ThemeMode mode,
            ) {
              return DropdownMenuItem<settings_service.ThemeMode>(
                value: mode,
                child: Text(_getThemeModeText(mode)),
              );
            }).toList(),
          ),
        ),
        ListTile(
          title: const Text('Theme Preset'),
          subtitle: Text(_getPresetName(_settingsService.getThemePreset())),
          trailing: Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return DropdownButton<settings_service.ThemePreset>(
                value: _settingsService.getThemePreset(),
                onChanged: (settings_service.ThemePreset? value) async {
                  if (value != null) {
                    await _settingsService.setThemePreset(value);
                    await themeProvider.setPreset(value);
                    if (!mounted) return;
                    setState(() {});
                  }
                },
                items: settings_service.ThemePreset.values.map((preset) {
                  return DropdownMenuItem<settings_service.ThemePreset>(
                    value: preset,
                    child: Text(_getPresetName(preset)),
                  );
                }).toList(),
              );
            },
          ),
        ),
        ListTile(
          title: const Text('Clear Recent Files'),
          subtitle: const Text('Remove all recently played files'),
          trailing: const Icon(Icons.clear_all),
          onTap: () {
            _showClearRecentDialog();
          },
        ),
        ListTile(
          title: const Text('Reset Settings'),
          subtitle: const Text('Reset all settings to default'),
          trailing: const Icon(Icons.restore),
          onTap: () {
            _showResetSettingsDialog();
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return ExpansionTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('About'),
      children: [
        const ListTile(
          title: Text('MX Player Clone'),
          subtitle: Text('Version 1.0.0'),
        ),
        const ListTile(
          title: Text('Built with Flutter'),
          subtitle: Text('A comprehensive media player for Linux'),
        ),
        ListTile(
          title: const Text('Supported Formats'),
          subtitle: const Text('Tap to view all supported file formats'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            _showSupportedFormatsDialog();
          },
        ),
      ],
    );
  }

  String _getRepeatModeText(settings_service.RepeatMode mode) {
    switch (mode) {
      case settings_service.RepeatMode.none:
        return 'Off';
      case settings_service.RepeatMode.one:
        return 'Repeat One';
      case settings_service.RepeatMode.all:
        return 'Repeat All';
    }
  }

  Icon _getRepeatModeIcon(settings_service.RepeatMode mode) {
    switch (mode) {
      case settings_service.RepeatMode.none:
        return const Icon(Icons.repeat);
      case settings_service.RepeatMode.one:
        return const Icon(Icons.repeat_one);
      case settings_service.RepeatMode.all:
        return const Icon(Icons.repeat);
    }
  }

  String _getThemeModeText(settings_service.ThemeMode mode) {
    switch (mode) {
      case settings_service.ThemeMode.system:
        return 'System';
      case settings_service.ThemeMode.light:
        return 'Light';
      case settings_service.ThemeMode.dark:
        return 'Dark';
    }
  }

  String _getPresetName(settings_service.ThemePreset preset) {
    switch (preset) {
      case settings_service.ThemePreset.oceanicCalm:
        return 'Oceanic Calm (Azure → Sky Blue)';
      case settings_service.ThemePreset.sereneTwilight:
        return 'Serene Twilight (Blue → Violet)';
      case settings_service.ThemePreset.deepSpace:
        return 'Deep Space (Slate Blue → Teal)';
      case settings_service.ThemePreset.mangoPassion:
        return 'Mango Passion (Yellow → Red-Orange)';
      case settings_service.ThemePreset.sunsetBlaze:
        return 'Sunset Blaze (Hot Pink → Magenta)';
      case settings_service.ThemePreset.neonGlow:
        return 'Neon Glow (Pink → Orange)';
      case settings_service.ThemePreset.lushMeadow:
        return 'Lush Meadow (Teal Green → Light Green)';
      case settings_service.ThemePreset.digitalMint:
        return 'Digital Mint (Sea Green → Mint)';
      case settings_service.ThemePreset.gentleOcean:
        return 'Gentle Ocean (Light Teal → Pale Lemon)';
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Subtitle Color'),
        content: SizedBox(
          width: 300,
          height: 200,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _subtitleColors.length,
            itemBuilder: (context, index) {
              final color = _subtitleColors[index];
              return GestureDetector(
                onTap: () {
                  _settingsService.setSubtitleColor(color.toARGB32());
                  Navigator.of(context).pop();
                  setState(() {});
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(
                      color: color.toARGB32() == _settingsService.subtitleColor
                          ? Colors.blue
                          : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showClearRecentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Recent Files'),
        content: const Text('Are you sure you want to clear all recent files?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Clear recent files logic would go here
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recent files cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showResetSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to default?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _settingsService.clearAll();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to default')),
              );
              setState(() {});
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showSupportedFormatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supported Formats'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Video Formats:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'MP4, AVI, MKV, MOV, WMV, FLV, WebM, M4V, 3GP, ASF, DIVX, F4V, M2TS, MTS, OGV, RM, RMVB, TS, VOB, XVID',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Audio Formats:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'MP3, WAV, FLAC, AAC, OGG, WMA, M4A, OPUS, AMR, AC3, DTS, APE, MKA',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
