import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

import 'providers/media_provider.dart';
import 'providers/player_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/player_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

void _initializeLinuxLibs() {
  // This will be handled by media_kit automatically on Linux
  // No need for explicit MediaKitLibsLinux.ensureInitialized()
}

class MxCloneApp extends StatelessWidget {
  static const appName = 'MX Clone';
  const MxCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primary = themeProvider.primaryColor;
    final secondary = themeProvider.secondaryColor;

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        background: const Color(0xFF121212),
        surface: const Color(0xFF121212),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: primary,
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
        unselectedLabelColor: const Color(0xFFB0BEC5),
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
        color: Color(0xFF1E1E1E),
        textStyle: TextStyle(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: secondary.withOpacity(0.2),
      ),
    );

    return MaterialApp(
      title: 'MX Player Clone',
      theme: theme,
      darkTheme: theme,
      themeMode: themeProvider.materialThemeMode,
      home: const HomeScreen(),
      routes: {'/player': (context) => const PlayerScreen()},
      debugShowCheckedModeBanner: false,
    );
  }
}
