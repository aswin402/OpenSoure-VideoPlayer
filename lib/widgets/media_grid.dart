import 'package:flutter/material.dart';
import '../models/media_file.dart';
import 'media_tile.dart';

class MediaGrid extends StatelessWidget {
  final List<MediaFile> files;
  final Function(MediaFile) onFileTap;

  const MediaGrid({super.key, required this.files, required this.onFileTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          // Responsive breakpoints for grid density
          double maxExtent;
          double spacing;
          if (width >= 1600) {
            maxExtent = 360;
            spacing = 16;
          } else if (width >= 1200) {
            maxExtent = 320;
            spacing = 14;
          } else if (width >= 900) {
            maxExtent = 280;
            spacing = 12;
          } else if (width >= 600) {
            maxExtent = 240;
            spacing = 10;
          } else {
            maxExtent = 200;
            spacing = 8;
          }

          final columns = (width / maxExtent).floor().clamp(1, 8);
          final actualTileWidth = (width - spacing * (columns - 1)) / columns;

          // Match MediaTile's thumbnail aspect to avoid overflow
          final thumbAspect = actualTileWidth >= 240
              ? 16 / 9
              : (actualTileWidth >= 180 ? 4 / 3 : 1.0);
          final thumbHeight = actualTileWidth / thumbAspect;

          // Footer height padded to ensure no vertical overflow
          // Add generous safety and scale with text size to prevent yellow stripes.
          final textScale = MediaQuery.textScaleFactorOf(context);
          final textExtra = (textScale - 1.0).clamp(0.0, 1.5) * 36.0;
          const baseSafety = 24.0; // extra headroom to avoid overflow
          final estimatedFooterHeight =
              (actualTileWidth < 200
                  ? 108.0
                  : actualTileWidth < 240
                  ? 122.0
                  : actualTileWidth < 300
                  ? 134.0
                  : 146.0) +
              textExtra +
              baseSafety;

          final childAspectRatio =
              actualTileWidth / (thumbHeight + estimatedFooterHeight);

          return GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: maxExtent,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 220 + (index % columns) * 60),
                builder: (context, opacity, child) =>
                    Opacity(opacity: opacity, child: child),
                child: MediaTile(file: file, onTap: () => onFileTap(file)),
              );
            },
          );
        },
      ),
    );
  }
}
