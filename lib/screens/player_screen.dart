import 'dart:async';
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
  Timer? _hideTimer;
  static const Duration _autoHideDuration = Duration(seconds: 4);

  void _showControls() {
    if (!_controlsVisible) {
      setState(() => _controlsVisible = true);
    }
    _restartHideTimer();
  }

  void _restartHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_autoHideDuration, () {
      if (!mounted) return;
      final isPlaying = context.read<PlayerProvider>().isPlaying;
      if (isPlaying) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _handleMouseHover(event) {
    // Show controls when mouse moves near the bottom or if already visible
    final box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      final local = box.globalToLocal(event.position);
      final isBottom = local.dy > box.size.height - 120; // bottom threshold
      if (isBottom || _controlsVisible) {
        _showControls();
      }
    } else {
      _showControls();
    }
  }

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
      _restartHideTimer();
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
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          // Space: play/pause
          const SingleActivator(LogicalKeyboardKey.space): () =>
              context.read<PlayerProvider>().playOrPause(),
          // Arrow left/right: seek 5s
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => context
              .read<PlayerProvider>()
              .seekRelative(const Duration(seconds: -5)),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () => context
              .read<PlayerProvider>()
              .seekRelative(const Duration(seconds: 5)),
          // Arrow up/down: volume
          const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
              context.read<PlayerProvider>().setVolume(
                (context.read<PlayerProvider>().volume + 0.05).clamp(0.0, 1.0),
              ),
          const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
              context.read<PlayerProvider>().setVolume(
                (context.read<PlayerProvider>().volume - 0.05).clamp(0.0, 1.0),
              ),
          // F: fullscreen toggle
          const SingleActivator(LogicalKeyboardKey.keyF): () =>
              context.read<PlayerProvider>().toggleFullscreen(),
          // A: aspect ratio cycle
          const SingleActivator(LogicalKeyboardKey.keyA): () =>
              context.read<PlayerProvider>().cycleAspectRatio(),
          // S: fit cycle
          const SingleActivator(LogicalKeyboardKey.keyS): () =>
              context.read<PlayerProvider>().cycleFit(),
        },
        child: Focus(
          autofocus: true,
          child: Consumer2<PlayerProvider, MediaProvider>(
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

              return MouseRegion(
                onHover: _handleMouseHover,
                onEnter: (_) => _showControls(),
                child: Stack(
                  children: [
                    // Video player
                    Center(
                      child: AspectRatio(
                        aspectRatio: playerProvider.aspectRatio ?? 16 / 9,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _toggleControls,
                          onDoubleTap: () => playerProvider.playOrPause(),
                          // Double-tap left/right for seek
                          onDoubleTapDown: (details) {
                            final box =
                                context.findRenderObject() as RenderBox?;
                            if (box != null) {
                              final local = box.globalToLocal(
                                details.globalPosition,
                              );
                              final isLeft = local.dx < box.size.width / 2;
                              if (isLeft) {
                                playerProvider.seekRelative(
                                  const Duration(seconds: -10),
                                );
                              } else {
                                playerProvider.seekRelative(
                                  const Duration(seconds: 10),
                                );
                              }
                            }
                          },
                          child: Video(
                            controller: playerProvider.videoController,
                            controls: NoVideoControls,
                            fill: Colors.black, // avoid transparent background
                            fit: playerProvider.videoFit,
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
                              ? () =>
                                    _playPrevious(mediaProvider, playerProvider)
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
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });
    if (_controlsVisible) {
      _restartHideTimer();
    } else {
      _hideTimer?.cancel();
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
    _hideTimer?.cancel();
    // Reset system UI when leaving player
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}
