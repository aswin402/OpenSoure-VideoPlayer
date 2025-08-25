# MXClone - Modern Media Player

A beautiful, modern media player built with Flutter that provides an intuitive interface for managing and playing your video and audio files.

## Features

### 🎥 Media Management
- **Smart Library**: Automatically organize your media files with intelligent categorization
- **File Browser**: Browse and add files from your local system
- **Folder Scanning**: Bulk import media files by scanning entire directories
- **Search & Filter**: Powerful search functionality with type-based filtering (Video/Audio/All)
- **Multiple Views**: Switch between grid and list views for optimal browsing

### 🎨 Beautiful UI/UX
- **Modern Design**: Clean, gradient-based interface with smooth animations
- **9 Theme Presets**: Choose from beautiful color schemes:
  - Oceanic Calm (Blue gradient)
  - Serene Twilight (Purple gradient)
  - Deep Space (Dark blue-teal)
  - Mango Passion (Orange-red)
  - Sunset Blaze (Pink-red)
  - Neon Glow (Pink-orange)
  - Lush Meadow (Teal-green)
  - Digital Mint (Dark teal-green)
  - Gentle Ocean (Teal-yellow)
- **Theme Modes**: System, Light, and Dark mode support
- **Responsive Layout**: Optimized for desktop with sidebar navigation
- **Hover Effects**: Interactive elements with smooth hover animations

### 🎵 Advanced Playback
- **Full-Featured Player**: Complete media playback with all essential controls
- **Progress Control**: Seek to any position with visual progress indication
- **Volume Control**: Gesture-based volume adjustment with visual feedback
- **Brightness Control**: Adjust video brightness with gesture controls
- **Playback Speed**: Variable speed control (0.25x to 3.0x)
- **Repeat Modes**: None, Single, and All repeat options
- **Resume Playback**: Option to resume from last position
- **Hardware Acceleration**: GPU-accelerated video decoding support

### 📱 Smart Features
- **Auto Play**: Automatically play next file in queue
- **Thumbnail Generation**: Automatic thumbnail creation for video files
- **Duration Display**: Show file duration and current position
- **File Information**: Display file size, date, and format details
- **Recent Files**: Keep track of recently played media
- **Playlist Support**: Create and manage custom playlists

### ⚙️ Comprehensive Settings
- **Appearance Settings**: Visual theme selector with live preview
- **Playback Settings**: Configure auto-play, repeat mode, and speed
- **Video Settings**: Brightness and display options
- **Audio Settings**: Volume and audio-specific configurations
- **General Settings**: Clear recent files, reset settings

## Screenshots

### Main Interface
- **Library View**: Grid and list views with beautiful media tiles
- **Search & Filter**: Real-time search with type-based filtering
- **Empty States**: Helpful guidance when no content is available

### Player Interface
- **Full-Screen Player**: Immersive playback experience
- **Control Overlay**: Intuitive controls with gesture support
- **Progress Bar**: Visual progress with time indicators

### Settings
- **Theme Selection**: Visual theme picker with live preview
- **Organized Sections**: Categorized settings for easy navigation

## Technical Features

### Architecture
- **Provider Pattern**: State management using Flutter Provider
- **Modular Design**: Well-organized code structure with separation of concerns
- **Responsive UI**: Adaptive layouts for different screen sizes

### Performance
- **Efficient Rendering**: Optimized widget rebuilding and animations
- **Memory Management**: Proper disposal of resources and controllers
- **Smooth Animations**: 60fps animations with proper curve timing

### File Support
- **Video Formats**: MP4, AVI, MKV, MOV, WMV, and more
- **Audio Formats**: MP3, WAV, FLAC, AAC, OGG, and more
- **Metadata Reading**: Extract duration, size, and format information

## Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Desktop platform support enabled

### Installation
1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd mxclone
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run -d linux  # For Linux
   flutter run -d windows  # For Windows
   flutter run -d macos  # For macOS
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── media_file.dart      # Media file model
│   └── playlist.dart        # Playlist model
├── providers/               # State management
│   ├── media_provider.dart  # Media library state
│   ├── player_provider.dart # Player state
│   └── theme_provider.dart  # Theme state
├── screens/                 # App screens
│   ├── main_layout_screen.dart
│   ├── player_screen.dart
│   └── settings_screen.dart
├── services/                # Business logic
│   ├── media_service.dart   # Media file operations
│   ├── player_service.dart  # Playback control
│   └── settings_service.dart # Settings persistence
└── widgets/                 # Reusable UI components
    ├── media_tile.dart      # Media file display
    ├── player_controls.dart # Playback controls
    ├── theme_selector.dart  # Theme selection
    └── empty_state.dart     # Empty state displays
```

## Key Components

### Media Management
- **MediaProvider**: Manages media library state and operations
- **MediaService**: Handles file operations and metadata extraction
- **MediaTile**: Beautiful display component for media files

### Player System
- **PlayerProvider**: Manages playback state and controls
- **PlayerService**: Handles actual media playback
- **PlayerControls**: Interactive playback control interface

### Theme System
- **ThemeProvider**: Manages theme state and persistence
- **ThemeSelector**: Visual theme selection interface
- **9 Preset Themes**: Carefully crafted color schemes

### UI Components
- **EmptyState**: Contextual empty state displays
- **SearchBar**: Animated search input with focus effects
- **FilterBar**: Media type filtering with visual indicators

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Material Design for design inspiration
- Contributors and testers who helped improve the app

---

**MXClone** - Experience media playback like never before! 🎬✨