import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/app_settings_provider.dart';
import 'providers/document_provider.dart';
import 'providers/scene_analyzer_provider.dart';
import 'screens/editor_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager for fullscreen support
  await windowManager.ensureInitialized();

  runApp(const JustWriteApp());
}

class JustWriteApp extends StatelessWidget {
  const JustWriteApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(create: (_) => SceneAnalyzerProvider()),
      ],
      child: Consumer<AppSettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Floe',
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(settings),
            darkTheme: _buildDarkTheme(settings),
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const EditorScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme(AppSettingsProvider settings) {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      primaryColor: Colors.black87,
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontFamily: settings.fontFamily,
          fontSize: settings.fontSize,
          height: settings.lineHeight,
          color: Colors.black87,
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme(AppSettingsProvider settings) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      primaryColor: Colors.white70,
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontFamily: settings.fontFamily,
          fontSize: settings.fontSize,
          height: settings.lineHeight,
          color: Colors.white70,
        ),
      ),
    );
  }
}
