import 'package:flutter/material.dart';
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (hovering) {
          setState(() {
            _isHovered = hovering;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail/Icon area
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getTypeColor(widget.file.type).withOpacity(0.8),
                      _getTypeColor(widget.file.type),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        _getTypeIcon(widget.file.type),
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    // Duration badge (if available)
                    if (widget.file.type == MediaType.video)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '00:00', // Placeholder duration
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    // Play button overlay
                    if (_isHovered)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                          ),
                          child: const Icon(
                            Icons.play_circle_outline,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // File info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.file.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.storage, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        widget.file.formattedSize,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const Spacer(),
                      Text(
                        widget.file.extension.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _getTypeColor(widget.file.type),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.file.formattedDate,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
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
    );
  }

  Color _getTypeColor(MediaType type) {
    switch (type) {
      case MediaType.video:
        return Colors.blue;
      case MediaType.audio:
        return Colors.green;
      case MediaType.unknown:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(MediaType type) {
    switch (type) {
      case MediaType.video:
        return Icons.video_file;
      case MediaType.audio:
        return Icons.audio_file;
      case MediaType.unknown:
        return Icons.insert_drive_file;
    }
  }
}
