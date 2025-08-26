import 'package:flutter/material.dart';
import '../models/playlist.dart';

class PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const PlaylistTile({
    super.key,
    required this.playlist,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColorLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                playlist.files.length.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Text(
            playlist.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${playlist.files.length} files',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
              ),
              Text(
                'Modified: ${_formatDate(playlist.lastModified)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
          trailing: _buildPopupMenu(context),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tooltip: 'Playlist Options',
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      onSelected: _handleMenuAction,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'play',
          child: Row(
            children: [
              Icon(Icons.play_arrow, size: 18),
              SizedBox(width: 8),
              Text('Play'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'shuffle',
          child: Row(
            children: [
              Icon(Icons.shuffle, size: 18),
              SizedBox(width: 8),
              Text('Shuffle Play'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Rename'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'play':
      case 'shuffle':
        onTap();
        break;
      case 'edit':
        onEdit();
        break;
      case 'delete':
        onDelete();
        break;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
