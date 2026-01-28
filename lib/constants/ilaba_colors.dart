import 'package:flutter/material.dart';

/// Simple ILABA Color System
/// Two-color palette: White and Burgundy Red
class ILabaColors {
  // Primary Colors
  static const Color burgundy = Color(0xFFC41D7F);  // Main burgundy red
  static const Color burgundyDark = Color(0xFFA01560);  // Darker shade for gradients
  static const Color white = Color(0xFFFFFFFF);  // White
  static const Color lightGray = Color(0xFFF5F5F5);  // Very light gray (near white)
  
  // Text Colors
  static const Color darkText = Color(0xFF1A1A1A);  // Dark text on white
  static const Color lightText = Color(0xFF666666);  // Medium text
  static const Color lightGrayText = Color(0xFFAAAAAA);  // Light text/hints
  
  // Backgrounds
  static const Color background = white;
  static const Color cardBackground = white;
  
  // Accents
  static const Color accent = burgundy;
  static const Color accentLight = Color(0xFFE84C89);  // Lighter burgundy for secondary
  
  // Semantic
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFE67E22);
  static const Color error = Color(0xFFE74C3C);
  
  // Borders and dividers
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFF0F0F0);
  
  // Shadows (grayscale)
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> strongShadow = [
    BoxShadow(
      color: Color(0x1E000000),
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];
}

/// Simple ILABA Design System
/// White background with burgundy accents
class ILabaDesign {
  // Spacing (4dp base unit)
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  
  // Border radius
  static const double radius4 = 4.0;
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  
  // Typography
  static const double fontSize10 = 10.0;
  static const double fontSize12 = 12.0;
  static const double fontSize14 = 14.0;
  static const double fontSize16 = 16.0;
  static const double fontSize18 = 18.0;
  static const double fontSize20 = 20.0;
  static const double fontSize24 = 24.0;
  static const double fontSize28 = 28.0;
  static const double fontSize32 = 32.0;
  
  // Button style - Primary Burgundy
  static ButtonStyle primaryButtonStyle(BuildContext context) =>
      ElevatedButton.styleFrom(
        backgroundColor: ILabaColors.burgundy,
        foregroundColor: ILabaColors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: spacing24,
          vertical: spacing12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius12),
        ),
        elevation: 2,
        shadowColor: ILabaColors.burgundy.withOpacity(0.3),
      );
  
  // Button style - Secondary outline
  static ButtonStyle secondaryButtonStyle(BuildContext context) =>
      OutlinedButton.styleFrom(
        foregroundColor: ILabaColors.burgundy,
        side: const BorderSide(color: ILabaColors.burgundy, width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: spacing24,
          vertical: spacing12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius12),
        ),
      );
  
  // Input decoration
  static InputDecoration inputDecoration(
    String label, {
    String? hint,
    IconData? icon,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: ILabaColors.lightGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: ILabaColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: ILabaColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius12),
          borderSide: const BorderSide(color: ILabaColors.burgundy, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing12,
        ),
      );
  
  // Card decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: ILabaColors.white,
    borderRadius: BorderRadius.circular(radius16),
    boxShadow: ILabaColors.softShadow,
  );
}
