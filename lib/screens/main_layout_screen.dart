import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/media_provider.dart';
import '../providers/theme_provider.dart';
import '../models/media_file.dart';
import '../widgets/media_grid.dart';
import '../widgets/media_list.dart';
import '../widgets/search_bar.dart' as custom;
import '../widgets/filter_bar.dart';
import '../widgets/playlist_tile.dart';
import '../widgets/create_playlist_dialog.dart';
import '../screens/player_screen.dart';
import '../screens/playlists_screen.dart';
import '../screens/settings_screen.dart';

enum NavigationItem { player, library, playlists, favorites }

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  NavigationItem _selectedItem = NavigationItem.library;
  bool _isGridView = true;
  final TextEditingController _searchController = TextEditingController();
  String _playlistSearchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),
          // Main content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF121212),
                    Theme.of(context).primaryColor.withOpacity(0.05),
                  ],
                ),
              ),
              child: _buildMainContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          width: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                themeProvider.primaryColor.withOpacity(0.1),
                const Color(0xFF1A1A1A),
              ],
            ),
          ),
          child: Column(
            children: [
              // App header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      themeProvider.primaryColor,
                      themeProvider.secondaryColor,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MX Clone',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Media Player for Flutter',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(
                color: themeProvider.primaryColor.withOpacity(0.3),
                height: 1,
              ),
              const SizedBox(height: 20),

              // Navigation section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'NAVIGATION',
                    style: TextStyle(
                      color: themeProvider.secondaryColor.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Navigation items
              _buildNavItem(
                icon: Icons.play_circle_outline,
                label: 'Player',
                item: NavigationItem.player,
                themeProvider: themeProvider,
              ),
              _buildNavItem(
                icon: Icons.video_library_outlined,
                label: 'Library',
                item: NavigationItem.library,
                themeProvider: themeProvider,
              ),
              _buildNavItem(
                icon: Icons.playlist_play,
                label: 'Playlists',
                item: NavigationItem.playlists,
                themeProvider: themeProvider,
              ),
              _buildNavItem(
                icon: Icons.favorite_outline,
                label: 'Favorites',
                item: NavigationItem.favorites,
                themeProvider: themeProvider,
              ),

              const Spacer(),

              // Settings at bottom
              Padding(
                padding: const EdgeInsets.all(20),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.settings, color: Colors.grey, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Settings',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required NavigationItem item,
    required ThemeProvider themeProvider,
  }) {
    final isSelected = _selectedItem == item;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedItem = item;
              });
            },
            borderRadius: BorderRadius.circular(8),
            hoverColor: themeProvider.secondaryColor.withOpacity(0.1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          themeProvider.primaryColor,
                          themeProvider.secondaryColor,
                        ],
                      )
                    : null,
                color: isSelected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.white : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedItem) {
      case NavigationItem.player:
        return _buildPlayerContent();
      case NavigationItem.library:
        return _buildLibraryContent();
      case NavigationItem.playlists:
        return _buildPlaylistsContent();
      case NavigationItem.favorites:
        return _buildFavoritesContent();
    }
  }

  Widget _buildPlayerContent() {
    return Consumer<MediaProvider>(
      builder: (context, mediaProvider, _) {
        if (mediaProvider.currentFile == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No media playing',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Select a file from your library to start playing',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Now Playing',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          mediaProvider.currentFile!.type == MediaType.video
                              ? Icons.video_file
                              : Icons.audio_file,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mediaProvider.currentFile!.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${mediaProvider.currentFile!.formattedSize} • ${mediaProvider.currentFile!.formattedDate}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const PlayerScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.fullscreen),
                        label: const Text('Full Player'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLibraryContent() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Library',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Browse and manage your media files',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // View toggle
              IconButton(
                icon: Icon(
                  _isGridView ? Icons.list : Icons.grid_view,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
              // Add files button
              ElevatedButton.icon(
                onPressed: () => _handleAddFiles(),
                icon: const Icon(Icons.add),
                label: const Text('Add Files'),
              ),
            ],
          ),
        ),

        // Filter bar and search
        const FilterBar(),
        const custom.SearchBar(),

        // Content
        Expanded(
          child: Consumer<MediaProvider>(
            builder: (context, mediaProvider, child) {
              if (mediaProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (mediaProvider.filteredFiles.isEmpty) {
                return _buildEmptyLibraryState();
              }

              return _isGridView
                  ? MediaGrid(
                      files: mediaProvider.filteredFiles,
                      onFileTap: _onFileTap,
                    )
                  : MediaList(
                      files: mediaProvider.filteredFiles,
                      onFileTap: _onFileTap,
                    );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistsContent() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Playlists',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Create and manage your video playlists',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreatePlaylistDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Create Playlist'),
              ),
            ],
          ),
        ),

        // Search bar for playlists
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _playlistSearchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search playlists...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: Icon(
                  Icons.search,
                  color: themeProvider.secondaryColor,
                ),
                filled: true,
                fillColor: themeProvider.primaryColor.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: themeProvider.primaryColor.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: themeProvider.primaryColor.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: themeProvider.secondaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),

        // Playlists content
        Expanded(
          child: Consumer<MediaProvider>(
            builder: (context, mediaProvider, child) {
              if (mediaProvider.playlists.isEmpty) {
                return _buildEmptyPlaylistsState();
              }

              // Filter playlists based on search query
              final filteredPlaylists = _playlistSearchQuery.isEmpty
                  ? mediaProvider.playlists
                  : mediaProvider.playlists
                        .where(
                          (playlist) => playlist.name.toLowerCase().contains(
                            _playlistSearchQuery,
                          ),
                        )
                        .toList();

              if (filteredPlaylists.isEmpty &&
                  _playlistSearchQuery.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No playlists found',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try a different search term',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: filteredPlaylists.length,
                itemBuilder: (context, index) {
                  final playlist = filteredPlaylists[index];
                  return PlaylistTile(
                    playlist: playlist,
                    onTap: () => _openPlaylist(playlist),
                    onDelete: () => _deletePlaylist(playlist),
                    onEdit: () => _editPlaylist(playlist),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Favorites',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Your favorite media files',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 40),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Mark files as favorites to see them here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLibraryState() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.video_library_outlined,
                  size: 72,
                  color: Colors.white70,
                ),
                const SizedBox(height: 16),
                Text(
                  'No media files found',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add files or scan folders to get started',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFB0BEC5),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _handleAddFiles(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Files'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () => _handleScanFolder(),
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Scan Folder'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPlaylistsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Playlist icon with lines (similar to screenshot)
          Column(
            children: [
              Container(
                width: 4,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 4,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 4,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'No playlists found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first playlist to organize your videos',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showCreatePlaylistDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Create Playlist'),
          ),
        ],
      ),
    );
  }

  void _onFileTap(MediaFile file) {
    final mediaProvider = context.read<MediaProvider>();
    mediaProvider.setCurrentFile(file);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const PlayerScreen()));
  }

  void _handleAddFiles() async {
    final mediaProvider = context.read<MediaProvider>();
    await mediaProvider.addFiles();
  }

  void _handleScanFolder() async {
    final mediaProvider = context.read<MediaProvider>();
    await mediaProvider.selectAndScanDirectory();
  }

  void _showCreatePlaylistDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreatePlaylistDialog(),
    );
  }

  void _openPlaylist(playlist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }

  void _deletePlaylist(playlist) {
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

  void _editPlaylist(playlist) {
    showDialog(
      context: context,
      builder: (context) => CreatePlaylistDialog(playlist: playlist),
    );
  }
}
