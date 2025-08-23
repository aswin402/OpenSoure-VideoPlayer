import 'media_file.dart';

class Playlist {
  final String id;
  String name;
  // Name changed from final to mutable
  final List<MediaFile> files;
  final DateTime createdAt;
  DateTime lastModified;

  Playlist({
    required this.id,
    required this.name,
    required this.files,
    required this.createdAt,
    required this.lastModified,
  });

  factory Playlist.create(String name) {
    final now = DateTime.now();
    return Playlist(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      files: [],
      createdAt: now,
      lastModified: now,
    );
  }

  void addFile(MediaFile file) {
    if (!files.any((f) => f.path == file.path)) {
      files.add(file);
      lastModified = DateTime.now();
    }
  }

  void removeFile(MediaFile file) {
    files.removeWhere((f) => f.path == file.path);
    lastModified = DateTime.now();
  }
  
  void dispose() {
    // Clean up any resources
  }

  Duration get totalDuration {
    // This would need to be calculated based on actual file durations
    // For now, return zero
    return Duration.zero;
  }

  String get formattedDuration {
    final duration = totalDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'files': files.map((f) => f.path).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory Playlist.fromJson(
    Map<String, dynamic> json,
    List<MediaFile> allFiles,
  ) {
    final filePaths = List<String>.from(json['files']);
    final playlistFiles = allFiles
        .where((f) => filePaths.contains(f.path))
        .toList();

    return Playlist(
      id: json['id'],
      name: json['name'],
      files: playlistFiles,
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: DateTime.parse(json['lastModified']),
    );
  }
}
