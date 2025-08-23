import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

import 'providers/media_provider.dart';
import 'providers/player_provider.dart';
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
    return MaterialApp(
      title: 'MX Player Clone',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      home: const HomeScreen(),
      routes: {'/player': (context) => const PlayerScreen()},
      debugShowCheckedModeBanner: false,
    );
  }
}
