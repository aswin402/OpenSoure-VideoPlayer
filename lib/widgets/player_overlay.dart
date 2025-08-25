import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/media_provider.dart';

class PlayerOverlay extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onToggleFullscreen;

  const PlayerOverlay({
    super.key,
    required this.onClose,
    required this.onToggleFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.8),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Column(
        children: [
          // Top bar
          _buildTopBar(context),

          const Spacer(),

          // Center controls (brightness and volume gestures area)
          Expanded(flex: 3, child: _buildCenterControls(context)),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              color: Colors.white,
              onPressed: onClose,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Consumer<MediaProvider>(
                builder: (context, mediaProvider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mediaProvider.currentFile?.name ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (mediaProvider.currentPlaylist != null)
                        Text(
                          '${mediaProvider.currentIndex + 1} of ${mediaProvider.currentPlaylist!.files.length}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              color: Colors.white,
              onPressed: () => _showOptionsMenu(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        return Row(
          children: [
            // Left side - Brightness control
            Expanded(
              child: GestureDetector(
                onPanUpdate: (details) {
                  final delta = -details.delta.dy / 200;
                  final newBrightness = (playerProvider.brightness + delta)
                      .clamp(-1.0, 1.0);
                  playerProvider.setBrightness(newBrightness);
                },
                child: Container(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          playerProvider.brightness > 0
                              ? Icons.brightness_high_rounded
                              : playerProvider.brightness < 0
                              ? Icons.brightness_low_rounded
                              : Icons.brightness_medium_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Brightness\n${(playerProvider.brightness * 100).round()}%',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Center - Play/Pause area
            Expanded(
              flex: 2,
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            themeProvider.primaryColor.withOpacity(0.8),
                            themeProvider.secondaryColor.withOpacity(0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: themeProvider.primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
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
                            iconSize: 40,
                            onPressed: playerProvider.isBuffering
                                ? null
                                : playerProvider.playOrPause,
                          ),
                          if (playerProvider.isBuffering)
                            CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.8),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Right side - Volume control
            Expanded(
              child: GestureDetector(
                onPanUpdate: (details) {
                  final delta = -details.delta.dy / 200;
                  final newVolume = (playerProvider.volume + delta).clamp(
                    0.0,
                    1.0,
                  );
                  playerProvider.setVolume(newVolume);
                },
                child: Container(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          playerProvider.isMuted || playerProvider.volume == 0
                              ? Icons.volume_off_rounded
                              : playerProvider.volume < 0.5
                              ? Icons.volume_down_rounded
                              : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Volume\n${(playerProvider.volume * 100).round()}%',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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
      backgroundColor: Colors.black87,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.speed, color: Colors.white),
              title: const Text(
                'Playback Speed',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSpeedDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.aspect_ratio, color: Colors.white),
              title: const Text(
                'Aspect Ratio',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showAspectRatioDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.subtitles, color: Colors.white),
              title: const Text(
                'Subtitles',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showSubtitleDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.audiotrack, color: Colors.white),
              title: const Text(
                'Audio Track',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showAudioTrackDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.white),
              title: const Text(
                'Media Info',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showMediaInfoDialog(context);
              },
            ),
          ],
        ),
      ),
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

  void _showSubtitleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subtitles'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text('None')),
            ListTile(title: Text('Load from file...')),
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
