import 'dart:io';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/media_file.dart';

class MediaTile extends StatefulWidget {
  final MediaFile file;
  final VoidCallback onTap;

  const MediaTile({super.key, required this.file, required this.onTap});

  @override
  State<MediaTile> createState() => _MediaTileState();
}

class _MediaTileState extends State<MediaTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isHovered
            ? [
                BoxShadow(
                  color: const Color(0x662196F3), // subtle blue glow
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _isHovered ? 1.02 : 1.0,
        child: Card(
          color: theme.cardColor,
          elevation: _isHovered ? 6 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (hovering) => setState(() => _isHovered = hovering),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail/Icon area
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.file.thumbnailPath != null &&
                          widget.file.thumbnailPath!.isNotEmpty &&
                          File(widget.file.thumbnailPath!).existsSync())
                        Image.file(
                          File(widget.file.thumbnailPath!),
                          fit: BoxFit.cover,
                        )
                      else
                        Consumer<ThemeProvider>(
                          builder: (context, theme, _) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    theme.primaryColor,
                                    theme.secondaryColor,
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  '🎥',
                                  style: TextStyle(fontSize: 56),
                                ),
                              ),
                            );
                          },
                        ),

                      // Duration badge (bottom-right)
                      if (widget.file.type == MediaType.video)
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.file.formattedDuration,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ),

                      // Play overlay hint on hover
                      if (_isHovered)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.18),
                            child: const Icon(
                              Icons.play_circle_outline,
                              size: 36,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // File info
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File name - bold single line
                      Text(
                        widget.file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Meta row: size • date + extension pill at right
                      Row(
                        children: [
                          Icon(
                            Icons.storage,
                            size: 12,
                            color: const Color(0xFF9E9E9E),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.file.formattedSize,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF9E9E9E),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF9E9E9E),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: const Color(0xFF9E9E9E),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.file.formattedDate,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF9E9E9E),
                              ),
                            ),
                          ),

                          // Extension badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.file.extension.isNotEmpty
                                  ? widget.file.extension
                                        .replaceFirst('.', '')
                                        .toUpperCase()
                                  : 'FILE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(MediaType type) {
    switch (type) {
      case MediaType.video:
        return Icons.videocam_rounded;
      case MediaType.audio:
        return Icons.audiotrack_rounded;
      case MediaType.unknown:
        return Icons.insert_drive_file_rounded;
    }
  }
}
