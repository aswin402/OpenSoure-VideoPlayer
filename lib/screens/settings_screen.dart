import 'package:flutter/material.dart' hide ThemeMode;
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import '../providers/media_provider.dart';

import '../widgets/theme_selector.dart';
import '../services/settings_service.dart' as settings_service;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final settings_service.SettingsService _settingsService =
      settings_service.SettingsService();
  bool _settingsReady = false;

  late final TabController _tabController;

  final List<Color> _subtitleColors = const [
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
    _tabController = TabController(length: 4, vsync: this);
    _initSettings();
  }

  Future<void> _initSettings() async {
    await _settingsService.initialize();
    if (!mounted) return;
    setState(() => _settingsReady = true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 16,
          title: const Text(
            'Preferences',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: ElevatedButton.icon(
                onPressed: _onSave,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(88),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customize your MX Player experience',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSegmentedTabs(context, primary, secondary),
                ],
              ),
            ),
          ),
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          foregroundColor: Colors.white,
        ),
        body: !_settingsReady
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading settings...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _PlaybackTab(settingsService: _settingsService),
                  _LibraryTab(settingsService: _settingsService),
                  _SubtitlesTab(
                    settingsService: _settingsService,
                    showColorPicker: _showColorPicker,
                  ),
                  _GeneralTab(
                    settingsService: _settingsService,
                    showClearRecentDialog: _showClearRecentDialog,
                    showResetSettingsDialog: _showResetSettingsDialog,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSegmentedTabs(
    BuildContext context,
    Color primary,
    Color secondary,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TabBar(
        controller: _tabController,
        labelPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        indicator: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        tabs: const [
          Tab(text: 'Playback'),
          Tab(text: 'Library'),
          Tab(text: 'Subtitles'),
          Tab(text: 'General'),
        ],
      ),
    );
  }

  void _onSave() {
    // Settings persist immediately in this app; provide UX feedback.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  // ===== Helpers & dialogs kept from previous screen =====

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

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Subtitle Color'),
        content: SizedBox(
          width: 300,
          height: 220,
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
            onPressed: () async {
              await context.read<MediaProvider>().clearRecentFiles();
              if (!context.mounted) return;
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
            onPressed: () async {
              await _settingsService.clearAll();
              if (!mounted) return;
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
}

// ===== Tabs =====

class _PlaybackTab extends StatelessWidget {
  const _PlaybackTab({required this.settingsService});
  final settings_service.SettingsService settingsService;

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final theme = Theme.of(context);

    return _SettingsCard(
      title: 'Playback Settings',
      subtitle: 'Control how your videos play.',
      child: Column(
        children: [
          _SwitchRow(
            title: 'Autoplay Next Video',
            value: settingsService.autoPlay,
            onChanged: (v) => settingsService.setAutoPlay(v),
          ),
          _SwitchRow(
            title: 'Remember Playback Position',
            value: settingsService.resumePlayback,
            onChanged: (v) => settingsService.setResumePlayback(v),
          ),
          const SizedBox(height: 12),
          _LabeledSlider(
            labelBuilder: (value) =>
                'Default Volume: ${(value * 100).round()}%',
            value: playerProvider.volume,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: (v) => playerProvider.setVolume(v),
          ),
          const SizedBox(height: 16),
          _DropdownRow<double>(
            title: 'Default Playback Speed',
            value: playerProvider.playbackSpeed,
            items: const [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0],
            itemText: (v) => v == 1.0 ? '1x (Normal)' : '${v}x',
            onChanged: (v) {
              if (v != null) playerProvider.setPlaybackSpeed(v);
            },
          ),
          const SizedBox(height: 12),
          _ListRow(
            title: 'Equalizer',
            subtitle: settingsService.eqEnabled
                ? {
                    settings_service.EqPreset.normal: 'Normal',
                    settings_service.EqPreset.bassBoost: 'Bass Boost',
                    settings_service.EqPreset.trebleBoost: 'Treble Boost',
                    settings_service.EqPreset.vocal: 'Vocal',
                    settings_service.EqPreset.custom: 'Custom',
                  }[settingsService.eqPreset]!
                : 'Off',
            leading: const Icon(Icons.equalizer),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed('/equalizer'),
          ),
          const Divider(height: 32),
          _ListRow(
            title: 'Repeat Mode',
            subtitle: _getRepeatModeText(
              playerProvider.repeatMode as settings_service.RepeatMode,
            ),
            trailing: IconButton(
              icon: _getRepeatModeIcon(
                playerProvider.repeatMode as settings_service.RepeatMode,
              ),
              onPressed: () => playerProvider.toggleRepeatMode(),
            ),
          ),
          _SwitchRow(
            title: 'Hardware Acceleration',
            value: settingsService.hardwareAcceleration,
            onChanged: (v) => settingsService.setHardwareAcceleration(v),
          ),
        ],
      ),
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
}

class _LibraryTab extends StatelessWidget {
  const _LibraryTab({required this.settingsService});
  final settings_service.SettingsService settingsService;

  @override
  Widget build(BuildContext context) {
    final media = context.watch<MediaProvider>();
    final theme = Theme.of(context);

    return _SettingsCard(
      title: 'Library Settings',
      subtitle: 'Manage folders and scanning.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () => media.loadFiles(force: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Rescan Now'),
              ),
              OutlinedButton.icon(
                onPressed: () => media.selectAndScanDirectory(),
                icon: const Icon(Icons.folder_open),
                label: const Text('Add Folders'),
              ),
              OutlinedButton.icon(
                onPressed: () => media.addFiles(),
                icon: const Icon(Icons.file_open),
                label: const Text('Add Files'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await media.loadFiles(regenerateThumbnails: true);
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Regenerating thumbnails in background...'),
                    ),
                  );
                },
                icon: const Icon(Icons.image_outlined),
                label: const Text('Regenerate Thumbnails'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Last scan will auto-refresh every 24 hours.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _SubtitlesTab extends StatelessWidget {
  const _SubtitlesTab({
    required this.settingsService,
    required this.showColorPicker,
  });
  final settings_service.SettingsService settingsService;
  final VoidCallback showColorPicker;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'Subtitle Settings',
      subtitle: 'Adjust text size and color.',
      child: Column(
        children: [
          _LabeledSlider(
            labelBuilder: (v) => 'Font Size: ${v.round()}px',
            value: settingsService.subtitleSize,
            min: 12,
            max: 32,
            divisions: 20,
            onChanged: (v) async {
              await settingsService.setSubtitleSize(v);
              // ignore: use_build_context_synchronously
              (context as Element).markNeedsBuild();
            },
          ),
          const SizedBox(height: 8),
          _ListRow(
            title: 'Font Color',
            subtitle: 'Subtitle text color',
            trailing: GestureDetector(
              onTap: showColorPicker,
              child: Container(
                width: 40,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(settingsService.subtitleColor),
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            onTap: showColorPicker,
          ),
        ],
      ),
    );
  }
}

class _GeneralTab extends StatelessWidget {
  const _GeneralTab({
    required this.settingsService,
    required this.showClearRecentDialog,
    required this.showResetSettingsDialog,
  });
  final settings_service.SettingsService settingsService;
  final VoidCallback showClearRecentDialog;
  final VoidCallback showResetSettingsDialog;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: _SettingsCard(
        title: 'General',
        subtitle: 'Appearance and maintenance.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ThemeSelector(),
            const SizedBox(height: 8),
            _ListRow(
              title: 'Clear Recent Files',
              subtitle: 'Remove all recently played files',
              leading: const Icon(Icons.clear_all_rounded),
              onTap: showClearRecentDialog,
            ),
            _ListRow(
              title: 'Reset Settings',
              subtitle: 'Reset all settings to default',
              leading: const Icon(Icons.restore_rounded),
              onTap: showResetSettingsDialog,
            ),
          ],
        ),
      ),
    );
  }
}

// ===== Reusable UI pieces to match screenshot styling =====

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ListRow(
      title: title,
      subtitle: subtitle,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: leading,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: subtitle != null
            ? Text(subtitle!, style: const TextStyle(color: Colors.white70))
            : null,
        trailing: trailing,
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.labelBuilder,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
  });
  final String Function(double) labelBuilder;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelBuilder(value),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: labelBuilder(value),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _DropdownRow<T> extends StatelessWidget {
  const _DropdownRow({
    required this.title,
    required this.value,
    required this.items,
    required this.itemText,
    required this.onChanged,
  });
  final String title;
  final T value;
  final List<T> items;
  final String Function(T) itemText;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ListRow(
      title: title,
      trailing: SizedBox(
        width: 220,
        child: DropdownButtonFormField<T>(
          value: value,
          items: items
              .map(
                (e) => DropdownMenuItem<T>(value: e, child: Text(itemText(e))),
              )
              .toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(borderSide: BorderSide.none),
            filled: true,
          ),
        ),
      ),
    );
  }
}
