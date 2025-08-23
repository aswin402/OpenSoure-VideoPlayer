import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/media_file.dart';
import 'media_tile.dart';

class MediaGrid extends StatelessWidget {
  final List<MediaFile> files;
  final Function(MediaFile) onFileTap;

  const MediaGrid({super.key, required this.files, required this.onFileTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MasonryGridView.count(
        crossAxisCount: _getCrossAxisCount(context),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        itemCount: files.length,
        itemBuilder: (context, index) {
          return MediaTile(
            file: files[index],
            onTap: () => onFileTap(files[index]),
          );
        },
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 6;
    if (width > 800) return 4;
    if (width > 600) return 3;
    return 2;
  }
}
