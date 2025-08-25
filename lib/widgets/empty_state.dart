import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget? customAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
    this.customAction,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        themeProvider.primaryColor.withOpacity(0.2),
                        themeProvider.secondaryColor.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 60,
                    color: themeProvider.primaryColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (customAction != null)
                  customAction!
                else if (actionText != null && onAction != null)
                  ElevatedButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(actionText!),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MediaEmptyState extends StatelessWidget {
  final VoidCallback? onAddFiles;

  const MediaEmptyState({super.key, this.onAddFiles});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.video_library_outlined,
      title: 'No Media Files',
      subtitle:
          'Add some videos or audio files to get started.\nYou can browse and organize your media collection here.',
      actionText: 'Add Files',
      onAction: onAddFiles,
    );
  }
}

class PlaylistEmptyState extends StatelessWidget {
  final VoidCallback? onCreatePlaylist;

  const PlaylistEmptyState({super.key, this.onCreatePlaylist});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.playlist_play_outlined,
      title: 'No Playlists',
      subtitle:
          'Create playlists to organize your favorite media files.\nGroup related content for easy access.',
      actionText: 'Create Playlist',
      onAction: onCreatePlaylist,
    );
  }
}

class SearchEmptyState extends StatelessWidget {
  final String searchQuery;

  const SearchEmptyState({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: 'No Results Found',
      subtitle:
          'No media files match "$searchQuery".\nTry adjusting your search terms or filters.',
    );
  }
}

class FilterEmptyState extends StatelessWidget {
  final String filterType;

  const FilterEmptyState({super.key, required this.filterType});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.filter_list_off_rounded,
      title: 'No $filterType Files',
      subtitle:
          'No $filterType files found in your library.\nTry changing the filter or add more files.',
    );
  }
}
