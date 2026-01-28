# Developer Quick Start - Global Accessibility

## 🚀 Getting Started

The ILABA app now has **global accessibility features** that automatically apply to all screens and components.

---

## 5-Minute Overview

### What Changed
- Settings no longer only affect preview mode
- Both features (text size and high contrast) now control the entire app
- Theme is generated dynamically based on accessibility settings

### Where Settings Live
- **Stored:** `SharedPreferences` (auto-saved and auto-loaded)
- **Managed:** `SettingsProvider` (state management)
- **Applied:** `main.dart` via `Consumer<SettingsProvider>`

### How to Use
```dart
// Read current settings
final settings = context.read<SettingsProvider>();
print(settings.textSizeMode);      // TextSizeMode.default_
print(settings.highContrastText);  // false

// Change settings
await settings.setTextSize(TextSizeMode.large);
await settings.toggleHighContrastText(true);
await settings.resetToDefaults();
```

---

## For New Screens/Widgets

### ✅ DO: Use Theme Styles

```dart
// Text with automatic scaling
Text(
  'Hello User',
  style: Theme.of(context).textTheme.bodyMedium,  // ← Respects text size
)

// Colors with theme support
Container(
  color: Theme.of(context).scaffoldBackgroundColor,  // ← Respects theme
)

// Buttons automatically styled
ElevatedButton(
  onPressed: () {},
  child: Text('Click Me'),  // ← Font weight respects high contrast
)

// AppBar automatically themed
AppBar(
  title: Text('My Screen'),  // ← All theme colors applied
)
```

### ❌ DON'T: Hard-Code Values

```dart
// ❌ BAD - Ignores accessibility settings
Text(
  'Hello User',
  style: TextStyle(fontSize: 14, color: Colors.indigo),
)

// ❌ BAD - Hard-coded color
Container(color: Colors.white)

// ❌ BAD - Hard-coded font weight
Text('Hello', style: TextStyle(fontWeight: FontWeight.bold))
```

---

## Integration Examples

### Example 1: Simple Text Screen

```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Screen'),  // ← Automatically themed
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Main Title',
              style: Theme.of(context).textTheme.headlineSmall,  // ✓ Respects settings
            ),
            SizedBox(height: 16),
            Text(
              'Body text that will scale with text size setting',
              style: Theme.of(context).textTheme.bodyMedium,  // ✓ Respects settings
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: Text('Continue'),  // ✓ Font respects high contrast
            ),
          ],
        ),
      ),
    );
  }
}
```

### Example 2: Card-Based Layout

```dart
Card(
  color: Theme.of(context).cardColor,  // ✓ Card color respects color-blind mode
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        Text(
          'Card Title',
          style: Theme.of(context).textTheme.titleLarge,  // ✓ Scaled & bold if contrast
        ),
        SizedBox(height: 8),
        Text(
          'Card description text',
          style: Theme.of(context).textTheme.bodyMedium,  // ✓ All settings applied
        ),
      ],
    ),
  ),
)
```

### Example 3: Custom Styling with Accessibility

If you need custom styling while respecting accessibility:

```dart
final settings = context.read<SettingsProvider>();

Text(
  'Custom Styled Text',
  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
    fontSize: (16 * settings.textSizeMultiplier),  // ✓ Scale text
    fontWeight: settings.highContrastText 
        ? FontWeight.bold 
        : FontWeight.normal,  // ✓ Apply contrast
    color: settings.colorBlindMode 
        ? Colors.black54 
        : Colors.black87,  // ✓ Accessible color
  ),
)
```

---

## Common Patterns

### Pattern 1: Responsive List Item

```dart
ListTile(
  leading: Icon(Icons.info),  // ← Icon color comes from theme
  title: Text('Item Title', 
    style: Theme.of(context).textTheme.titleMedium),  // ← Scaled text
  subtitle: Text('Item description',
    style: Theme.of(context).textTheme.bodySmall),  // ← Scaled text
  trailing: Icon(Icons.arrow_forward),
)
```

### Pattern 2: Dialog with Accessibility

```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,  // ← Respects theme
    title: Text('Title',
      style: Theme.of(context).textTheme.headlineSmall),  // ← Scaled
    content: Text('Message',
      style: Theme.of(context).textTheme.bodyMedium),  // ← Scaled
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Cancel'),  // ← Respects theme
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Confirm'),  // ← Respects theme
      ),
    ],
  ),
)
```

### Pattern 3: Custom Card with All Settings

```dart
Consumer<SettingsProvider>(
  builder: (context, settings, child) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,  // ← Color respects color-blind mode
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,  // ← Border respects theme
        ),
      ),
      child: Column(
        children: [
          Text(
            'Dynamic Title',
            style: Theme.of(context).textTheme.titleLarge,  // ← Scaled + contrast
          ),
          SizedBox(height: 8 * settings.textSizeMultiplier),  // ← Scale spacing too
          Text(
            'Description',
            style: Theme.of(context).textTheme.bodyMedium,  // ← Scaled + contrast
          ),
        ],
      ),
    );
  },
)
```

---

## Testing Your Code

### Manual Testing Checklist

When adding new screens, verify:

- [ ] Text appears smaller when text size = Small
- [ ] Text appears larger when text size = Large  
- [ ] Colors change to orange when color blind mode = ON
- [ ] Text appears bold when high contrast = ON
- [ ] No hard-coded colors visible
- [ ] No hard-coded font sizes visible
- [ ] All text uses Theme.of(context) styles
- [ ] Spacing scales proportionally with text

### Quick Test Script

```dart
// Temporarily add to any screen to verify theme is applied
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final settings = context.read<SettingsProvider>();
  
  return Scaffold(
    body: SingleChildScrollView(
      child: Column(
        children: [
          Text('Theme Color: ${theme.colorScheme.primary}'),
          Text('Text Size Multiplier: ${settings.textSizeMultiplier}'),
          Text('Color Blind: ${settings.colorBlindMode}'),
          Text('High Contrast: ${settings.highContrastText}'),
          // ... rest of screen
        ],
      ),
    ),
  );
}
```

---

## Troubleshooting

### Issue: Text size not changing on my new screen

**Solution:** Make sure you're using `Theme.of(context).textTheme.*` instead of hard-coded `TextStyle`:

```dart
// ❌ Wrong - hard-coded
Text('Hello', style: TextStyle(fontSize: 16))

// ✅ Correct - uses theme
Text('Hello', style: Theme.of(context).textTheme.bodyMedium)
```

### Issue: Colors don't change with color blind mode

**Solution:** Use theme colors instead of hard-coded colors:

```dart
// ❌ Wrong - hard-coded
Container(color: Colors.indigo)

// ✅ Correct - uses theme
Container(color: Theme.of(context).colorScheme.primary)
```

### Issue: Font weight doesn't change with high contrast

**Solution:** Let the theme handle it, don't override font weight:

```dart
// ❌ Wrong - overrides theme
Text('Hello', style: TextStyle(fontWeight: FontWeight.normal))

// ✅ Correct - uses theme
Text('Hello', style: Theme.of(context).textTheme.bodyMedium)
```

---

## API Reference

### SettingsProvider Methods

```dart
// Get current text size multiplier
double multiplier = settingsProvider.textSizeMultiplier;
// Returns: 0.85 (Small), 1.0 (Default), or 1.2 (Large)

// Get current settings
TextSizeMode mode = settingsProvider.textSizeMode;
bool isColorBlind = settingsProvider.colorBlindMode;
bool isHighContrast = settingsProvider.highContrastText;

// Change settings
await settingsProvider.setTextSize(TextSizeMode.large);
await settingsProvider.toggleColorBlindMode(true);
await settingsProvider.toggleHighContrastText(true);

// Reset all settings
await settingsProvider.resetToDefaults();

// Get custom theme (normally not needed - theme applied globally)
ThemeData theme = settingsProvider.getCustomTheme();
```

### Theme Access

```dart
// Get theme in widget
final theme = Theme.of(context);

// Common theme values
theme.colorScheme.primary       // Primary color (indigo or orange)
theme.scaffoldBackgroundColor   // Background color
theme.cardColor                 // Card background
theme.dividerColor              // Border/divider color
theme.appBarTheme.backgroundColor  // AppBar color

// Text styles (all scaled and contrast-adjusted)
theme.textTheme.displayLarge
theme.textTheme.headlineSmall
theme.textTheme.titleLarge
theme.textTheme.bodyMedium
theme.textTheme.bodySmall
// ... and 10+ more styles
```

---

## Performance Tips

### ✅ DO

```dart
// Good: Single Text widget with theme
Text('Hello', style: Theme.of(context).textTheme.bodyMedium)

// Good: Use Consumer only when needed
Consumer<SettingsProvider>(
  builder: (context, settings, child) {
    // Only put code here that actually needs settings
  },
)

// Good: Cache theme lookup in build
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  return Column(
    children: [
      Text('Title', style: theme.textTheme.titleLarge),
      Text('Body', style: theme.textTheme.bodyMedium),
    ],
  );
}
```

### ❌ DON'T

```dart
// Bad: Theme.of() called repeatedly
Text('Title', style: Theme.of(context).textTheme.titleLarge),
Text('Body', style: Theme.of(context).textTheme.bodyMedium),
Text('Small', style: Theme.of(context).textTheme.bodySmall),

// Bad: Wrapping entire app in Consumer
Consumer<SettingsProvider>(
  builder: (context, settings, child) {
    return MyEntireApp();  // Rebuilds too much
  },
)

// Bad: Reading settings in every widget
Text('Hello', style: TextStyle(
  fontSize: context.read<SettingsProvider>().textSizeMultiplier * 14,
))
```

---

## Common Use Cases

### Use Case 1: Custom Component Library

Create a custom text widget that respects accessibility:

```dart
class AccessibleText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  
  const AccessibleText(this.text, {this.baseStyle});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = baseStyle ?? theme.textTheme.bodyMedium;
    return Text(text, style: style);
  }
}

// Usage - automatically respects all settings
AccessibleText('My Text')
AccessibleText('Custom', baseStyle: theme.textTheme.headlineSmall)
```

### Use Case 2: Conditional Styling

```dart
Text(
  'Important Notice',
  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
    color: Colors.red,  // ← Can override color if needed
    // But font size/weight still respect settings
  ),
)
```

### Use Case 3: Custom Spacing

Scale spacing proportionally with text:

```dart
Consumer<SettingsProvider>(
  builder: (context, settings, _) {
    return Column(
      children: [
        Text('Title', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 16 * settings.textSizeMultiplier),  // Scales with text
        Text('Body', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  },
)
```

---

## When to Use Consumer<SettingsProvider>

### Use Consumer When:
- You need to scale spacing proportionally with text size
- You need custom logic based on high contrast mode
- You're building a custom widget that needs multiple settings

### Don't Use Consumer When:
- Just using Theme.of(context) for styles
- Just rendering normal widgets
- The entire screen doesn't depend on settings (theme handle it)

---

## Best Practices

1. **Always use Theme.of(context)** for colors and text styles
2. **Never hard-code colors or font sizes**
3. **Use Consumer only when necessary** to avoid unnecessary rebuilds
4. **Test with all setting combinations** (small+colorblind, large+contrast, etc.)
5. **Scale spacing proportionally** with text size when needed
6. **Document any custom styling** clearly in comments

---

## Quick Checklist for New Screens

- [ ] All text uses `Theme.of(context).textTheme.*`
- [ ] All colors use `Theme.of(context).colorScheme.*` or `cardColor`
- [ ] No hard-coded color values (Colors.indigo, Colors.white, etc.)
- [ ] No hard-coded font sizes (fontSize: 14, etc.)
- [ ] Tested with text size = Small
- [ ] Tested with text size = Large
- [ ] Tested with color blind mode = ON
- [ ] Tested with high contrast = ON
- [ ] Screen looks good with all combinations

---

## Questions?

Refer to the complete documentation:
- `ACCESSIBILITY_FEATURES_GUIDE.md` - Detailed reference
- `ARCHITECTURE_DIAGRAMS.md` - System architecture
- `QUICK_REFERENCE_ACCESSIBILITY.md` - Quick lookup

---

**Happy coding! 🚀**
