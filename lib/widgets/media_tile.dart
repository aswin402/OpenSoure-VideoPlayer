import 'dart:io';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/media_provider.dart';
import '../models/media_file.dart';
import 'media_tile_shimmer.dart';

class MediaTile extends StatefulWidget {
  final MediaFile file;
  final VoidCallback onTap;

  const MediaTile({super.key, required this.file, required this.onTap});

  // Helper actions used by grid tile popup
  static Future<void> showRenameDialog(
    BuildContext context,
    MediaFile file,
  ) async {
    final controller = TextEditingController(text: file.name);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'New name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final messenger = ScaffoldMessenger.of(context);
                final ok = await context.read<MediaProvider>().rename(
                  file,
                  newName,
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Renamed to $newName' : 'Rename failed'),
                  ),
                );
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  static Future<void> confirmDelete(
    BuildContext context,
    MediaFile file,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text(
          'Are you sure you want to delete "${file.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final ok = await context.read<MediaProvider>().delete(file);
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok ? 'Deleted' : 'Delete failed')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  State<MediaTile> createState() => _MediaTileState();
}

class _MediaTileState extends State<MediaTile> {
  bool _isHovered = false;

  void _showPropertiesDialog(BuildContext context, MediaFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _prop('Path', file.path),
            _prop('Size', file.formattedSize),
            _prop('Type', file.extension.toUpperCase()),
            _prop('Modified', file.formattedDate),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _prop(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isHovered
            ? [
                BoxShadow(
                  color: const Color(0x662196F3),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _isHovered ? 1.02 : 1.0,
        child: Card(
          color: theme.cardColor,
          elevation: _isHovered ? 6 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (hovering) {
              if (!mounted) return;
              setState(() => _isHovered = hovering);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail / Icon
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final aspect = w >= 240 ? 16 / 9 : (w >= 180 ? 4 / 3 : 1.0);
                    return AspectRatio(
                      aspectRatio: aspect,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (widget.file.thumbnailPath != null &&
                                widget.file.thumbnailPath!.isNotEmpty)
                              FutureBuilder<bool>(
                                future: File(
                                  widget.file.thumbnailPath!,
                                ).exists(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Consumer<ThemeProvider>(
                                      builder: (context, theme, _) =>
                                          ShimmerPlaceholder(
                                            startColor: theme.primaryColor,
                                            endColor: theme.secondaryColor,
                                            icon:
                                                widget.file.type ==
                                                    MediaType.video
                                                ? Icons.videocam_outlined
                                                : Icons.image_outlined,
                                          ),
                                    );
                                  }
                                  if (snapshot.data == true) {
                                    return Image.file(
                                      File(widget.file.thumbnailPath!),
                                      key: ValueKey(widget.file.thumbnailPath!),
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                      filterQuality: FilterQuality.medium,
                                      errorBuilder:
                                          (
                                            context,
                                            error,
                                            stackTrace,
                                          ) => Consumer<ThemeProvider>(
                                            builder: (context, theme, _) =>
                                                ShimmerPlaceholder(
                                                  startColor:
                                                      theme.primaryColor,
                                                  endColor:
                                                      theme.secondaryColor,
                                                  icon:
                                                      widget.file.type ==
                                                          MediaType.video
                                                      ? Icons.videocam_outlined
                                                      : Icons.image_outlined,
                                                ),
                                          ),
                                    );
                                  }
                                  return Consumer<ThemeProvider>(
                                    builder: (context, theme, _) =>
                                        ShimmerPlaceholder(
                                          startColor: theme.primaryColor,
                                          endColor: theme.secondaryColor,
                                          icon:
                                              widget.file.type ==
                                                  MediaType.video
                                              ? Icons.videocam_outlined
                                              : Icons.image_outlined,
                                        ),
                                  );
                                },
                              )
                            else
                              Consumer<ThemeProvider>(
                                builder: (context, theme, _) =>
                                    ShimmerPlaceholder(
                                      startColor: theme.primaryColor,
                                      endColor: theme.secondaryColor,
                                      icon: widget.file.type == MediaType.video
                                          ? Icons.videocam_outlined
                                          : Icons.image_outlined,
                                    ),
                              ),

                            // Video duration badge
                            if (widget.file.type == MediaType.video)
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: ValueListenableBuilder<Duration?>(
                                    valueListenable: widget.file.duration,
                                    builder: (context, duration, child) {
                                      final formattedDuration =
                                          widget.file.formattedDuration;
                                      return Visibility(
                                        visible: formattedDuration != '00:00',
                                        child: Text(
                                          formattedDuration,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize:
                                                MediaQuery.sizeOf(
                                                      context,
                                                    ).width >
                                                    1400
                                                ? 13
                                                : 12,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                            // Hover effect overlay
                            if (_isHovered)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.10),
                                  child: const Center(
                                    child: Icon(
                                      Icons.play_circle_outline,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                            // Hover actions menu (top-right)
                            if (_isHovered)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Material(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(8),
                                  child: PopupMenuButton<String>(
                                    tooltip: 'Actions',
                                    color: const Color(0xFF1E1E1E),
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'play':
                                          widget.onTap();
                                          break;
                                        case 'rename':
                                          MediaTile.showRenameDialog(
                                            context,
                                            widget.file,
                                          );
                                          break;
                                        case 'delete':
                                          MediaTile.confirmDelete(
                                            context,
                                            widget.file,
                                          );
                                          break;
                                        case 'properties':
                                          _showPropertiesDialog(
                                            context,
                                            widget.file,
                                          );
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'play',
                                        child: Row(
                                          children: [
                                            Icon(Icons.play_arrow),
                                            SizedBox(width: 8),
                                            Text('Play'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'rename',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.drive_file_rename_outline,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Rename'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline),
                                            SizedBox(width: 8),
                                            Text('Delete'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'properties',
                                        child: Row(
                                          children: [
                                            Icon(Icons.info),
                                            SizedBox(width: 8),
                                            Text('Properties'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // File info
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final maxH = c.maxHeight.isFinite
                          ? c.maxHeight
                          : double.infinity;
                      final tight = maxH < 88; // small cards -> compress footer
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // File name
                          Text(
                            widget.file.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                (theme.textTheme.titleSmall ??
                                        const TextStyle())
                                    .copyWith(
                                      fontWeight: FontWeight.w700,
                                      // Adaptive font size based on tile width
                                      fontSize: tight
                                          ? 12.5
                                          : (theme
                                                        .textTheme
                                                        .titleSmall
                                                        ?.fontSize ??
                                                    14) +
                                                (MediaQuery.sizeOf(
                                                          context,
                                                        ).width >
                                                        1400
                                                    ? 2
                                                    : MediaQuery.sizeOf(
                                                            context,
                                                          ).width >
                                                          900
                                                    ? 1
                                                    : 0),
                                      color: theme.brightness == Brightness.dark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                          ),
                          SizedBox(height: tight ? 4 : 8),

                          // Meta info row
                          FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: Row(
                              children: [
                                if (widget.file.type == MediaType.video) ...[
                                  const Icon(
                                    Icons.timelapse,
                                    size: 11,
                                    color: Color(0xFF9E9E9E),
                                  ),
                                  const SizedBox(width: 3),
                                  ValueListenableBuilder<Duration?>(
                                    valueListenable: widget.file.duration,
                                    builder: (context, duration, child) {
                                      final formattedDuration =
                                          widget.file.formattedDuration;
                                      return Visibility(
                                        visible: formattedDuration != '00:00',
                                        child: Text(
                                          formattedDuration,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontSize: tight ? 10 : null,
                                                color: const Color(0xFF9E9E9E),
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                const Icon(
                                  Icons.storage,
                                  size: 11,
                                  color: Color(0xFF9E9E9E),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  widget.file.formattedSize,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      (theme.textTheme.bodySmall ??
                                              const TextStyle())
                                          .copyWith(
                                            fontSize: tight
                                                ? 10
                                                : (theme
                                                              .textTheme
                                                              .bodySmall
                                                              ?.fontSize ??
                                                          12) +
                                                      (MediaQuery.sizeOf(
                                                                context,
                                                              ).width >
                                                              1400
                                                          ? 1.5
                                                          : MediaQuery.sizeOf(
                                                                  context,
                                                                ).width >
                                                                900
                                                          ? 1
                                                          : 0),
                                            color: const Color(0xFF9E9E9E),
                                          ),
                                ),
                                const SizedBox(width: 8),
                                // Extension badge
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: tight ? 6 : 8,
                                    vertical: tight ? 1.5 : 2,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2196F3),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(4),
                                    ),
                                  ),
                                  child: Text(
                                    widget.file.extension.isNotEmpty
                                        ? widget.file.extension
                                              .replaceFirst('.', '')
                                              .toUpperCase()
                                        : 'FILE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: tight ? 10 : 11,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),

                                // Continue-watching progress bar
                                if (widget.file.type == MediaType.video) ...[
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 80,
                                    child: Consumer<MediaProvider>(
                                      builder: (context, mediaProvider, _) {
                                        final saved = mediaProvider
                                            .getSavedPosition(widget.file);
                                        final total =
                                            widget.file.duration.value ??
                                            Duration.zero;
                                        final show =
                                            saved > Duration.zero &&
                                            total > Duration.zero;
                                        final progress = show
                                            ? saved.inMilliseconds /
                                                  total.inMilliseconds
                                            : 0.0;
                                        return Visibility(
                                          visible: show,
                                          child: LinearProgressIndicator(
                                            value: progress.clamp(0.0, 1.0),
                                            minHeight: 4,
                                            backgroundColor: Colors.white10,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.secondary,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
