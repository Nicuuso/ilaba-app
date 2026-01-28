import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilaba/constants/ilaba_colors.dart';

enum TextSizeMode {
  small,
  default_,
  large,
}

class SettingsProvider extends ChangeNotifier {
  // Settings state
  TextSizeMode _textSizeMode = TextSizeMode.default_;
  bool _highContrastText = false;

  // Getters
  TextSizeMode get textSizeMode => _textSizeMode;
  bool get highContrastText => _highContrastText;

  // Text size multiplier
  double get textSizeMultiplier {
    switch (_textSizeMode) {
      case TextSizeMode.small:
        return 0.85;
      case TextSizeMode.default_:
        return 1.0;
      case TextSizeMode.large:
        return 1.2;
    }
  }

  SettingsProvider() {
    _loadSettings();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load text size
      final textSizeIndex = prefs.getInt('textSizeMode') ?? 1; // default is 1
      _textSizeMode = TextSizeMode.values[textSizeIndex];

      // Load high contrast text
      _highContrastText = prefs.getBool('highContrastText') ?? false;

      notifyListeners();
    } catch (e) {
      debugPrint('❌ SettingsProvider: Error loading settings: $e');
    }
  }

  // Set text size
  Future<void> setTextSize(TextSizeMode size) async {
    try {
      _textSizeMode = size;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('textSizeMode', size.index);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ SettingsProvider: Error setting text size: $e');
    }
  }

  // Toggle high contrast text
  Future<void> toggleHighContrastText(bool value) async {
    try {
      _highContrastText = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('highContrastText', value);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ SettingsProvider: Error toggling high contrast text: $e');
    }
  }

  // Reset all settings to default
  Future<void> resetToDefaults() async {
    try {
      _textSizeMode = TextSizeMode.default_;
      _highContrastText = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('textSizeMode');
      await prefs.remove('highContrastText');

      notifyListeners();
    } catch (e) {
      debugPrint('❌ SettingsProvider: Error resetting settings: $e');
    }
  }

  // Get theme with accessibility adjustments
  ThemeData getCustomTheme() {
    // Use burgundy as the primary color to match the app design
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: ILabaColors.burgundy,
      primary: ILabaColors.burgundy,
    );

    return ThemeData(
      colorScheme: baseColorScheme,
      useMaterial3: true,
      textTheme: _buildAccessibleTextTheme(baseColorScheme),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: ILabaColors.burgundy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: TextStyle(
            fontWeight: _highContrastText ? FontWeight.bold : FontWeight.w600,
            fontSize: 14 * textSizeMultiplier,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: TextStyle(
            fontWeight: _highContrastText ? FontWeight.bold : FontWeight.w600,
            fontSize: 15 * textSizeMultiplier,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: TextStyle(
            fontWeight: _highContrastText ? FontWeight.bold : FontWeight.w600,
            fontSize: 14 * textSizeMultiplier,
          ),
        ),
      ),
    );
  }

  // Build text theme with accessibility
  TextTheme _buildAccessibleTextTheme(ColorScheme colorScheme) {
    final baseTheme = Typography.englishLike2018;

    return baseTheme.apply(
      displayColor: _getTextColor(Colors.black87),
      bodyColor: _getTextColor(Colors.black87),
    ).copyWith(
      displayLarge: baseTheme.displayLarge?.copyWith(
        fontSize: (57 * textSizeMultiplier),
        fontWeight: _highContrastText ? FontWeight.bold : FontWeight.w400,
        color: _getTextColor(Colors.black87),
      ),
      displayMedium: baseTheme.displayMedium?.copyWith(
        fontSize: (45 * textSizeMultiplier),
        fontWeight: _highContrastText ? FontWeight.bold : FontWeight.w400,
        color: _getTextColor(Colors.black87),
      ),
      displaySmall: baseTheme.displaySmall?.copyWith(
        fontSize: (36 * textSizeMultiplier),
        fontWeight: _highContrastText ? FontWeight.bold : FontWeight.w400,
        color: _getTextColor(Colors.black87),
      ),
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        fontSize: (32 * textSizeMultiplier),
        fontWeight: _highContrastText ? FontWeight.bold : FontWeight.w400,
        color: _getTextColor(Colors.black87),
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        fontSize: (28 * textSizeMultiplier),
        fontWeight: _highContrastText ? FontWeight.bold : FontWeight.w400,
        color: _getTextColor(Colors.black87),
      ),
      headlineSmall: baseTheme.headlineSmall?.copyWith(
        fontSize: (24 * textSizeMultiplier),
        fontWeight: _highContrastText ? FontWeight.bold : FontWeight.w500,
        color: _getTextColor(Colors.black87),
      ),
      titleLarge: baseTheme.titleLarge?.copyWith(
        fontSize: (22 * textSizeMultiplier),
        fontWeight: _highContrastText ? FontWeight.bold : FontWeight.w500,
        color: _getTextColor(Colors.black87),
      ),
      titleMedium: baseTheme.titleMedium?.copyWith(
        fontSize: (16 * textSizeMultiplier),
        fontWeight: _highContrastText ? FontWeight.bold : FontWeight.w600,
        color: _getTextColor(Colors.black87),
      ),
      titleSmall: baseTheme.titleSmall?.copyWith(
        fontSize: (14 * textSizeMultiplier),
        fontWeight: _highContrastText ? FontWeight.bold : FontWeight.w600,
        color: _getTextColor(Colors.black87),
      ),
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        fontSize: (16 * textSizeMultiplier),
        fontWeight: _highContrastText ? FontWeight.w600 : FontWeight.w500,
        color: _getTextColor(Colors.black87),
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        fontSize: (14 * textSizeMultiplier),
        fontWeight: _highContrastText ? FontWeight.w500 : FontWeight.w400,
        color: _getTextColor(Colors.black87),
      ),
      bodySmall: baseTheme.bodySmall?.copyWith(
        fontSize: (12 * textSizeMultiplier),
        fontWeight: _highContrastText ? FontWeight.w500 : FontWeight.w400,
        color: _getTextColor(Colors.grey.shade700),
      ),
      labelLarge: baseTheme.labelLarge?.copyWith(
        fontSize: (14 * textSizeMultiplier),
        fontWeight: _highContrastText ? FontWeight.bold : FontWeight.w600,
        color: _getTextColor(Colors.black87),
      ),
      labelMedium: baseTheme.labelMedium?.copyWith(
        fontSize: (12 * textSizeMultiplier),
        fontWeight: _highContrastText ? FontWeight.bold : FontWeight.w500,
        color: _getTextColor(Colors.black87),
      ),
      labelSmall: baseTheme.labelSmall?.copyWith(
        fontSize: (11 * textSizeMultiplier),
        fontWeight: _highContrastText ? FontWeight.bold : FontWeight.w500,
        color: _getTextColor(Colors.black87),
      ),
    );
  }

  // Get text color with accessibility
  Color _getTextColor(Color defaultColor) {
    if (_highContrastText) {
      return Colors.black87;
    }
    return defaultColor;
  }

  // Get text style with all accessibility applied
  TextStyle getAccessibleTextStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * textSizeMultiplier,
      fontWeight: _highContrastText
          ? FontWeight.bold
          : (baseStyle.fontWeight ?? FontWeight.normal),
      color: _getTextColor(baseStyle.color ?? Colors.black87),
    );
  }
}

