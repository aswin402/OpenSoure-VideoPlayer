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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final provider = MediaProvider();
            // Initialize asynchronously after creation
            WidgetsBinding.instance.addPostFrameCallback((_) {
              provider
                  .initialize()
                  .then((_) => debugPrint('MediaProvider initialized'))
                  .catchError(
                    (e) => debugPrint('Error initializing MediaProvider: $e'),
                  );
            });
            return provider;
          },
        ),
        // PlayerProvider available app-wide
        ChangeNotifierProvider(create: (_) => PlayerProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),
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

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);

    // Start a periodic check to enforce size constraints
    _sizeCheckTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      _enforceWindowSize();
    });
  }

  @override
  void dispose() {
    _sizeCheckTimer?.cancel();
    windowManager.removeListener(this);
    super.dispose();
  }

  void _enforceWindowSize() {
    windowManager
        .getSize()
        .then((size) {
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
            debugPrint(
              'Window width too small (${size.width}), enforcing minimum: $minWidth',
            );
          } else if (size.width > maxWidth) {
            newWidth = maxWidth;
            needsResize = true;
          }

          if (size.height < minHeight) {
            newHeight = minHeight;
            needsResize = true;
            debugPrint(
              'Window height too small (${size.height}), enforcing minimum: $minHeight',
            );
          } else if (size.height > maxHeight) {
            newHeight = maxHeight;
            needsResize = true;
          }

          if (needsResize) {
            debugPrint(
              'Resizing window from ${size.width}x${size.height} to ${newWidth}x$newHeight',
            );
            windowManager.setSize(Size(newWidth, newHeight));
          }
        })
        .catchError((e) {
          // Ignore errors during size checking
        });
  }

  @override
  void onWindowResize() {
    // Trigger size enforcement on resize events
    _enforceWindowSize();
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
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
