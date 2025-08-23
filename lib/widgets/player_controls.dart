import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../providers/player_provider.dart';

class PlayerControls extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PlayerControls({super.key, this.onPrevious, this.onNext});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar
              _buildProgressBar(context, playerProvider),
              const SizedBox(height: 16),

              // Main controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Previous button
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    color: Colors.white,
                    iconSize: 32,
                    onPressed: onPrevious,
                  ),

                  // Rewind button
                  IconButton(
                    icon: const Icon(Icons.replay_10),
                    color: Colors.white,
                    iconSize: 28,
                    onPressed: () => playerProvider.seekRelative(
                      const Duration(seconds: -10),
                    ),
                  ),

                  // Play/Pause button
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        playerProvider.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      color: Colors.black,
                      iconSize: 36,
                      onPressed: playerProvider.playOrPause,
                    ),
                  ),

                  // Forward button
                  IconButton(
                    icon: const Icon(Icons.forward_10),
                    color: Colors.white,
                    iconSize: 28,
                    onPressed: () => playerProvider.seekRelative(
                      const Duration(seconds: 10),
                    ),
                  ),

                  // Next button
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    color: Colors.white,
                    iconSize: 32,
                    onPressed: onNext,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Secondary controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Volume control
                  _buildVolumeControl(context, playerProvider),

                  // Playback speed
                  _buildSpeedControl(context, playerProvider),

                  // Repeat mode
                  IconButton(
                    icon: _getRepeatIcon(playerProvider.repeatMode),
                    color: Colors.white,
                    onPressed: playerProvider.toggleRepeatMode,
                  ),

                  // Fullscreen toggle
                  IconButton(
                    icon: Icon(
                      playerProvider.isFullscreen
                          ? Icons.fullscreen_exit
                          : Icons.fullscreen,
                    ),
                    color: Colors.white,
                    onPressed: playerProvider.toggleFullscreen,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(BuildContext context, PlayerProvider playerProvider) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              playerProvider.positionText,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const Spacer(),
            Text(
              playerProvider.durationText,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.red,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: Colors.red,
            overlayColor: Colors.red.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: playerProvider.progress.clamp(0.0, 1.0),
            onChanged: (value) {
              final position = Duration(
                milliseconds: (value * playerProvider.duration.inMilliseconds)
                    .round(),
              );
              playerProvider.seek(position);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeControl(BuildContext context, PlayerProvider playerProvider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            playerProvider.isMuted || playerProvider.volume == 0
                ? Icons.volume_off
                : playerProvider.volume < 0.5
                ? Icons.volume_down
                : Icons.volume_up,
          ),
          color: Colors.white,
          onPressed: playerProvider.toggleMute,
        ),
        SizedBox(
          width: 80,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: playerProvider.volume,
              onChanged: playerProvider.setVolume,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedControl(
    BuildContext context,
    PlayerProvider playerProvider,
  ) {
    return GestureDetector(
      onTap: () => _showSpeedDialog(context, playerProvider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${playerProvider.playbackSpeed}x',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  void _showSpeedDialog(BuildContext context, PlayerProvider playerProvider) {
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Icon _getRepeatIcon(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.none:
        return const Icon(Icons.repeat);
      case RepeatMode.one:
        return const Icon(Icons.repeat_one);
      case RepeatMode.all:
        return const Icon(Icons.repeat);
    }
    return const Icon(Icons.repeat);
  }
}
