import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/media_provider.dart';
import '../providers/theme_provider.dart';
import '../models/playlist.dart';
import '../models/media_file.dart';
import '../widgets/playlist_tile.dart';
import '../widgets/create_playlist_dialog.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        flexibleSpace: Consumer<ThemeProvider>(
          builder: (context, theme, _) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [theme.primaryColor, theme.secondaryColor],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreatePlaylistDialog(context),
          ),
        ],
      ),
      body: Consumer<MediaProvider>(
        builder: (context, mediaProvider, child) {
          if (mediaProvider.playlists.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            itemCount: mediaProvider.playlists.length,
            itemBuilder: (context, index) {
              final playlist = mediaProvider.playlists[index];
              return PlaylistTile(
                playlist: playlist,
                onTap: () => _openPlaylist(context, playlist),
                onDelete: () => _deletePlaylist(context, playlist),
                onEdit: () => _editPlaylist(context, playlist),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.playlist_play, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No playlists yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first playlist to organize your media',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreatePlaylistDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Playlist'),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreatePlaylistDialog(),
    );
  }

  void _openPlaylist(BuildContext context, Playlist playlist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }

  void _deletePlaylist(BuildContext context, Playlist playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Are you sure you want to delete "${playlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<MediaProvider>().deletePlaylist(playlist);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editPlaylist(BuildContext context, Playlist playlist) {
    showDialog(
      context: context,
      builder: (context) => CreatePlaylistDialog(playlist: playlist),
    );
  }
}

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: playlist.files.isNotEmpty
                ? () => _shufflePlay(context)
                : null,
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_files',
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('Add Files'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear Playlist'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<MediaProvider>(
        builder: (context, mediaProvider, _) {
          final files =
              playlist.files; // same instance; Consumer ensures rebuild
          if (files.isEmpty) return _buildEmptyPlaylist(context);
          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Icon(
                    file.type == MediaType.video
                        ? Icons.video_file
                        : Icons.audio_file,
                    color: Colors.white,
                  ),
                ),
                title: Text(file.name),
                subtitle: Text('${file.formattedSize} • ${file.formattedDate}'),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => _removeFromPlaylist(context, file),
                ),
                onTap: () => _playFile(context, file),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addFilesToPlaylist(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyPlaylist(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.playlist_add, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Empty playlist',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some files to get started',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addFilesToPlaylist(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Files'),
          ),
        ],
      ),
    );
  }

  void _shufflePlay(BuildContext context) {
    if (playlist.files.isNotEmpty) {
      final shuffledPlaylist = Playlist(
        id: '${playlist.id}_shuffled',
        name: '${playlist.name} (Shuffled)',
        files: List.from(playlist.files)..shuffle(),
        createdAt: playlist.createdAt,
        lastModified: playlist.lastModified,
      );

      final mediaProvider = context.read<MediaProvider>();
      mediaProvider.setCurrentFile(
        shuffledPlaylist.files.first,
        playlist: shuffledPlaylist,
      );

      Navigator.of(context).pushNamed('/player');
    }
  }

  void _playFile(BuildContext context, MediaFile file) {
    final mediaProvider = context.read<MediaProvider>();
    mediaProvider.setCurrentFile(file, playlist: playlist);
    Navigator.of(context).pushNamed('/player');
  }

  void _removeFromPlaylist(BuildContext context, MediaFile file) {
    context.read<MediaProvider>().removeFromPlaylist(playlist, file);
  }

  Future<void> _addFilesToPlaylist(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<MediaProvider>().pickAndAddFilesToPlaylist(playlist);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Files added to playlist')),
      );
    } catch (_) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to add files')),
      );
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'add_files':
        _addFilesToPlaylist(context);
        break;
      case 'clear':
        _clearPlaylist(context);
        break;
    }
  }

  void _clearPlaylist(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Playlist'),
        content: const Text(
          'Are you sure you want to remove all files from this playlist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<MediaProvider>().clearPlaylist(playlist);
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
