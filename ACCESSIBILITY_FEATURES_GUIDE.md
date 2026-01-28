# ILABA App - Global Accessibility Features Guide

## Overview

The ILABA app now includes comprehensive accessibility features that apply globally across the entire application. All settings persist across user sessions using `SharedPreferences`.

---

## Features Implemented

### 1. **Text Size (Dropdown)**
- **Options**: Small (85%), Default (100%), Large (120%)
- **Application**: All text throughout the app scales proportionally
- **Affects**: 
  - Order screens
  - Loyalty cards
  - Profile pages
  - Settings screens
  - FAQ pages
  - All headings, body text, and labels

**How it works:**
- The `SettingsProvider` maintains a `textSizeMultiplier` that adjusts from 0.85 to 1.2x
- The custom theme applies this multiplier to all `TextTheme` styles
- All widgets that use `Theme.of(context).textTheme.*` automatically scale

### 2. **High Contrast Text (Toggle)**
- **Default**: OFF (normal font weights)
- **Enabled**: All text uses bold/bolder font weights for higher visibility
- **Affects**:
  - Body text → bolder
  - Headlines → bold
  - Labels → bold
  - All text becomes more prominent

**Implementation:**
- When enabled, all `FontWeight` values increase (e.g., `w400` → `w600`)
- Titles and headings become `bold` (FontWeight.w700+)
- Improves readability for users with visual impairments

---

## System Architecture

### Settings Provider (`lib/providers/settings_provider.dart`)

The `SettingsProvider` is the core of the accessibility system:

```dart
class SettingsProvider extends ChangeNotifier {
  // Enum for text size modes
  enum TextSizeMode { small, default_, large }
  
  // State management
  TextSizeMode _textSizeMode = TextSizeMode.default_;
  bool _highContrastText = false;
  
  // Computed properties
  double get textSizeMultiplier { ... }
  
  // Persistence methods
  Future<void> _loadSettings() { ... }
  Future<void> setTextSize(TextSizeMode size) { ... }
  Future<void> toggleHighContrastText(bool value) { ... }
  Future<void> resetToDefaults() { ... }
  
  // Theme generation
  ThemeData getCustomTheme() { ... }
  TextTheme _buildAccessibleTextTheme(ColorScheme colorScheme) { ... }
}
```

### App-Wide Theme Application (`lib/main.dart`)

The theme is applied globally through the app's `MaterialApp`:

```dart
Consumer<SettingsProvider>(
  builder: (context, settingsProvider, _) {
    return MaterialApp(
      title: 'iLaba',
      theme: settingsProvider.getCustomTheme(), // ← Global theme
      home: Consumer<AuthProvider>(...),
      // ... rest of app
    );
  },
),
```

### Settings UI (`lib/screens/settings/settings_screen.dart`)

Users control settings through a clean, modern interface:

- **Dropdown**: Switch between Small, Default, Large text sizes
- **Toggles**: Enable/disable Color Blind Mode and High Contrast Text
- **Live Preview**: Shows how text will appear with current settings
- **Reset Button**: Restore all settings to default

---

## How Settings Persist

1. **On Change**: When user toggles a setting, `SettingsProvider` updates state AND saves to `SharedPreferences`
2. **On App Start**: `SettingsProvider` constructor calls `_loadSettings()`, which retrieves saved preferences
3. **SharedPreferences Keys**:
   - `textSizeMode` → stored as integer index (0, 1, or 2)
   - `highContrastText` → stored as boolean

---

## Global Impact Matrix

| Screen/Feature | Text Size | High Contrast |
|---|---|---|
| Login Screen | ✅ | ✅ |
| Home Menu | ✅ | ✅ |
| Orders Screen | ✅ | ✅ |
| Loyalty Card | ✅ | ✅ |
| Mobile Booking | ✅ | ✅ |
| FAQ Screen | ✅ | ✅ |
| Profile Page | ✅ | ✅ |
| Settings Screen | ✅ | ✅ |
| All Buttons | ✅ | ✅ |
| AppBar | ✅ | ✅ |
| Cards | ✅ | ✅ |
| Dialogs | ✅ | ✅ |

---

## Technical Details

### Theme Building Process

When `getCustomTheme()` is called:

1. **Create Base Color Scheme**:
   - If Color Blind Mode: Use `Colors.deepOrange` seed
   - Otherwise: Use `Colors.indigo` seed

2. **Build Accessible Text Theme**:
   - Apply text size multiplier to all styles
   - Apply high contrast (bold font weights if enabled)
   - Apply high contrast text colors if needed

3. **Configure Component Themes**:
   - AppBar theme with selected colors
   - CardThemeData with accessible backgrounds
   - Button themes with scaled text sizes
   - Elevated, Filled, and Outlined button styling

### Text Theme Customization

All text styles (displayLarge, displayMedium, headlineSmall, bodyMedium, etc.) are customized to:
- Scale with `textSizeMultiplier`
- Apply bold weights when `highContrastText` is enabled
- Use accessible colors when `colorBlindMode` is enabled

---

## User Experience Flow

### First Time User
1. Opens app → Default settings (Normal text size, indigo theme, regular contrast)
2. Navigates to Settings via hamburger menu → "Accessibility Settings"
3. Can adjust text size, enable color blind mode, enable high contrast

### Returning User
1. Opens app → Previous settings automatically restored from SharedPreferences
2. All screens display with saved preferences applied

### Changing Settings
1. User changes dropdown or toggles → Instant UI rebuild
2. All screens across the entire app update in real-time
3. Settings saved to device

---

## Code Integration Points

### For Developers Adding New Screens

To ensure new screens respect accessibility settings:

1. **Use Theme Styles**:
   ```dart
   Text(
     'My Text',
     style: Theme.of(context).textTheme.bodyMedium, // Automatically scaled
   ),
   ```

2. **Use Theme Colors**:
   ```dart
   Container(
     color: Theme.of(context).scaffoldBackgroundColor, // Respects color blind mode
   ),
   ```

3. **Use Theme AppBar**:
   ```dart
   AppBar(
     // Automatically uses theme's AppBar colors
   ),
   ```

### Optional: Custom Styling for Specific Text

If you need to apply custom styling while respecting accessibility:

```dart
final settingsProvider = context.read<SettingsProvider>();
Text(
  'Custom Text',
  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
    fontSize: (16 * settingsProvider.textSizeMultiplier),
    fontWeight: settingsProvider.highContrastText ? FontWeight.bold : FontWeight.normal,
    color: settingsProvider.colorBlindMode ? Colors.black54 : Colors.black87,
  ),
);
```

---

## Testing Accessibility Features

### Manual Testing Checklist

- [ ] Text Size - Small: Verify all text appears smaller (85% of normal)
- [ ] Text Size - Large: Verify all text appears larger (120% of normal)
- [ ] Text Size - Persists: Change size, close app, reopen → setting maintained
- [ ] Color Blind - Toggle ON: Verify UI changes to orange theme
- [ ] Color Blind - Toggle OFF: Verify UI reverts to indigo theme
- [ ] Color Blind - All screens: Check orders, loyalty, FAQ, profile screens
- [ ] High Contrast - Toggle ON: Verify text appears bolder
- [ ] High Contrast - Toggle OFF: Verify text returns to normal weight
- [ ] High Contrast - Persists: Change setting, close app, reopen → setting maintained
- [ ] Settings Reset: Click reset button, verify all return to default
- [ ] Preview: Change settings, verify preview updates before applying globally

### Screens to Test
1. Login screen
2. Home menu
3. Orders screen
4. Loyalty card screen
5. Mobile booking flow
6. FAQ screen
7. Settings screen
8. Dialogs and alerts

---

## Performance Considerations

- **Minimal Overhead**: Settings changes trigger app-wide rebuild via Consumer, but this is efficient
- **Persistence**: SharedPreferences I/O is async but fast (typically < 50ms)
- **Theme Caching**: Material 3 theme caching is handled by Flutter automatically
- **No Observable Lag**: Settings changes apply immediately with smooth transition

---

## Future Enhancements

Potential improvements for future iterations:

1. **Font Family Selection**: Allow users to choose serif/sans-serif fonts
2. **Letter Spacing**: Add adjustable letter spacing for readability
3. **Line Height**: Customize line height for documents and long text
4. **Color Presets**: Save multiple preference combinations
5. **Dyslexia-Friendly Font**: Integrate OpenDyslexic or similar fonts
6. **Haptic Feedback**: Add haptic feedback for accessibility
7. **Screen Reader Support**: Enhanced VoiceOver/TalkBack compatibility
8. **Keyboard Navigation**: Improved keyboard-only navigation

---

## Support & Documentation

For questions or issues with accessibility features:

1. Check this guide for common questions
2. Verify all theme styles are using `Theme.of(context)`
3. Test with all three combinations enabled/disabled
4. Report any inconsistencies in accessibility application

---

## Summary

The ILABA app now provides comprehensive accessibility support through:
- ✅ Global text scaling (3 size options)
- ✅ Color-blind friendly color schemes
- ✅ High contrast mode for visibility
- ✅ Persistent user preferences
- ✅ Real-time application across entire app
- ✅ Clean, intuitive settings UI

All features work seamlessly across orders, loyalty cards, profiles, and every screen in the application.
