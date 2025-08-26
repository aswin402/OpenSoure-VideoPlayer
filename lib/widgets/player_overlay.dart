import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/media_provider.dart';
  import 'package:file_picker/file_picker.dart';

class PlayerOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onToggleFullscreen;

  const PlayerOverlay({
    super.key,
    required this.onClose,
    required this.onToggleFullscreen,
  });

  @override
  State<PlayerOverlay> createState() => _PlayerOverlayState();
}

class _PlayerOverlayState extends State<PlayerOverlay> {
  DateTime? _lastBrightnessTouch;
  DateTime? _lastVolumeTouch;

  bool get _showBrightness =>
      _lastBrightnessTouch != null &&
      DateTime.now().difference(_lastBrightnessTouch!) <
          const Duration(milliseconds: 900);
  bool get _showVolume =>
      _lastVolumeTouch != null &&
      DateTime.now().difference(_lastVolumeTouch!) <
          const Duration(milliseconds: 900);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        // Subtle dark veil only at the very top & bottom for minimalism
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xCC000000),
            Color(0x00000000),
            Color(0x00000000),
            Color(0xCC000000),
          ],
          stops: [0.0, 0.18, 0.82, 1.0],
        ),
      ),
      child: Column(
        children: [
          // Top bar
          _buildTopBar(context),

          // Center gestures with transient minimalist hints
          Expanded(child: _buildCenterControls(context)),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            _glassIconButton(icon: Icons.arrow_back, onTap: widget.onClose),
            const SizedBox(width: 10),
            Expanded(
              child: Consumer<MediaProvider>(
                builder: (context, mediaProvider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        mediaProvider.currentFile?.name ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (mediaProvider.currentPlaylist != null)
                        Text(
                          '${mediaProvider.currentIndex + 1} / ${mediaProvider.currentPlaylist!.files.length}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            _glassIconButton(
              icon: Icons.more_vert,
              onTap: () => _showOptionsMenu(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls(BuildContext context) {
    return Consumer2<PlayerProvider, ThemeProvider>(
      builder: (context, playerProvider, themeProvider, child) {
        return Row(
          children: [
            // Left side - Brightness gesture
            Expanded(
              child: GestureDetector(
                onPanUpdate: (details) {
                  final delta = -details.delta.dy / 220;
                  final newBrightness = (playerProvider.brightness + delta)
                      .clamp(-1.0, 1.0);
                  playerProvider.setBrightness(newBrightness);
                  setState(() => _lastBrightnessTouch = DateTime.now());
                },
                child: Container(
                  color: Colors.transparent,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 18),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _showBrightness ? 1.0 : 0.0,
                    child: _miniPill(
                      icon: playerProvider.brightness > 0
                          ? Icons.brightness_high_rounded
                          : playerProvider.brightness < 0
                          ? Icons.brightness_low_rounded
                          : Icons.brightness_medium_rounded,
                      label: '${(playerProvider.brightness * 100).round()}%',
                    ),
                  ),
                ),
              ),
            ),

            // Center - minimalist play/pause
            Expanded(
              flex: 2,
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.35),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          playerProvider.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        color: Colors.white,
                        iconSize: 34,
                        onPressed: playerProvider.isBuffering
                            ? null
                            : playerProvider.playOrPause,
                      ),
                      if (playerProvider.isBuffering)
                        CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.9),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Right side - Volume gesture
            Expanded(
              child: GestureDetector(
                onPanUpdate: (details) {
                  final delta = -details.delta.dy / 220;
                  final newVolume = (playerProvider.volume + delta).clamp(
                    0.0,
                    1.0,
                  );
                  playerProvider.setVolume(newVolume);
                  setState(() => _lastVolumeTouch = DateTime.now());
                },
                child: Container(
                  color: Colors.transparent,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 18),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _showVolume ? 1.0 : 0.0,
                    child: _miniPill(
                      icon: playerProvider.isMuted || playerProvider.volume == 0
                          ? Icons.volume_off_rounded
                          : playerProvider.volume < 0.5
                          ? Icons.volume_down_rounded
                          : Icons.volume_up_rounded,
                      label: '${(playerProvider.volume * 100).round()}%',
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetItem(
                icon: Icons.speed,
                label: 'Playback Speed',
                onTap: () {
                  Navigator.pop(context);
                  _showSpeedDialog(context);
                },
              ),
              _sheetItem(
                icon: Icons.aspect_ratio,
                label: 'Aspect Ratio',
                onTap: () {
                  Navigator.pop(context);
                  _showAspectRatioDialog(context);
                },
              ),
              _sheetItem(
                icon: Icons.subtitles,
                label: 'Subtitles',
                onTap: () {
                  Navigator.pop(context);
                  _showSubtitleDialog(context);
                },
              ),
              _sheetItem(
                icon: Icons.audiotrack,
                label: 'Audio Track',
                onTap: () {
                  Navigator.pop(context);
                  _showAudioTrackDialog(context);
                },
              ),
              _sheetItem(
                icon: Icons.info,
                label: 'Media Info',
                onTap: () {
                  Navigator.pop(context);
                  _showMediaInfoDialog(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // --- Small helpers for minimalist UI ---
  Widget _miniPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
      ),
      child: IconButton(
        icon: Icon(icon),
        color: Colors.white,
        onPressed: onTap,
      ),
    );
  }

  Widget _sheetItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
      dense: true,
      horizontalTitleGap: 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  void _showSpeedDialog(BuildContext context) {
    final playerProvider = context.read<PlayerProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Playback Speed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0]
              .map(
                (speed) => ListTile(
                  title: Text('${speed}x'),
                  leading: Radio<double>(
                    value: speed,
                    groupValue: playerProvider.playbackSpeed,
                    onChanged: (value) {
                      if (value != null) {
                        playerProvider.setPlaybackSpeed(value);
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showAspectRatioDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aspect Ratio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Original', '16:9', '4:3', '21:9', 'Stretch']
              .map(
                (ratio) => ListTile(
                  title: Text(ratio),
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Aspect ratio set to $ratio')),
                    );
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }




  Future<void> _showSubtitleDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subtitles'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('None'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement remove subtitles
              },
            ),
            ListTile(
              title: const Text('Load from file...'),
              onTap: () async {
                Navigator.pop(context);
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['srt', 'ass', 'vtt'],
                );

                if (result != null) {
                  String? subtitlePath = result.files.single.path;
                  // TODO: Implement load subtitles from path
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Loaded subtitle: $subtitlePath')),
                  );
                }
              },
            ),
          ],
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

  void _showAudioTrackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audio Track'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [ListTile(title: Text('Track 1 (Default)'))],
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

  void _showMediaInfoDialog(BuildContext context) {
    final mediaProvider = context.read<MediaProvider>();
    final playerProvider = context.read<PlayerProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Media Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow(
                'File',
                mediaProvider.currentFile?.name ?? 'Unknown',
              ),
              _buildInfoRow(
                'Size',
                mediaProvider.currentFile?.formattedSize ?? 'Unknown',
              ),
              _buildInfoRow('Duration', playerProvider.durationText),
              _buildInfoRow(
                'Format',
                mediaProvider.currentFile?.extension.toUpperCase() ?? 'Unknown',
              ),
              _buildInfoRow(
                'Path',
                mediaProvider.currentFile?.path ?? 'Unknown',
              ),
            ],
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
