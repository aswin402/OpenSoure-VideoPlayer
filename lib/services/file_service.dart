import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/foundation.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
import '../models/media_file.dart';

class FileService {
  static const List<String> supportedExtensions = [
    // Video formats
    'mp4', 'avi', 'mkv', 'mov', 'wmv', 'flv', 'webm', 'm4v',
    '3gp', '3g2', 'asf', 'divx', 'f4v', 'm2ts', 'mts', 'ogv',
    'rm', 'rmvb', 'ts', 'vob', 'xvid',
    // Audio formats
    'mp3', 'wav', 'flac', 'aac', 'ogg', 'wma', 'm4a', 'opus',
    'amr', 'ac3', 'dts', 'ape', 'mka',
  ];

  Future<List<MediaFile>> scanCustomFormats() async {
    const videoExtensions = {
      '3gp',
      'avi',
      'flv',
      'h264',
      'm4v',
      'mkv',
      'mov',
      'mp4',
      'mpg',
      'mpeg',
      'rm',
      'swf',
      'vob',
      'webm',
      'wmv',
      'm2ts',
      'ts',
      'mts',
      'm2t',
      'divx',
      'f4v',
      'h265',
      'hevc',
      'ogv',
      'vp8',
      'vp9',
      'asf',
      'amv',
      'drc',
      'gifv',
      'm4p',
      'mxf',
      'nsv',
      'roq',
      'svi',
      'yuv',
    };
    const audioExtensions = {
      'aac',
      'aiff',
      'ape',
      'dsd',
      'dts',
      'flac',
      'm4a',
      'mid',
      'mp3',
      'oga',
      'ogg',
      'opus',
      'wav',
      'wma',
      'wv',
      'ac3',
      'amr',
      'au',
      'mka',
      'ra',
      'rmi',
      'spx',
      'tak',
      'tta',
      'webm',
    };

    final files = await scanDirectory(
      (await getDownloadsDirectory())?.path ?? '/',
    );
    return files.where((file) {
      final ext = file.extension.toLowerCase();
      return videoExtensions.contains(ext) || audioExtensions.contains(ext);
    }).toList();
  }

  Future<List<MediaFile>> scanDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    final List<MediaFile> mediaFiles = [];

    if (!await directory.exists()) {
      return mediaFiles;
    }

    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final extension = entity.path.split('.').last.toLowerCase();
          if (supportedExtensions.contains(extension)) {
            try {
              final mediaFile = MediaFile.fromFile(entity);
              mediaFiles.add(mediaFile);
            } catch (e) {
              // Skip files that can't be processed
              debugPrint('Error processing file ${entity.path}: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning directory $directoryPath: $e');
    }

    return mediaFiles;
  }

  Future<List<MediaFile>> getCommonMediaDirectories() async {
    final List<MediaFile> allFiles = [];

    try {
      // Get common directories
      final homeDir = Platform.environment['HOME'] ?? '/home';
      final commonDirs = [
        '$homeDir/Videos',
        '$homeDir/Music',
        '$homeDir/Downloads',
        '$homeDir/Documents',
        '/media',
        '/mnt',
      ];

      for (final dirPath in commonDirs) {
        final files = await scanDirectory(dirPath);
        allFiles.addAll(files);
      }
    } catch (e) {
      debugPrint('Error getting common media directories: $e');
    }

    return allFiles;
  }

  Future<List<MediaFile>> pickFiles() async {
    try {
      if (!kIsWeb &&
          (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
        // Use file_selector on desktop for better portal integration
        final typeGroups = [
          fs.XTypeGroup(label: 'Media', extensions: supportedExtensions),
        ];
        final files = await fs.openFiles(acceptedTypeGroups: typeGroups);
        final media = files
            .map((xfile) => MediaFile.fromFile(File(xfile.path)))
            .toList();
        // Defer metadata enrichment to caller (provider) to avoid blocking UI here
        return media;
      } else {
        // Fallback to file_picker
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: supportedExtensions,
          allowMultiple: true,
        );
        if (result != null) {
          final media = result.files
              .where((file) => file.path != null)
              .map((file) => MediaFile.fromFile(File(file.path!)))
              .toList();
          // Defer metadata enrichment to caller
          return media;
        }
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    }

    return [];
  }

  Future<String?> pickDirectory() async {
    try {
      if (!kIsWeb &&
          (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
        final directory = await fs.getDirectoryPath();
        return directory;
      } else {
        final result = await FilePicker.platform.getDirectoryPath();
        return result;
      }
    } catch (e) {
      debugPrint('Error picking directory: $e');
      return null;
    }
  }

  Future<List<MediaFile>> getRecentFiles() async {
    // This would typically load from shared preferences or a database
    // For now, return empty list
    return [];
  }

  bool isMediaFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return supportedExtensions.contains(extension);
  }

  Future<Directory> getAppDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  Future<void> enrichMediaFile(MediaFile file) async {
    if (file.type == MediaType.video) {
      await _populateVideoMeta(file);
    }
  }

  Future<void> _populateVideoMeta(MediaFile file) async {
    try {
      // Ensure media_kit is initialized
      MediaKit.ensureInitialized();

      // Create a temporary player to probe duration
      final player = Player();
      try {
        await player.open(
          Media(file.path),
          play: false,
        ); // open without playing
        final ms = await player.stream.position.first.timeout(
          const Duration(milliseconds: 200),
          onTimeout: () => Duration.zero,
        );
        // If position is zero quickly, probe duration via state.duration if available
        final duration = await player.stream.duration.first.timeout(
          const Duration(milliseconds: 500),
          onTimeout: () => Duration.zero,
        );
        file.duration = duration == Duration.zero ? ms : duration;
      } catch (_) {
        file.duration = null;
      } finally {
        await player.dispose();
      }

      // Generate or reuse a cached thumbnail image
      try {
        final tempDir = await getTemporaryDirectory();
        final outPath = p.join(
          tempDir.path,
          'mxclone_thumbs',
          '${p.basenameWithoutExtension(file.path)}.jpg',
        );
        final outDir = Directory(p.dirname(outPath));
        if (!await outDir.exists()) {
          await outDir.create(recursive: true);
        }

        // If a cached thumbnail already exists, reuse it
        final cached = File(outPath);
        if (await cached.exists()) {
          file.thumbnailPath = outPath;
        } else {
          // Choose middle frame when duration is known; otherwise first frame
          final midMs =
              (file.duration != null && file.duration != Duration.zero)
              ? (file.duration!.inMilliseconds ~/ 2)
              : 0;
          final generated = await VideoThumbnail.thumbnailFile(
            video: file.path,
            thumbnailPath: outDir.path, // generate into directory
            imageFormat: ImageFormat.JPEG,
            quality: 70,
            timeMs: midMs,
          );
          if (generated != null && await File(generated).exists()) {
            try {
              await File(generated).rename(outPath);
              file.thumbnailPath = outPath;
            } catch (_) {
              // Fallback to original generated path if rename fails
              file.thumbnailPath = generated;
            }
          }
        }
      } catch (e) {
        // Ignore thumbnail errors
      }
    } catch (e) {
      // Ignore meta errors per-file
    }
  }
}
