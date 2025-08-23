import 'dart:io';
import 'package:path/path.dart' as p;

class MediaFile {
  final String name;
  final String path;
  final String extension;
  final int size;
  final DateTime lastModified;
  final MediaType type;
  String? thumbnailPath;
  Duration? duration;

  MediaFile({
    required this.name,
    required this.path,
    required this.extension,
    required this.size,
    required this.lastModified,
    required this.type,
    this.thumbnailPath,
    this.duration,
  });

  factory MediaFile.fromFile(File file) {
    final fileName = p.basename(file.path);
    final fileExtension = p.extension(file.path).toLowerCase();

    try {
      final stat = file.statSync();
      return MediaFile(
        name: fileName,
        path: file.path,
        extension: fileExtension,
        size: stat.size,
        lastModified: stat.modified,
        type: _getMediaType(fileExtension),
      );
    } catch (e) {
      // If we can't get file stats, create with default values
      return MediaFile(
        name: fileName,
        path: file.path,
        extension: fileExtension,
        size: 0,
        lastModified: DateTime.now(),
        type: _getMediaType(fileExtension),
      );
    }
  }

  static MediaType _getMediaType(String extension) {
    const videoExtensions = [
      '.mp4',
      '.avi',
      '.mkv',
      '.mov',
      '.wmv',
      '.flv',
      '.webm',
      '.m4v',
      '.3gp',
      '.3g2',
      '.asf',
      '.divx',
      '.f4v',
      '.m2ts',
      '.mts',
      '.ogv',
      '.rm',
      '.rmvb',
      '.ts',
      '.vob',
      '.xvid',
    ];

    const audioExtensions = [
      '.mp3',
      '.wav',
      '.flac',
      '.aac',
      '.ogg',
      '.wma',
      '.m4a',
      '.opus',
      '.amr',
      '.ac3',
      '.dts',
      '.ape',
      '.mka',
    ];

    if (videoExtensions.contains(extension)) {
      return MediaType.video;
    } else if (audioExtensions.contains(extension)) {
      return MediaType.audio;
    } else {
      return MediaType.unknown;
    }
  }

  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  String get formattedDate {
    return '${lastModified.day}/${lastModified.month}/${lastModified.year}';
  }

  String get formattedDuration {
    final d = duration;
    if (d == null || d == Duration.zero) return '00:00';
    String two(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (hours > 0) {
      return '${two(hours)}:${two(minutes)}:${two(seconds)}';
    }
    return '${two(minutes)}:${two(seconds)}';
  }
}

enum MediaType { video, audio, unknown }
