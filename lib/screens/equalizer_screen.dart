import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';
import '../providers/player_provider.dart';

// Equalizer Screen: modern, minimal, theme-accented
class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  final SettingsService _settings = SettingsService();
  bool _ready = false;

  bool _enabled = false;
  EqPreset _preset = EqPreset.normal;

  double _bass = 0.0;
  double _lowMid = 0.0;
  double _mid = 0.0;
  double _highMid = 0.0;
  double _treble = 0.0;

  // Audio enhancements
  bool _bassBoostEnabled = false;
  double _bassBoostStrength = 0.0;
  bool _virtualizerEnabled = false;
  double _virtualizerStrength = 0.0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _settings.initialize();
    _enabled = _settings.eqEnabled;
    _preset = _settings.eqPreset;
    _bass = _settings.eqBass;
    _lowMid = _settings.eqLowMid;
    _mid = _settings.eqMid;
    _highMid = _settings.eqHighMid;
    _treble = _settings.eqTreble;

    // Load audio enhancement settings
    _bassBoostEnabled = _settings.bassBoostEnabled;
    _bassBoostStrength = _settings.bassBoostStrength;
    _virtualizerEnabled = _settings.virtualizerEnabled;
    _virtualizerStrength = _settings.virtualizerStrength;

    setState(() => _ready = true);
  }

  void _applyPreset(EqPreset preset) {
    // Simple curves; values in -1.0..+1.0
    switch (preset) {
      case EqPreset.normal:
        _bass = 0.0;
        _lowMid = 0.0;
        _mid = 0.0;
        _highMid = 0.0;
        _treble = 0.0;
        break;
      case EqPreset.bassBoost:
        _bass = 0.6;
        _lowMid = 0.3;
        _mid = 0.0;
        _highMid = -0.1;
        _treble = -0.1;
        break;
      case EqPreset.trebleBoost:
        _bass = -0.1;
        _lowMid = 0.0;
        _mid = 0.1;
        _highMid = 0.35;
        _treble = 0.6;
        break;
      case EqPreset.vocal:
        _bass = -0.1;
        _lowMid = 0.1;
        _mid = 0.5;
        _highMid = 0.3;
        _treble = 0.0;
        break;
      case EqPreset.custom:
        // Keep current custom values
        break;
    }
  }

  Future<void> _persist() async {
    await _settings.setEqEnabled(_enabled);
    await _settings.setEqPreset(_preset);
    await _settings.setEqBass(_bass);
    await _settings.setEqLowMid(_lowMid);
    await _settings.setEqMid(_mid);
    await _settings.setEqHighMid(_highMid);
    await _settings.setEqTreble(_treble);

    // Persist audio enhancement settings
    await _settings.setBassBoostEnabled(_bassBoostEnabled);
    await _settings.setBassBoostStrength(_bassBoostStrength);
    await _settings.setVirtualizerEnabled(_virtualizerEnabled);
    await _settings.setVirtualizerStrength(_virtualizerStrength);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.secondary; // app uses secondary as CTA
    final secondary =
        theme.colorScheme.primary; // Use primary as secondary accent
    final surface = theme.cardColor;

    if (!_ready) {
      return Scaffold(
        appBar: AppBar(title: const Text('Equalizer')),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primary),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Equalizer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card with toggle and preset
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Audio Equalizer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Fine-tune audio with five bands. Presets available.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _enabled,
                    activeColor: Colors.white,
                    activeTrackColor: primary,
                    onChanged: (v) async {
                      setState(() => _enabled = v);
                      await _persist();
                      // apply live (avoid context across async gap)
                      final pp = context.read<PlayerProvider>();
                      await pp.applyEqualizerFromSettings();

                      // Show feedback to user
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              v ? 'Equalizer enabled' : 'Equalizer disabled',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Preset selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Preset',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<EqPreset>(
                      value: _preset,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        filled: true,
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: EqPreset.normal,
                          child: Text('Normal'),
                        ),
                        DropdownMenuItem(
                          value: EqPreset.bassBoost,
                          child: Text('Bass Boost'),
                        ),
                        DropdownMenuItem(
                          value: EqPreset.trebleBoost,
                          child: Text('Treble Boost'),
                        ),
                        DropdownMenuItem(
                          value: EqPreset.vocal,
                          child: Text('Vocal'),
                        ),
                        DropdownMenuItem(
                          value: EqPreset.custom,
                          child: Text('Custom'),
                        ),
                      ],
                      onChanged: (p) async {
                        if (p == null) return;
                        setState(() {
                          _preset = p;
                          _applyPreset(p);
                        });
                        await _persist();
                        final pp = context.read<PlayerProvider>();
                        await pp.applyEqualizerFromSettings();

                        // Show feedback to user
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Applied ${p.name} preset'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Sliders row
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: AbsorbPointer(
                        absorbing: !_enabled,
                        child: Opacity(
                          opacity: _enabled ? 1.0 : 0.5,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children:
                                [
                                      _EqBand(
                                        label: 'Bass',
                                        value: _bass,
                                        onChanged: (v) =>
                                            _onBandChanged(() => _bass = v),
                                        activeColor: primary,
                                      ),
                                      _EqBand(
                                        label: 'Low-Mid',
                                        value: _lowMid,
                                        onChanged: (v) =>
                                            _onBandChanged(() => _lowMid = v),
                                        activeColor: primary,
                                      ),
                                      _EqBand(
                                        label: 'Mid',
                                        value: _mid,
                                        onChanged: (v) =>
                                            _onBandChanged(() => _mid = v),
                                        activeColor: primary,
                                      ),
                                      _EqBand(
                                        label: 'High-Mid',
                                        value: _highMid,
                                        onChanged: (v) =>
                                            _onBandChanged(() => _highMid = v),
                                        activeColor: primary,
                                      ),
                                      _EqBand(
                                        label: 'Treble',
                                        value: _treble,
                                        onChanged: (v) =>
                                            _onBandChanged(() => _treble = v),
                                        activeColor: primary,
                                      ),
                                    ]
                                    .expand(
                                      (w) => [
                                        Expanded(child: w),
                                        const SizedBox(width: 8),
                                      ],
                                    )
                                    .toList()
                                  ..removeLast(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          setState(() => _preset = EqPreset.custom);
                          await _persist();
                          final pp = context.read<PlayerProvider>();
                          await pp.applyEqualizerFromSettings();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Custom preset saved'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save Custom Preset'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Audio Enhancements Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Audio Enhancements',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enhance your audio experience with bass boost and spatial effects.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bass Boost
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.graphic_eq,
                                  color: primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Bass Boost',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enhance low-frequency response',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _bassBoostEnabled,
                        activeColor: Colors.white,
                        activeTrackColor: primary,
                        onChanged: (v) async {
                          setState(() => _bassBoostEnabled = v);
                          await _persist();
                          if (!mounted) return;
                          final pp = context.read<PlayerProvider>();
                          await pp.applyEqualizerFromSettings();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  v
                                      ? 'Bass boost enabled'
                                      : 'Bass boost disabled',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),

                  // Bass Boost Strength Slider
                  if (_bassBoostEnabled) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const SizedBox(width: 28), // Align with icon
                        Text(
                          'Strength',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: primary,
                              inactiveTrackColor: Colors.white.withValues(
                                alpha: 0.15,
                              ),
                              trackHeight: 4,
                              thumbColor: Colors.white,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                              overlayColor: primary.withValues(alpha: 0.15),
                            ),
                            child: Slider(
                              value: _bassBoostStrength,
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              onChanged: (v) async {
                                setState(() => _bassBoostStrength = v);
                                await _persist();
                                final pp = context.read<PlayerProvider>();
                                await pp.applyEqualizerFromSettings();
                              },
                            ),
                          ),
                        ),
                        Text(
                          '${(_bassBoostStrength * 100).round()}%',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Virtualizer
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.surround_sound,
                                  color: secondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Virtualizer',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create spatial surround sound effect',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _virtualizerEnabled,
                        activeColor: Colors.white,
                        activeTrackColor: secondary,
                        onChanged: (v) async {
                          setState(() => _virtualizerEnabled = v);
                          await _persist();
                          if (!mounted) return;
                          final pp = context.read<PlayerProvider>();
                          await pp.applyEqualizerFromSettings();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  v
                                      ? 'Virtualizer enabled'
                                      : 'Virtualizer disabled',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),

                  // Virtualizer Strength Slider
                  if (_virtualizerEnabled) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const SizedBox(width: 28), // Align with icon
                        Text(
                          'Strength',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: secondary,
                              inactiveTrackColor: Colors.white.withValues(
                                alpha: 0.15,
                              ),
                              trackHeight: 4,
                              thumbColor: Colors.white,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                              overlayColor: secondary.withValues(alpha: 0.15),
                            ),
                            child: Slider(
                              value: _virtualizerStrength,
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              onChanged: (v) async {
                                setState(() => _virtualizerStrength = v);
                                await _persist();
                                final pp = context.read<PlayerProvider>();
                                await pp.applyEqualizerFromSettings();
                              },
                            ),
                          ),
                        ),
                        Text(
                          '${(_virtualizerStrength * 100).round()}%',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onBandChanged(void Function() apply) async {
    setState(() {
      apply();
      if (_preset != EqPreset.custom) {
        _preset = EqPreset.custom; // mark as custom on manual change
      }
    });
    await _persist();
    final pp = context.read<PlayerProvider>();
    await pp.applyEqualizerFromSettings();
  }
}

// A single vertical EQ band using a rotated Slider with custom theme.
class _EqBand extends StatelessWidget {
  const _EqBand({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  final String label;
  final double value; // -1.0..+1.0
  final ValueChanged<double> onChanged;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final neutral = Colors.white.withValues(alpha: 0.15);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Scale: show numeric gain in dB-ish (-10..+10)
        Text(
          _formatDb(value),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: RotatedBox(
            quarterTurns: -1,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: activeColor,
                inactiveTrackColor: neutral,
                trackHeight: 8,
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayColor: activeColor.withValues(alpha: 0.15),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                trackShape: const RoundedRectSliderTrackShape(),
              ),
              child: Slider(
                value: value,
                min: -1.0,
                max: 1.0,
                divisions: 20,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _formatDb(double v) {
    final db = (v * 10).toStringAsFixed(0);
    return (v > 0 ? '+$db dB' : '$db dB');
  }
}
