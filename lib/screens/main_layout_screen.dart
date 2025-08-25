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
import '../widgets/empty_state.dart';
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
    return Consumer<MediaProvider>(
      builder: (context, mediaProvider, child) {
        return Column(
          children: [
            // Enhanced Header with gradient background
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Media Library',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${mediaProvider.filteredFiles.length} files • ${mediaProvider.allFiles.length} total',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Enhanced view toggle with animation
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildViewToggleButton(
                              icon: Icons.grid_view_rounded,
                              isSelected: _isGridView,
                              onPressed: () =>
                                  setState(() => _isGridView = true),
                              tooltip: 'Grid View',
                            ),
                            _buildViewToggleButton(
                              icon: Icons.view_list_rounded,
                              isSelected: !_isGridView,
                              onPressed: () =>
                                  setState(() => _isGridView = false),
                              tooltip: 'List View',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Enhanced Add files button
                      ElevatedButton.icon(
                        onPressed: () => _handleAddFiles(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Files'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Search bar
                  custom.SearchBar(
                    controller: _searchController,
                    onChanged: mediaProvider.setSearchQuery,
                  ),
                ],
              ),
            ),

            // Enhanced Filter bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: FilterBar(
                selectedType: mediaProvider.filterType,
                onTypeChanged: mediaProvider.setFilterType,
                sortBy: mediaProvider.sortBy,
                sortAscending: mediaProvider.sortAscending,
                onSortChanged: mediaProvider.setSorting,
              ),
            ),

            // Content with enhanced loading and empty states
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: mediaProvider.isLoading
                    ? _buildLoadingState()
                    : mediaProvider.filteredFiles.isEmpty
                    ? _buildEmptyLibraryState()
                    : _isGridView
                    ? MediaGrid(
                        files: mediaProvider.filteredFiles,
                        onFileTap: _onFileTap,
                      )
                    : MediaList(
                        files: mediaProvider.filteredFiles,
                        onFileTap: _onFileTap,
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Icon(icon),
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading media files...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
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
    return Consumer<MediaProvider>(
      builder: (context, mediaProvider, child) {
        // Check if it's a search result or filter result
        if (mediaProvider.searchQuery.isNotEmpty) {
          return SearchEmptyState(searchQuery: mediaProvider.searchQuery);
        }

        if (mediaProvider.filterType != MediaType.unknown) {
          return FilterEmptyState(
            filterType: mediaProvider.filterType == MediaType.video
                ? 'Video'
                : 'Audio',
          );
        }

        // Default empty state with custom actions
        return EmptyState(
          icon: Icons.video_library_outlined,
          title: 'No Media Files',
          subtitle:
              'Add some videos or audio files to get started.\nYou can browse and organize your media collection here.',
          customAction: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _handleAddFiles(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Files'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _handleScanFolder(),
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text('Scan Folder'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyPlaylistsState() {
    return PlaylistEmptyState(
      onCreatePlaylist: () => _showCreatePlaylistDialog(),
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
