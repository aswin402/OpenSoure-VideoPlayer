import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/media_provider.dart';
import '../models/media_file.dart';
import '../widgets/media_grid.dart';
import '../widgets/media_list.dart';
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
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'scan_folder',
                child: Row(
                  children: [
                    Icon(Icons.folder_open),
                    SizedBox(width: 8),
                    Text('Scan Folder'),
                  ],
                ),
              ),
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
                value: 'playlists',
                child: Row(
                  children: [
                    Icon(Icons.playlist_play),
                    SizedBox(width: 8),
                    Text('Playlists'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
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
          const custom.SearchBar(),
          const FilterBar(),
          Expanded(
            child: Consumer<MediaProvider>(
              builder: (context, mediaProvider, child) {
                if (mediaProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (mediaProvider.filteredFiles.isEmpty) {
                  return _buildEmptyState(context);
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleMenuSelection('add_files'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No media files found',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Add files or scan folders to get started',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
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
              ElevatedButton.icon(
                onPressed: () => _handleMenuSelection('scan_folder'),
                icon: const Icon(Icons.folder_open),
                label: const Text('Scan Folder'),
              ),
            ],
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
