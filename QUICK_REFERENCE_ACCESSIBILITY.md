# Quick Reference - Global Accessibility Features

## 🎯 Quick Summary

The ILABA app now has **2 accessibility features that work across the entire app**:

| Feature | Type | Options | Persists? | Applies To |
|---------|------|---------|-----------|-----------|
| **Text Size** | Dropdown | Small / Default / Large | ✅ Yes | All text everywhere |
| **High Contrast Text** | Toggle | ON / OFF | ✅ Yes | All font weights |

---

## 🔄 How It Works

```
User Changes Setting
        ↓
SettingsProvider Notifies Listeners
        ↓
main.dart Consumer Rebuilds
        ↓
MaterialApp Gets New Theme
        ↓
ENTIRE APP UI UPDATES
        ↓
Setting Saved to Device
```

---

## 📍 Accessing Settings

1. Open ILABA app
2. Tap **hamburger menu** (three lines) in top-left
3. Tap **Settings** (or "Accessibility Settings")
4. Adjust settings:
   - Dropdown: Select text size
   - Toggle: High Contrast Text
5. Changes apply **instantly** across entire app

---

## 🎨 Visual Changes

### Text Size
- **Small**: All text 15% smaller (0.85x)
- **Default**: Normal text size (1.0x)  
- **Large**: All text 20% bigger (1.2x)

### High Contrast
- **OFF** (Default): Normal text weight
- **ON**: Bold text everywhere (easier to read)

---

## 💾 Persistence

✅ **Settings automatically save and restore**

- Change a setting → Instantly saved to device
- Close app → Settings remembered
- Reopen app → All settings restored exactly
- Reset button → Clear all to defaults

---

## 🧪 Testing Checklist

- [ ] Text Size Small: Is everything 15% smaller?
- [ ] Text Size Large: Is everything 20% bigger?
- [ ] High Contrast ON: Is text bold everywhere?
- [ ] High Contrast OFF: Is text back to normal?
- [ ] All screens work: Orders, Loyalty, FAQ, Profile
- [ ] Settings persist: Close app, reopen, settings remain

---

## ⚙️ Technical Details

### Where Settings Are Applied

**Every Screen:**
- Login
- Home Menu
- Orders
- Loyalty Card
- Mobile Booking
- FAQ
- Profile
- Settings

**Every Component:**
- Text (all sizes)
- Buttons (all types)
- AppBar
- Cards
- Dialogs
- Links
- Labels

### How It's Different From Before

| Before | After |
|--------|-------|
| Settings only changed preview box | Settings change entire app |
| Hard-coded indigo theme | Dynamic theme generation |
| No persistence between sessions | Automatic save/restore |
| Preview mode vs real mode confusion | One consistent app experience |

---

## 🔧 For Developers

### Using Accessible Styles

```dart
// ✅ DO: Use theme styles (respects accessibility)
Text('My Text', style: Theme.of(context).textTheme.bodyMedium)

// ✅ DO: Use theme colors (respects color blind mode)
Container(color: Theme.of(context).scaffoldBackgroundColor)

// ❌ DON'T: Hard-code colors
Text('My Text', style: TextStyle(color: Colors.indigo))

// ❌ DON'T: Hard-code font sizes
Text('My Text', style: TextStyle(fontSize: 14))
```

### How Theme Respects Settings

```
Text Size:
  Theme styles × textSizeMultiplier (0.85, 1.0, or 1.2)

Color Blind:
  ColorScheme uses deepOrange instead of indigo
  
High Contrast:
  FontWeight: normal → bold
```

---

## 📊 Settings Provider API

```dart
// Get current settings
SettingsProvider settings = context.read<SettingsProvider>();
double multiplier = settings.textSizeMultiplier;      // 0.85, 1.0, or 1.2
bool isColorBlind = settings.colorBlindMode;          // true/false
bool isHighContrast = settings.highContrastText;      // true/false

// Change settings
await settings.setTextSize(TextSizeMode.large);
await settings.toggleColorBlindMode(true);
await settings.toggleHighContrastText(true);
await settings.resetToDefaults();
```

---

## 🎯 User Stories

### Story 1: User with Vision Loss
1. Opens ILABA app
2. Goes to Settings
3. Enables Large text size (120%)
4. Enables High Contrast
5. **All text is now big and bold everywhere**

### Story 2: Color-Blind User
1. Opens ILABA app
2. Goes to Settings
3. Enables Color Blind Mode
4. **Entire app switches to orange/accessible theme**
5. Closes and reopens app → Settings restored

### Story 3: Returning User
1. Previous session: Had settings customized
2. Opens app today
3. **All previous settings automatically restored**
4. No need to reconfigure

---

## ⚠️ Troubleshooting

| Issue | Solution |
|-------|----------|
| Settings not changing | Ensure you're in Settings screen, check toggles/dropdown |
| Settings reset after restart | Likely cached old version, rebuild app: `flutter clean && flutter pub get && flutter run` |
| Text size not scaling on one screen | Check that screen uses Theme.of(context).textTheme instead of hard-coded sizes |
| Color theme not changing | Toggle Color Blind Mode OFF then ON, or reset to defaults |
| Text not getting bold | Toggle High Contrast OFF then ON |

---

## 📞 Support

For issues:
1. Check `ACCESSIBILITY_FEATURES_GUIDE.md` for detailed info
2. Check `GLOBAL_ACCESSIBILITY_IMPLEMENTATION.md` for architecture
3. Verify all screens use Theme.of(context) for styles
4. Test with all combinations of settings enabled/disabled

---

## ✨ Key Features

- ✅ **Global** - All 3 features work everywhere
- ✅ **Instant** - Changes apply in real-time
- ✅ **Persistent** - Settings saved automatically
- ✅ **Simple** - Easy dropdown and toggle UI
- ✅ **Inclusive** - Supports multiple accessibility needs
- ✅ **No Preview Mode** - What you set is what you get

---

**Ready to use!** All accessibility features are live and working across the entire ILABA app.
