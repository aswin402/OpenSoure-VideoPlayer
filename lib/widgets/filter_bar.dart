import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/media_provider.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Consumer<MediaProvider>(
            builder: (context, mediaProvider, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF2196F3).withOpacity(0.4),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<SortBy>(
                    dropdownColor: const Color(0xFF1E1E1E),
                    value: mediaProvider.sortBy,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                    iconEnabledColor: const Color(0xFF2196F3),
                    onChanged: (SortBy? value) {
                      if (value != null) {
                        mediaProvider.setSorting(
                          value,
                          mediaProvider.sortAscending,
                        );
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: SortBy.name, child: Text('Name')),
                      DropdownMenuItem(value: SortBy.size, child: Text('Size')),
                      DropdownMenuItem(value: SortBy.date, child: Text('Date')),
                      DropdownMenuItem(value: SortBy.type, child: Text('Type')),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Consumer<MediaProvider>(
            builder: (context, mediaProvider, child) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF2196F3).withOpacity(0.4),
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    mediaProvider.sortAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: const Color(0xFF2196F3),
                    size: 18,
                  ),
                  onPressed: () {
                    mediaProvider.setSorting(
                      mediaProvider.sortBy,
                      !mediaProvider.sortAscending,
                    );
                  },
                ),
              );
            },
          ),
          const Spacer(),
          Consumer<MediaProvider>(
            builder: (context, mediaProvider, child) {
              return Text(
                '${mediaProvider.filteredFiles.length} files',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFFB0BEC5)),
              );
            },
          ),
        ],
      ),
    );
  }
}
