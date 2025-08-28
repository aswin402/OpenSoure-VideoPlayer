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
  static bool? _ffmpegAvailable;

  static Future<bool> isFfmpegAvailable() async {
    if (_ffmpegAvailable != null) return _ffmpegAvailable!;
    try {
      // Try invoking ffmpeg to see if it is present on PATH
      final result = await Process.run('ffmpeg', ['-version']);
      _ffmpegAvailable = result.exitCode == 0;
    } catch (_) {
      _ffmpegAvailable = false;
    }
    return _ffmpegAvailable!;
  }

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

  // Rename a file within the same directory; returns new absolute path on success
  Future<String?> renameFile(String oldPath, String newName) async {
    try {
      final file = File(oldPath);
      if (!await file.exists()) return null;
      final dir = file.parent.path;
      final newPath = p.join(dir, newName);
      // If newName has no extension, keep the old one
      if (!newName.contains('.') && oldPath.contains('.')) {
        final ext = p.extension(oldPath);
        final withExt = p.join(dir, '$newName$ext');
        final renamed = await file.rename(withExt);
        return renamed.path;
      }
      final renamed = await file.rename(newPath);
      return renamed.path;
    } catch (e) {
      debugPrint('Rename failed for $oldPath -> $newName: $e');
      return null;
    }
  }

  // Delete a file; returns true if deleted
  Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Delete failed for $path: $e');
      return false;
    }
  }

  Future<Directory> getAppDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  Future<void> enrichMediaFile(
    MediaFile file, {
    bool forceThumbnail = false,
  }) async {
    if (file.type == MediaType.video) {
      await _populateVideoMeta(file, forceThumbnail: forceThumbnail);
    }
  }

  Future<void> _populateVideoMeta(
    MediaFile file, {
    bool forceThumbnail = false,
  }) async {
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

        // Wait for a non-zero duration with a reasonable timeout
        Duration probed = Duration.zero;
        try {
          probed = await player.stream.duration
              .firstWhere((d) => d != Duration.zero)
              .timeout(const Duration(seconds: 3));
        } catch (_) {
          // Fallback: small delay then read the latest emitted value if any
          try {
            await Future.delayed(const Duration(milliseconds: 300));
            final latest = await player.stream.duration.first.timeout(
              const Duration(milliseconds: 300),
              onTimeout: () => Duration.zero,
            );
            probed = latest;
          } catch (_) {}
        }

        file.duration.value = probed == Duration.zero ? null : probed;
      } catch (_) {
        file.duration.value = null;
      } finally {
        await player.dispose();
      }

      // Generate or reuse a cached thumbnail image
      try {
        // Ensure ffmpeg is on PATH; if not, skip generation gracefully
        if (!(await FileService.isFfmpegAvailable())) {
          debugPrint('Thumbnail generation skipped: ffmpeg not found on PATH');
          return;
        }

        final tempDir = await getTemporaryDirectory();
        final baseName = p.basenameWithoutExtension(file.path);
        final outPath = p.join(
          tempDir.path,
          'mxclone_thumbs',
          // Cache-bust on file changes using size + mtime
          '${baseName}_${file.size}_${file.lastModified.millisecondsSinceEpoch}.jpg',
        );
        final outDir = Directory(p.dirname(outPath));
        if (!await outDir.exists()) {
          await outDir.create(recursive: true);
        }

        // If a cached thumbnail already exists, reuse it unless forcing regeneration
        final cached = File(outPath);
        if (!forceThumbnail && await cached.exists()) {
          file.thumbnailPath = outPath;
        } else {
          // Pick a good preview frame:
          // - Prefer middle for long videos
          // - Otherwise try 2–5 seconds where available
          final dur = file.duration.value ?? Duration.zero;
          final totalMs = dur.inMilliseconds;

          List<int> timeCandidates;
          if (totalMs >= 10 * 1000) {
            // Long videos: middle, then 5s, 2s, then 0
            timeCandidates = [totalMs ~/ 2, 5000, 2000, 0];
          } else if (totalMs >= 5 * 1000) {
            // Medium: 3s, middle, 2s, 0
            timeCandidates = [3000, totalMs ~/ 2, 2000, 0];
          } else if (totalMs >= 2 * 1000) {
            // Short: 2s, middle, 0
            timeCandidates = [2000, totalMs ~/ 2, 0];
          } else if (totalMs > 0) {
            // Very short: middle, 0
            timeCandidates = [totalMs ~/ 2, 0];
          } else {
            // Unknown duration: try 2s then 0
            timeCandidates = [2000, 0];
          }

          String? generatedFinal;
          for (final t in timeCandidates) {
            try {
              // Try writing directly to our target path to avoid rename races
              final generated = await VideoThumbnail.thumbnailFile(
                video: file.path,
                thumbnailPath: outPath,
                imageFormat: ImageFormat.JPEG,
                quality: 85,
                timeMs: t,
                maxWidth: 1280,
                maxHeight: 1280,
              );
              if (generated != null && await File(generated).exists()) {
                generatedFinal = generated;
                break;
              }
            } catch (_) {
              // Fallback: generate in directory with random name
              try {
                final generated = await VideoThumbnail.thumbnailFile(
                  video: file.path,
                  thumbnailPath: outDir.path,
                  imageFormat: ImageFormat.JPEG,
                  quality: 85,
                  timeMs: t,
                  maxWidth: 1280,
                  maxHeight: 1280,
                );
                if (generated != null && await File(generated).exists()) {
                  generatedFinal = generated;
                  break;
                }
              } catch (_) {}
            }
          }

          if (generatedFinal != null) {
            try {
              if (generatedFinal != outPath) {
                await File(generatedFinal).rename(outPath);
                file.thumbnailPath = outPath;
              } else {
                file.thumbnailPath = outPath;
              }
            } catch (_) {
              // Fallback to original generated path if rename fails
              file.thumbnailPath = generatedFinal;
            }
          }
        }
      } catch (e) {
        // Ignore thumbnail errors
        debugPrint('Thumbnail generation error: $e');
      }
    } catch (e) {
      // Ignore meta errors per-file
    }
  }
}
