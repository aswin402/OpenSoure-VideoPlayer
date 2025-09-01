import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'providers/media_provider.dart';
import 'providers/player_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_layout_screen.dart';
import 'screens/player_screen.dart';
import 'screens/equalizer_screen.dart';
import 'services/thumbnail_cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager
  await windowManager.ensureInitialized();

  // Window configuration for 1366×768 screen
  const windowOptions = WindowOptions(
    size: Size(1100, 700), // Optimized for 1366×768 screen
    minimumSize: Size(1000, 800), // Minimum resize limit
    maximumSize: Size(1600, 1000), // Maximum resize limit
    center: true,
    backgroundColor: Colors.black,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    windowButtonVisibility: true,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    // Show the window
    await windowManager.show();
    await windowManager.focus();

    // Uncomment the line below to start in fullscreen mode
    // await windowManager.setFullScreen(true);
  });

  // Enforce size constraints after window is shown (for better platform compatibility)
  await windowManager.setMinimumSize(const Size(1000, 800));
  await windowManager.setMaximumSize(const Size(1600, 1000));

  // Debug: Print current window size constraints
  debugPrint('Window minimum size set to: 1000x800');
  debugPrint('Window maximum size set to: 1600x1000');

  // Ensure media_kit is ready (required for playback)
  MediaKit.ensureInitialized();

  // Initialize thumbnail cache service
  await ThumbnailCacheService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final provider = MediaProvider();
            // Initialize asynchronously without blocking UI
            provider.initializeAsync();
            return provider;
          },
        ),
        // PlayerProvider available app-wide
        ChangeNotifierProvider(
          create: (_) {
            final provider = PlayerProvider();
            provider.initializeAsync();
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = ThemeProvider();
            provider.initializeAsync();
            return provider;
          },
        ),
      ],
      child: const MxCloneApp(),
    ),
  );
}

class MxCloneApp extends StatefulWidget {
  static const appName = 'MX Clone';
  const MxCloneApp({super.key});

  @override
  State<MxCloneApp> createState() => _MxCloneAppState();
}

class _MxCloneAppState extends State<MxCloneApp> with WindowListener {
  Timer? _sizeCheckTimer;
  bool _isResizing = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);

    // Reduced frequency size checking - only when needed
    _sizeCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isResizing) {
        _enforceWindowSize();
      }
    });
  }

  @override
  void dispose() {
    _sizeCheckTimer?.cancel();
    windowManager.removeListener(this);
    super.dispose();
  }

  void _enforceWindowSize() async {
    if (_isResizing) return;
    _isResizing = true;

    try {
      final size = await windowManager.getSize();
      const minWidth = 1000.0;
      const minHeight = 800.0;
      const maxWidth = 1600.0;
      const maxHeight = 1000.0;

      bool needsResize = false;
      double newWidth = size.width;
      double newHeight = size.height;

      if (size.width < minWidth) {
        newWidth = minWidth;
        needsResize = true;
      } else if (size.width > maxWidth) {
        newWidth = maxWidth;
        needsResize = true;
      }

      if (size.height < minHeight) {
        newHeight = minHeight;
        needsResize = true;
      } else if (size.height > maxHeight) {
        newHeight = maxHeight;
        needsResize = true;
      }

      if (needsResize) {
        await windowManager.setSize(Size(newWidth, newHeight));
      }
    } catch (e) {
      // Silently handle errors
    } finally {
      _isResizing = false;
    }
  }

  @override
  void onWindowResize() {
    // Debounced resize handling
    if (!_isResizing) {
      Timer(const Duration(milliseconds: 100), _enforceWindowSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primary = themeProvider.primaryColor;
    final secondary = themeProvider.secondaryColor;

    // AMOLED true black theme with accent colors
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: Colors.black, // OLED black
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
      ),
      tabBarTheme: TabBarThemeData(
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: secondary, width: 3),
        ),
        labelColor: secondary,
        unselectedLabelColor: const Color(0xFF9AA5AE),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondary,
          side: BorderSide(color: secondary),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Color(0xFF101010),
        textStyle: TextStyle(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF101010),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: secondary.withValues(alpha: 0.2),
      ),
      dividerColor: Colors.white10,
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF101010)),
    );

    return MaterialApp(
      title: 'MX Player Clone',
      theme: theme,
      darkTheme: theme,
      themeMode: themeProvider.materialThemeMode,
      home: const MainLayoutScreen(),
      routes: {
        '/player': (context) {
          // Get the current file from MediaProvider
          final mediaProvider = Provider.of<MediaProvider>(
            context,
            listen: false,
          );
          if (mediaProvider.currentFile != null) {
            return PlayerScreen(file: mediaProvider.currentFile!);
          } else {
            // If no current file, navigate back to main screen
            return const MainLayoutScreen();
          }
        },
        '/equalizer': (context) => const EqualizerScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
