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
          const Text('Sort by:'),
          const SizedBox(width: 8),
          Consumer<MediaProvider>(
            builder: (context, mediaProvider, child) {
              return DropdownButton<SortBy>(
                value: mediaProvider.sortBy,
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
              );
            },
          ),
          const SizedBox(width: 8),
          Consumer<MediaProvider>(
            builder: (context, mediaProvider, child) {
              return IconButton(
                icon: Icon(
                  mediaProvider.sortAscending
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                ),
                onPressed: () {
                  mediaProvider.setSorting(
                    mediaProvider.sortBy,
                    !mediaProvider.sortAscending,
                  );
                },
              );
            },
          ),
          const Spacer(),
          Consumer<MediaProvider>(
            builder: (context, mediaProvider, child) {
              return Text(
                '${mediaProvider.filteredFiles.length} files',
                style: Theme.of(context).textTheme.bodySmall,
              );
            },
          ),
        ],
      ),
    );
  }
}
