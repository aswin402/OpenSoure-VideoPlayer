import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/media_provider.dart';
import '../providers/theme_provider.dart';
import '../models/media_file.dart';
import '../widgets/media_grid.dart';
import '../widgets/media_list.dart';
import '../widgets/media_tile.dart';
import '../widgets/search_bar.dart' as custom;
import '../widgets/filter_bar.dart';
import '../screens/player_screen.dart';
import '../screens/playlists_screen.dart';
import '../screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // MediaProvider is already initialized in main.dart
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MX Player Clone'),
        elevation: 0,
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
          // Search icon (opens inline search in body widget)
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => setState(() {}),
          ),
          // Layout toggle
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
          PopupMenuButton<String>(
            color: const Color(0xFF1E1E1E),
            onSelected: _handleMenuSelection,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'scan_folder',
                child: Row(
                  children: [
                    Icon(Icons.folder_open, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Scan Folder'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add_files',
                child: Row(
                  children: [
                    Icon(Icons.add, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Add Files'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'playlists',
                child: Row(
                  children: [
                    Icon(Icons.playlist_play, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Playlists'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Videos', icon: Icon(Icons.video_library)),
            Tab(text: 'Music', icon: Icon(Icons.music_note)),
            Tab(text: 'All', icon: Icon(Icons.folder)),
          ],
          onTap: (index) {
            final mediaProvider = context.read<MediaProvider>();
            switch (index) {
              case 0:
                mediaProvider.setFilterType(MediaType.video);
                break;
              case 1:
                mediaProvider.setFilterType(MediaType.audio);
                break;
              case 2:
                mediaProvider.setFilterType(MediaType.unknown);
                break;
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Compact sort & count bar
          const FilterBar(),
          // Search bar (animated inline)
          const custom.SearchBar(),
          Expanded(
            child: Consumer<MediaProvider>(
              builder: (context, mediaProvider, child) {
                if (mediaProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView(
                  children: [
                    // Recently played section
                    if (mediaProvider.recentFiles.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.history,
                              color: Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Recently played',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 150,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          scrollDirection: Axis.horizontal,
                          itemCount: math.min(
                            mediaProvider.recentFiles.length,
                            12,
                          ),
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final file = mediaProvider.recentFiles[index];
                            return SizedBox(
                              width: 240,
                              child: MediaTile(
                                file: file,
                                onTap: () => _onFileTap(file),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    // All files section
                    if (mediaProvider.filteredFiles.isEmpty)
                      _buildEmptyState(context)
                    else
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _isGridView
                            ? MediaGrid(
                                files: mediaProvider.filteredFiles,
                                onFileTap: _onFileTap,
                              )
                            : MediaList(
                                files: mediaProvider.filteredFiles,
                                onFileTap: _onFileTap,
                              ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleMenuSelection('add_files'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
                      onPressed: () => _handleMenuSelection('add_files'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Files'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () => _handleMenuSelection('scan_folder'),
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

  void _onFileTap(MediaFile file) {
    final mediaProvider = context.read<MediaProvider>();
    mediaProvider.setCurrentFile(file);

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => PlayerScreen(file: file)));
  }

  void _handleMenuSelection(String value) async {
    final mediaProvider = context.read<MediaProvider>();

    switch (value) {
      case 'scan_folder':
        // Open a directory picker and scan the selected folder
        await mediaProvider.selectAndScanDirectory();
        break;
      case 'add_files':
        await mediaProvider.addFiles();
        break;
      case 'playlists':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const PlaylistsScreen()),
        );
        break;
      case 'settings':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
        break;
    }
  }
}
