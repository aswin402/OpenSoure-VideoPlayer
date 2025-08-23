import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../providers/player_provider.dart';
import '../providers/media_provider.dart';
import '../widgets/player_controls.dart';
import '../widgets/player_overlay.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _controlsVisible = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final mediaProvider = context.read<MediaProvider>();
    final playerProvider = context.read<PlayerProvider>();

    // Ensure PlayerProvider is initialized
    await playerProvider.initialize();

    if (mediaProvider.currentFile != null) {
      await playerProvider.openMedia(mediaProvider.currentFile!);
      setState(() {
        _isInitialized = true;
      });
    } else {
      setState(() {
        _isInitialized = true; // Still build UI (will show empty state)
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer2<PlayerProvider, MediaProvider>(
        builder: (context, playerProvider, mediaProvider, child) {
          if (!_isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          if (mediaProvider.currentFile == null) {
            return Center(
              child: Text(
                'No media selected',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
              ),
            );
          }

          return Stack(
            children: [
              // Video player
              Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: GestureDetector(
                    onTap: _toggleControls,
                    onDoubleTap: () => playerProvider.playOrPause(),
                    child: Video(
                      controller: playerProvider.videoController,
                      controls: NoVideoControls,
                      fill: Colors.black, // avoid transparent background
                      // Keep aspect fitted within parent
                      // Use fit to avoid unexpected cropping
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // Brightness overlay
              if (playerProvider.brightness != 0.0)
                Container(
                  color: Colors.black.withOpacity(
                    playerProvider.brightness < 0
                        ? -playerProvider.brightness * 0.5
                        : 0.0,
                  ),
                ),

              // Player overlay with controls
              if (_controlsVisible)
                PlayerOverlay(
                  onClose: () => Navigator.of(context).pop(),
                  onToggleFullscreen: _toggleFullscreen,
                ),

              // Player controls
              if (_controlsVisible)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: PlayerControls(
                    onPrevious: mediaProvider.hasPrevious
                        ? () => _playPrevious(mediaProvider, playerProvider)
                        : null,
                    onNext: mediaProvider.hasNext
                        ? () => _playNext(mediaProvider, playerProvider)
                        : null,
                  ),
                ),

              // Loading indicator
              if (playerProvider.isBuffering)
                const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
    );
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });

    // Auto-hide controls after 3 seconds
    if (_controlsVisible) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _controlsVisible = false;
          });
        }
      });
    }
  }

  void _toggleFullscreen() {
    final playerProvider = context.read<PlayerProvider>();

    if (playerProvider.isFullscreen) {
      // Exit fullscreen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      // Enter fullscreen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    playerProvider.toggleFullscreen();
  }

  void _playNext(
    MediaProvider mediaProvider,
    PlayerProvider playerProvider,
  ) async {
    mediaProvider.playNext();
    if (mediaProvider.currentFile != null) {
      await playerProvider.openMedia(mediaProvider.currentFile!);
    }
  }

  void _playPrevious(
    MediaProvider mediaProvider,
    PlayerProvider playerProvider,
  ) async {
    mediaProvider.playPrevious();
    if (mediaProvider.currentFile != null) {
      await playerProvider.openMedia(mediaProvider.currentFile!);
    }
  }

  @override
  void dispose() {
    // Reset system UI when leaving player
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}
