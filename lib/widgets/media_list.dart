import 'package:flutter/material.dart';
import '../models/media_file.dart';

class MediaList extends StatefulWidget {
  final List<MediaFile> files;
  final Function(MediaFile) onFileTap;

  const MediaList({super.key, required this.files, required this.onFileTap});

  @override
  State<MediaList> createState() => _MediaListState();
}

class _MediaListState extends State<MediaList> {
  final Set<int> _hoveredIndex = {};

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.files.length,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemBuilder: (context, index) {
        final file = widget.files[index];
        final isHovered = _hoveredIndex.contains(index);

        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredIndex.add(index)),
          onExit: (_) => setState(() => _hoveredIndex.remove(index)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isHovered
                  ? Theme.of(context).cardColor.withOpacity(0.95)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 16,
              ),
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: _getTypeColor(file.type),
                child: Icon(_getTypeIcon(file.type), color: Colors.white),
              ),
              title: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${file.formattedSize} • ${file.formattedDate}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(context, value, file),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'play',
                    child: Row(
                      children: [
                        Icon(Icons.play_arrow),
                        SizedBox(width: 8),
                        Text('Play'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'add_to_playlist',
                    child: Row(
                      children: [
                        Icon(Icons.playlist_add),
                        SizedBox(width: 8),
                        Text('Add to Playlist'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'properties',
                    child: Row(
                      children: [
                        Icon(Icons.info),
                        SizedBox(width: 8),
                        Text('Properties'),
                      ],
                    ),
                  ),
                ],
                tooltip: 'Actions',
              ),
              onTap: () => widget.onFileTap(file),
            ),
          ),
        );
      },
    );
  }

  Color _getTypeColor(MediaType type) {
    switch (type) {
      case MediaType.video:
        return Colors.blueAccent;
      case MediaType.audio:
        return Colors.green;
      case MediaType.unknown:
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(MediaType type) {
    switch (type) {
      case MediaType.video:
        return Icons.videocam;
      case MediaType.audio:
        return Icons.audiotrack;
      case MediaType.unknown:
      default:
        return Icons.insert_drive_file;
    }
  }

  void _handleMenuAction(BuildContext context, String action, MediaFile file) {
    switch (action) {
      case 'play':
        widget.onFileTap(file);
        break;
      case 'add_to_playlist':
        _showAddToPlaylistDialog(context, file);
        break;
      case 'properties':
        _showPropertiesDialog(context, file);
        break;
    }
  }

  void _showAddToPlaylistDialog(BuildContext context, MediaFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Playlist'),
        content: const Text('Playlist selection would appear here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showPropertiesDialog(BuildContext context, MediaFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPropertyRow('Path', file.path),
            _buildPropertyRow('Size', file.formattedSize),
            _buildPropertyRow('Type', file.extension.toUpperCase()),
            _buildPropertyRow('Modified', file.formattedDate),
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

  Widget _buildPropertyRow(String label, String value) {
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
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}
