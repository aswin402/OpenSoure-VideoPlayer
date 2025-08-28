import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/media_provider.dart';

// Simple mini player (PiP-like) docked bottom-right for desktop/web
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerProvider, MediaProvider>(
      builder: (context, player, media, _) {
        if (!player.miniPlayerVisible || media.currentFile == null)
          return const SizedBox.shrink();

        return Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Material(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 320,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    // Title and progress text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            media.currentFile!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${player.positionText} / ${player.durationText}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: player.isPlaying ? 'Pause' : 'Play',
                      icon: Icon(
                        player.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: player.playOrPause,
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: player.hideMiniPlayer,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
