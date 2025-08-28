import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/media_provider.dart';
import '../providers/theme_provider.dart';
import '../models/media_file.dart';

class FilterBar extends StatelessWidget {
  final MediaType? selectedType;
  final Function(MediaType)? onTypeChanged;
  final SortBy? sortBy;
  final bool? sortAscending;
  final Function(SortBy, bool)? onSortChanged;

  const FilterBar({
    super.key,
    this.selectedType,
    this.onTypeChanged,
    this.sortBy,
    this.sortAscending,
    this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, mediaProvider, child) {
        final currentType = selectedType ?? mediaProvider.filterType;
        final currentSortBy = sortBy ?? mediaProvider.sortBy;
        final currentSortAscending =
            sortAscending ?? mediaProvider.sortAscending;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Media type filters
              _buildFilterChip(
                context,
                label: 'All',
                icon: Icons.all_inclusive_rounded,
                isSelected: currentType == MediaType.unknown,
                onTap: () =>
                    _handleTypeChange(MediaType.unknown, mediaProvider),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context,
                label: 'Videos',
                icon: Icons.video_library_rounded,
                isSelected: currentType == MediaType.video,
                onTap: () => _handleTypeChange(MediaType.video, mediaProvider),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                context,
                label: 'Audio',
                icon: Icons.audiotrack_rounded,
                isSelected: currentType == MediaType.audio,
                onTap: () => _handleTypeChange(MediaType.audio, mediaProvider),
              ),
              const SizedBox(width: 16),

              // Divider
              Container(
                height: 32,
                width: 1,
                color: Colors.white.withOpacity(0.2),
              ),
              const SizedBox(width: 16),

              // Sorting dropdown and direction
              _buildSortDropdown(
                context,
                currentSortBy,
                currentSortAscending,
                mediaProvider,
              ),
              const SizedBox(width: 8),
              _buildSortDirectionButton(
                context,
                currentSortAscending,
                currentSortBy,
                mediaProvider,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        themeProvider.primaryColor,
                        themeProvider.secondaryColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.2),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.75),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.75),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortDropdown(
    BuildContext context,
    SortBy currentSortBy,
    bool currentSortAscending,
    MediaProvider mediaProvider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SortBy>(
          value: currentSortBy,
          dropdownColor: const Color(0xFF1E1E1E),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          iconEnabledColor: Theme.of(context).primaryColor,
          onChanged: (SortBy? value) {
            if (value != null) {
              _handleSortChange(value, currentSortAscending, mediaProvider);
            }
          },
          items: const [
            DropdownMenuItem(
              value: SortBy.name,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sort_by_alpha_rounded, size: 16),
                  SizedBox(width: 8),
                  Text('Name'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: SortBy.size,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.data_usage_rounded, size: 16),
                  SizedBox(width: 8),
                  Text('Size'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: SortBy.date,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time_rounded, size: 16),
                  SizedBox(width: 8),
                  Text('Date'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: SortBy.duration,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_rounded, size: 16),
                  SizedBox(width: 8),
                  Text('Duration'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: SortBy.type,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category_rounded, size: 16),
                  SizedBox(width: 8),
                  Text('Type'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortDirectionButton(
    BuildContext context,
    bool currentSortAscending,
    SortBy currentSortBy,
    MediaProvider mediaProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: IconButton(
        icon: Icon(
          currentSortAscending
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          color: Colors.white,
          size: 22,
        ),
        onPressed: () => _handleSortChange(
          currentSortBy,
          !currentSortAscending,
          mediaProvider,
        ),
        tooltip: currentSortAscending ? 'Sort Descending' : 'Sort Ascending',
      ),
    );
  }

  void _handleTypeChange(MediaType type, MediaProvider mediaProvider) {
    if (onTypeChanged != null) {
      onTypeChanged!(type);
    } else {
      mediaProvider.setFilterType(type);
    }
  }

  void _handleSortChange(
    SortBy sortBy,
    bool ascending,
    MediaProvider mediaProvider,
  ) {
    if (onSortChanged != null) {
      onSortChanged!(sortBy, ascending);
    } else {
      mediaProvider.setSorting(sortBy, ascending);
    }
  }
}
