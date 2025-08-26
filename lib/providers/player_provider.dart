import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/media_file.dart';
import '../services/settings_service.dart';

class PlayerProvider extends ChangeNotifier {
  late final Player _player;
  late final VideoController _videoController;
  final SettingsService _settingsService = SettingsService();

  MediaFile? _currentMedia;
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  double _brightness = 0.0;
  bool _showControls = true;
  bool _isFullscreen = false;
  RepeatMode _repeatMode = RepeatMode.none;
  bool _isMuted = false;
  double _previousVolume = 1.0;
  bool _isInitialized = false;
  Future<void>? _initializing;

  // Expose settings service for UI access
  SettingsService get settingsService => _settingsService;

  // Aspect ratio & fit
  BoxFit _videoFit = BoxFit.contain; // default
  // Predefined aspect ratios; null uses source aspect
  double? _aspectRatio; // null => auto

  // Getters
  Player get player => _player;
  VideoController get videoController => _videoController;
  bool get isInitialized => _isInitialized;
  MediaFile? get currentMedia => _currentMedia;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  double get playbackSpeed => _playbackSpeed;
  double get brightness => _brightness;
  bool get showControls => _showControls;
  bool get isFullscreen => _isFullscreen;
  RepeatMode get repeatMode => _repeatMode;
  bool get isMuted => _isMuted;

  // Video layout getters
  BoxFit get videoFit => _videoFit;
  double? get aspectRatio => _aspectRatio;

  double get progress => _duration.inMilliseconds > 0
      ? _position.inMilliseconds / _duration.inMilliseconds
      : 0.0;

  // Audio tracks management
  List<AudioTrack> _audioTracks = const [];
  AudioTrack? _selectedAudioTrack;
  List<AudioTrack> get audioTracks => _audioTracks;
  AudioTrack? get selectedAudioTrack => _selectedAudioTrack;

  String get positionText => _formatDuration(_position);
  String get durationText => _formatDuration(_duration);
  String get remainingText => _formatDuration(_duration - _position);

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_initializing != null) return await _initializing;

    _initializing = _doInitialize();
    try {
      await _initializing;
    } catch (e) {
      debugPrint('Player initialization failed: $e');
      _isInitialized = false;
      _initializing = null;
      rethrow;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _doInitialize() async {
    if (_isInitialized) return;

    await _settingsService.initialize();

    _player = Player();
    _videoController = VideoController(_player);
    _isInitialized = true;

    // Load settings
    _volume = _settingsService.volume;
    _playbackSpeed = _settingsService.playbackSpeed;
    _brightness = _settingsService.brightness;
    _repeatMode = _settingsService.repeatMode;

    // Set initial values
    await _player.setVolume(_volume * 100);
    await _player.setRate(_playbackSpeed);

    // Listen to player events
    _player.stream.playing.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    _player.stream.buffering.listen((buffering) {
      _isBuffering = buffering;
      notifyListeners();
    });

    _player.stream.position.listen((position) {
      _position = position;
      notifyListeners();

      // Save position periodically (every 5 seconds for better accuracy)
      if (_currentMedia != null &&
          position.inSeconds % 5 == 0 &&
          position.inSeconds > 0) {
        debugPrint(
          'Periodic save: ${position.inSeconds}s for ${_currentMedia!.name}',
        );
        _settingsService.setLastPlayedPosition(_currentMedia!.path, position);
      }
    });

    _player.stream.duration.listen((duration) {
      _duration = duration;
      notifyListeners();
    });

    // Track changes: update available audio tracks and selection
    _player.stream.tracks.listen((tracks) {
      _audioTracks = tracks.audio; // List<AudioTrack>
      notifyListeners();
    });
    _player.stream.track.listen((track) {
      _selectedAudioTrack = track.audio; // AudioTrack?
      notifyListeners();
    });

    _player.stream.completed.listen((completed) {
      if (completed) {
        _onPlaybackCompleted();
      }
    });
  }

  Future<void> openMedia(MediaFile media, {bool resume = true}) async {
    debugPrint('openMedia called: ${media.name}, resume: $resume');
    _currentMedia = media;
    _isBuffering = true;
    notifyListeners();

    try {
      debugPrint('Opening media file: ${media.path}');
      await _player.open(Media(media.path));
      debugPrint('Media opened successfully');

      if (resume) {
        final savedPosition = getLastSavedPosition(media);
        debugPrint(
          'Resume requested, saved position: ${savedPosition.inSeconds}s',
        );
        if (savedPosition.inSeconds > 0) {
          debugPrint('Seeking to position: ${savedPosition.inSeconds}s');
          await _player.seek(savedPosition);
          debugPrint('Seek completed');
        }
      } else {
        debugPrint('Resume not requested, starting from beginning');
      }

      // Audio tracks will be populated via stream listeners after opening.

      notifyListeners();
    } catch (e) {
      debugPrint('Error opening media: $e');
      _isBuffering = false;
      rethrow;
    } finally {
      _isBuffering = false;
    }
  }

  // Expose last saved position for UI to decide resume behavior
  Duration getLastSavedPosition(MediaFile media) {
    final savedPosition = _settingsService.getLastPlayedPosition(media.path);
    debugPrint(
      'Getting saved position for ${media.name}: ${savedPosition.inSeconds}s',
    );
    return savedPosition;
  }

  // Save current position manually
  Future<void> saveCurrentPosition() async {
    if (_currentMedia != null && _position.inSeconds > 0) {
      await _settingsService.setLastPlayedPosition(
        _currentMedia!.path,
        _position,
      );
    }
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
    // Save position when pausing
    if (_currentMedia != null) {
      debugPrint(
        'Saving position on pause: ${_position.inSeconds}s for ${_currentMedia!.name}',
      );
      await _settingsService.setLastPlayedPosition(
        _currentMedia!.path,
        _position,
      );
    }
  }

  Future<void> playOrPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _position = Duration.zero;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> seekRelative(Duration offset) async {
    final newPosition = _position + offset;
    if (newPosition >= Duration.zero && newPosition <= _duration) {
      await seek(newPosition);
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _player.setVolume(_volume * 100);
    await _settingsService.setVolume(_volume);

    if (_volume > 0 && _isMuted) {
      _isMuted = false;
    }

    notifyListeners();
  }

  Future<void> toggleMute() async {
    if (_isMuted) {
      _isMuted = false;
      await setVolume(_previousVolume);
    } else {
      _isMuted = true;
      _previousVolume = _volume;
      await setVolume(0.0);
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed.clamp(0.25, 3.0);
    await _player.setRate(_playbackSpeed);
    await _settingsService.setPlaybackSpeed(_playbackSpeed);
    notifyListeners();
  }

  void setBrightness(double brightness) {
    _brightness = brightness.clamp(-1.0, 1.0);
    _settingsService.setBrightness(_brightness);
    notifyListeners();
  }

  void setRepeatMode(RepeatMode mode) {
    _repeatMode = mode;
    _settingsService.setRepeatMode(mode);
    notifyListeners();
  }

  // Select audio track
  Future<void> setAudioTrack(AudioTrack track) async {
    try {
      await _player.setAudioTrack(track);
      _selectedAudioTrack = track;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to set audio track: $e');
    }
  }

  void toggleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.none:
        setRepeatMode(RepeatMode.one);
        break;
      case RepeatMode.one:
        setRepeatMode(RepeatMode.all);
        break;
      case RepeatMode.all:
        setRepeatMode(RepeatMode.none);
        break;
    }
  }

  void setShowControls(bool show) {
    _showControls = show;
    notifyListeners();
  }

  void toggleControls() {
    setShowControls(!_showControls);
  }

  void setFullscreen(bool fullscreen) {
    _isFullscreen = fullscreen;
    notifyListeners();
  }

  void toggleFullscreen() {
    setFullscreen(!_isFullscreen);
  }

  // Aspect ratio & fit controls
  void cycleAspectRatio() {
    // Order: auto(null) -> 16:9 -> 4:3 -> 1:1 -> auto
    if (_aspectRatio == null) {
      _aspectRatio = 16 / 9;
    } else if ((_aspectRatio! - 16 / 9).abs() < 0.001) {
      _aspectRatio = 4 / 3;
    } else if ((_aspectRatio! - 4 / 3).abs() < 0.001) {
      _aspectRatio = 1.0;
    } else {
      _aspectRatio = null; // back to auto (source)
    }
    notifyListeners();
  }

  void cycleFit() {
    // Order: contain -> cover -> fill -> contain
    if (_videoFit == BoxFit.contain) {
      _videoFit = BoxFit.cover;
    } else if (_videoFit == BoxFit.cover) {
      _videoFit = BoxFit.fill;
    } else {
      _videoFit = BoxFit.contain;
    }
    notifyListeners();
  }

  void _onPlaybackCompleted() {
    // Clear saved position when video completes (so it doesn't ask to resume next time)
    if (_currentMedia != null) {
      _settingsService.setLastPlayedPosition(
        _currentMedia!.path,
        Duration.zero,
      );
    }

    switch (_repeatMode) {
      case RepeatMode.one:
        _player.seek(Duration.zero);
        _player.play();
        break;
      case RepeatMode.all:
        // This would be handled by MediaProvider to play next file
        break;
      case RepeatMode.none:
        // Do nothing, playback stops
        break;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    // Save current position before disposing
    if (_currentMedia != null && _position.inSeconds > 0) {
      _settingsService.setLastPlayedPosition(_currentMedia!.path, _position);
    }

    // Dispose safely only if initialized
    if (_isInitialized) {
      _player.dispose();
    }
    super.dispose();
  }
}
