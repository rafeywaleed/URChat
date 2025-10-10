import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';

class NesThemeWrapper extends StatefulWidget {
  final Widget child;
  final ThemeData? customTheme;
  final ThemeMode themeMode;

  const NesThemeWrapper({
    super.key,
    required this.child,
    this.customTheme,
    this.themeMode = ThemeMode.light,
  });

  @override
  State<NesThemeWrapper> createState() => _NesThemeWrapperState();
}

class _NesThemeWrapperState extends State<NesThemeWrapper> {
  late ThemeData _currentTheme;
  late ThemeMode _currentThemeMode;

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.customTheme ?? flutterNesTheme();
    _currentThemeMode = widget.themeMode;
  }

  void updateTheme(ThemeData newTheme, ThemeMode newThemeMode) {
    setState(() {
      _currentTheme = newTheme;
      _currentThemeMode = newThemeMode;
    });
  }

  @override
  void didUpdateWidget(NesThemeWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.customTheme != oldWidget.customTheme ||
        widget.themeMode != oldWidget.themeMode) {
      setState(() {
        _currentTheme = widget.customTheme ?? flutterNesTheme();
        _currentThemeMode = widget.themeMode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _currentTheme.copyWith(
        platform: TargetPlatform.android,
      ),
      darkTheme: _createDarkTheme(_currentTheme),
      themeMode: _currentThemeMode,
      home: widget.child,
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _createDarkTheme(ThemeData lightTheme) {
    // Create a proper dark theme based on your light theme
    return lightTheme.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.grey[900],
      cardColor: Colors.grey[800],
      dialogBackgroundColor: Colors.grey[800],
      colorScheme: ColorScheme.dark(
        primary: lightTheme.colorScheme.primary,
        secondary: lightTheme.colorScheme.secondary,
        surface: const Color.fromARGB(255, 63, 63, 63),
        background: Colors.grey[900],
      ),
    );
  }
}
