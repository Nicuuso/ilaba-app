# Global   │  │                    Settings Screen                        │   │
  │  │  ┌─────────────┐  ┌────────────────────┐                 │   │
  │  │  │ Text Size   │  │ High Contrast      │                 │   │
  │  │  │ Dropdown    │  │ Toggle             │                 │   │
  │  │  │ (85/100/120)│  │ (ON/OFF)           │                 │   │
  │  │  └──────┬──────┘  └─────────┬──────────┘                 │   │ibility Architecture Diagram

## System Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER INTERFACE                           │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    Settings Screen                        │   │
│  │  ┌─────────────┐  ┌──────────┐  ┌────────────────────┐  │   │
│  │  │ Text Size   │  │Color Blind│  │ High Contrast      │  │   │
│  │  │ Dropdown    │  │ Toggle    │  │ Toggle             │  │   │
│  │  │ (85/100/120)│  │ (ON/OFF)  │  │ (ON/OFF)           │  │   │
│  │  └──────┬──────┘  └─────┬─────┘  └─────────┬──────────┘  │   │
│  └─────────┼───────────────┼────────────────────┼─────────────┘   │
│            │               │                    │                  │
└────────────┼───────────────┼────────────────────┼──────────────────┘
             │               │                    │
             └───────────────┴────────────────────┘
                             │
                             ▼
        ┌────────────────────────────────────────┐
        │     SettingsProvider                   │
        │  (lib/providers/settings_provider.dart)│
        │                                        │
        │  • _textSizeMode                       │
        │  • _highContrastText                   │
        │                                        │
        │  Methods:                              │
        │  • setTextSize()                       │
        │  • toggleHighContrastText()            │
        │  • getCustomTheme() ◄─── KEY METHOD   │
        │  • resetToDefaults()                   │
        └────────────────────────────────────────┘
                             │
                ┌────────────┼────────────┐
                │            │            │
                ▼            ▼            ▼
        ┌──────────┐  ┌─────────┐  ┌────────────┐
        │ Saves to │  │ Notifies│  │ Generates  │
        │ Shared   │  │ All     │  │ Custom     │
        │Prefs     │  │Listeners│  │ ThemeData  │
        └──────────┘  └────┬────┘  └─────┬──────┘
                           │             │
                    ┌──────┴─────────────┘
                    │
                    ▼
        ┌────────────────────────────────────────┐
        │  main.dart                             │
        │  Consumer<SettingsProvider>            │
        │                                        │
        │  MaterialApp(                          │
        │    theme: settingsProvider             │
        │           .getCustomTheme()            │
        │  )                                     │
        └────────────────────────────────────────┘
                    │
                    ▼
        ┌────────────────────────────────────────┐
        │  Global ThemeData                      │
        │  (Applied to entire app)               │
        │                                        │
        │  • ColorScheme (Indigo)                │
        │  • TextTheme (All styles scaled)       │
        │  • AppBarTheme (Accessible colors)    │
        │  • CardThemeData (Responsive)         │
        │  • ButtonThemes (Scaled text)         │
        └────────────────────────────────────────┘
                    │
         ┌──────────┴──────────────────────────┐
         │                                      │
         ▼                                      ▼
    ┌─────────────────┐               ┌──────────────────┐
    │ All Text Styles │               │ All Color Values │
    │                 │               │                  │
    │ × textSize      │               │ = ColorScheme    │
    │   Multiplier    │               │   colors         │
    │ + FontWeight    │               │                  │
    │   if contrast   │               │ Indigo or Orange │
    └────────┬────────┘               └────────┬─────────┘
             │                                  │
             └──────────────┬───────────────────┘
                            │
         ┌──────────────────┴──────────────────┐
         │                                      │
         ▼                                      ▼
    ┌──────────────────────┐         ┌────────────────────┐
    │  All App Screens     │         │ Every Component    │
    │                      │         │                    │
    │ • Login Screen       │         │ • AppBar           │
    │ • Home Menu          │         │ • Buttons          │
    │ • Orders Screen      │         │ • Cards            │
    │ • Loyalty Card       │         │ • Text Fields      │
    │ • Mobile Booking     │         │ • Dialogs          │
    │ • FAQ Screen         │         │ • Links            │
    │ • Profile Page       │         │ • Labels           │
    │ • Settings Screen    │         │ • Badges           │
    │                      │         │ • Icons (colors)   │
    └──────────────────────┘         └────────────────────┘
         │                                      │
         └──────────────┬───────────────────────┘
                        │
                        ▼
         ┌──────────────────────────────┐
         │   USER SEES CHANGES          │
         │   ACROSS ENTIRE APP          │
         │                              │
         │ ✓ Text Size Changes          │
         │ ✓ Color Theme Changes        │
         │ ✓ Contrast Changes           │
         │ ✓ All Screens Updated        │
         │ ✓ All Components Updated     │
         └──────────────────────────────┘
```

---

## Theme Generation Pipeline

```
getCustomTheme() Method:
│
├─ Step 1: Select Base Color Scheme
│  ├─ IF colorBlindMode = true
│  │  └─ Use Colors.deepOrange (Accessible)
│  └─ ELSE
│     └─ Use Colors.indigo (Default)
│
├─ Step 2: Build Text Theme
│  ├─ displayLarge    → fontSize × textSizeMultiplier
│  ├─ headlineSmall   → fontSize × textSizeMultiplier + bold if contrast
│  ├─ bodyMedium      → fontSize × textSizeMultiplier
│  ├─ bodySmall       → fontSize × textSizeMultiplier
│  └─ ... (15+ more styles)
│
├─ Step 3: Configure AppBar
│  ├─ backgroundColor  = primary color from scheme
│  ├─ foregroundColor  = white/contrasting color
│  └─ elevation        = 0 (flat)
│
├─ Step 4: Configure Cards
│  ├─ color            = theme card color
│  └─ elevation        = 2
│
├─ Step 5: Configure Buttons
│  ├─ textStyle        → fontSize scaled
│  ├─ fontWeight       → bold if highContrast
│  └─ colors           → from scheme
│
└─ Return Complete ThemeData
   └─ Used by MaterialApp
      └─ Applied to entire app tree
```

---

## Persistence Flow

```
User Changes Setting
        │
        ▼
SettingsProvider.setTextSize() 
(or toggleColorBlindMode, etc)
        │
        ├─────────────────────────────────┐
        │                                 │
        ▼                                 ▼
   Update State              Save to SharedPreferences
   (_textSizeMode)           (setInt/setBool)
        │                                 │
        └─────────────────────────────────┘
                 │
                 ▼
        notifyListeners()
                 │
                 ▼
   Consumer<SettingsProvider> Rebuilds
                 │
                 ▼
        MaterialApp gets new theme
                 │
                 ▼
        Entire app UI updates
                 │
                 ▼
   ┌────────────────────────────────┐
   │ USER SEES CHANGES              │
   │ (Instantly across app)         │
   └────────────────────────────────┘


NEXT TIME USER OPENS APP:
        │
        ├─ SettingsProvider() constructor
        │  └─ Calls _loadSettings()
        │     └─ Reads from SharedPreferences
        │        └─ Restores all saved settings
        │
        ▼
   All Settings Ready
        │
        ▼
   App Displays with Saved Settings
```

---

## State Management Architecture

```
┌─────────────────────────────────────────────────┐
│               App State Tree                     │
├─────────────────────────────────────────────────┤
│                                                 │
│ MyApp                                          │
│ └─ MultiProvider                               │
│    ├─ AuthProvider                             │
│    ├─ MobileBookingProvider                    │
│    ├─ SettingsProvider ◄── ACCESSIBILITY      │
│    │   ├─ _textSizeMode                       │
│    │   ├─ _colorBlindMode                     │
│    │   └─ _highContrastText                   │
│    │                                           │
│    └─ Consumer<SettingsProvider>               │
│       └─ MaterialApp                           │
│          ├─ theme (dynamic)                    │
│          └─ home                               │
│             └─ AuthProvider Consumer           │
│                ├─ LoginScreen                  │
│                └─ HomeMenuScreen               │
│                   ├─ OrdersScreen              │
│                   ├─ LoyaltyCardScreen        │
│                   ├─ FAQScreen                 │
│                   ├─ ProfileScreen             │
│                   └─ SettingsScreen            │
│                      (Consumer<SettingsProvider>)
│
└─────────────────────────────────────────────────┘

All Consumers listen to SettingsProvider changes
When settings change → All consumers rebuild
→ App displays with new theme
```

---

## Accessibility Setting Application

```
Text Size Setting:
│
├─ getTextStyle(baseStyle)
│  └─ fontSize = baseStyle.fontSize × textSizeMultiplier
│     ├─ (Small)    × 0.85
│     ├─ (Default)  × 1.0
│     └─ (Large)    × 1.2
│
└─ Applied via Theme.of(context).textTheme.*


Color Blind Setting:
│
├─ getCustomTheme()
│  ├─ IF colorBlindMode = true
│  │  └─ ColorScheme.fromSeed(deepOrange)
│  └─ ELSE
│     └─ ColorScheme.fromSeed(indigo)
│
└─ Entire app color scheme changes
   ├─ AppBar colors
   ├─ Button colors
   ├─ Card backgrounds
   └─ Link/Badge colors


High Contrast Setting:
│
├─ _buildAccessibleTextTheme()
│  ├─ IF highContrastText = true
│  │  └─ FontWeight.bold for all text
│  └─ ELSE
│     └─ Normal font weights
│
└─ Applied to all text styles
   ├─ Headings
   ├─ Body text
   ├─ Labels
   └─ Button text
```

---

## File Dependencies

```
main.dart
    ├─ imports settings_provider.dart
    │
    └─ Uses Consumer<SettingsProvider>
       └─ Calls getCustomTheme()


settings_screen.dart
    ├─ imports settings_provider.dart
    │
    └─ Consumer<SettingsProvider>
       ├─ Calls setTextSize()
       ├─ Calls toggleColorBlindMode()
       ├─ Calls toggleHighContrastText()
       └─ Calls resetToDefaults()


settings_provider.dart
    ├─ ChangeNotifier
    │
    ├─ SharedPreferences
    │  ├─ _loadSettings() → Load on init
    │  ├─ setTextSize() → Save on change
    │  ├─ toggleColorBlindMode() → Save on change
    │  └─ toggleHighContrastText() → Save on change
    │
    └─ getCustomTheme()
       └─ Returns ThemeData for MaterialApp


all_other_screens.dart
    └─ Use Theme.of(context)
       └─ Automatically respect accessibility settings
```

---

## Settings Persistence Storage

```
SharedPreferences Database
│
├─ textSizeMode (int)
│  ├─ 0 = TextSizeMode.small (0.85x)
│  ├─ 1 = TextSizeMode.default_ (1.0x)
│  └─ 2 = TextSizeMode.large (1.2x)
│
├─ colorBlindMode (bool)
│  ├─ true = Deep Orange theme active
│  └─ false = Indigo theme (default)
│
└─ highContrastText (bool)
   ├─ true = Bold text weights
   └─ false = Normal text weights

Each key automatically saved/loaded:
├─ On initialization: _loadSettings()
├─ On change: setTextSize(), toggleColorBlindMode(), etc.
└─ Manual reset: resetToDefaults()
```

---

## Real-Time Update Flow

```
User taps dropdown to change text size from Default to Large:

1. onChanged callback triggered
2. settingsProvider.setTextSize(TextSizeMode.large)
3. _textSizeMode = TextSizeMode.large
4. await prefs.setInt('textSizeMode', 2) ← Saved to device
5. notifyListeners() ← Notify all consumers
6. Consumer<SettingsProvider> in main.dart receives update
7. MaterialApp rebuilds
8. theme: settingsProvider.getCustomTheme() called
9. All text themes recalculated with multiplier = 1.2
10. Flutter rebuilds app tree with new theme
11. User sees all text 20% larger everywhere
    ├─ Orders screen text = larger
    ├─ Loyalty card text = larger
    ├─ Settings screen text = larger
    ├─ All buttons = larger text
    └─ Dialogs = larger text
12. Setting persisted to SharedPreferences
13. Next app open: setting restored automatically
```

---

## Key Design Principles

```
1. SINGLE SOURCE OF TRUTH
   └─ SettingsProvider is the only state manager for accessibility

2. REACTIVE UI
   └─ Changes notify listeners → UI rebuilds automatically

3. THEME CENTRALIZATION
   └─ All styling in getCustomTheme() → No scattered hardcodes

4. PERSISTENCE ABSTRACTION
   └─ SharedPreferences handled internally → Transparent to UI

5. GLOBAL APPLICATION
   └─ Theme applied via MaterialApp → Affects entire tree

6. USER-FIRST DESIGN
   └─ Settings auto-load → Seamless experience on reopen

7. NO PREVIEW MODE
   └─ Settings apply immediately → No confusion
```

---

## Summary

The global accessibility architecture ensures:
✅ Settings apply everywhere (100% coverage)
✅ Changes occur in real-time (instant feedback)
✅ Persistence is automatic (seamless experience)
✅ Code is maintainable (single source of truth)
✅ Architecture is scalable (easy to add features)
