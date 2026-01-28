# 🎨 ILABA Color Scheme - Quick Reference Card

## Color Palette (White & Burgundy)

```
┌─────────────────────┐   ┌──────────────────────┐
│    BURGUNDY RED     │   │      WHITE BG        │
│    #C41D7F          │   │      #FFFFFF         │
│                     │   │                      │
│  • Primary accent   │   │  • Main background   │
│  • CTA buttons      │   │  • Card backgrounds  │
│  • Links            │   │  • Container fill    │
│  • Icons highlight  │   │  • Text backgrounds  │
└─────────────────────┘   └──────────────────────┘

┌──────────────────────────────────────┐
│     LIGHT GRAY (#F5F5F5)             │
│  • Input backgrounds                 │
│  • Hover states                      │
│  • Subtle backgrounds                │
└──────────────────────────────────────┘
```

## Text Colors

```
#1A1A1A  Headings (Dark)
#666666  Body Text (Medium)
#AAAAAA  Hints & Captions (Light)
#FFFFFF  White text (on burgundy)
```

## Quick Code Reference

```dart
// Import
import 'package:ilaba/constants/ilaba_colors.dart';

// Colors
ILabaColors.burgundy            // Main accent (#C41D7F)
ILabaColors.white               // Background (#FFFFFF)
ILabaColors.lightGray           // Light BG (#F5F5F5)
ILabaColors.darkText            // Headings (#1A1A1A)
ILabaColors.lightText           // Body (#666666)

// Spacing (px)
ILabaDesign.spacing8            // 8px
ILabaDesign.spacing12           // 12px
ILabaDesign.spacing16           // 16px ⭐
ILabaDesign.spacing24           // 24px
ILabaDesign.spacing32           // 32px

// Border Radius (px)
ILabaDesign.radius12            // 12px (buttons)
ILabaDesign.radius16            // 16px (cards) ⭐

// Font Sizes (px)
ILabaDesign.fontSize16          // 16px (body) ⭐
ILabaDesign.fontSize24          // 24px (titles) ⭐

// Helpers
ILabaDesign.primaryButtonStyle(context)    // Burgundy button
ILabaDesign.cardDecoration                 // White card + shadow
ILabaDesign.inputDecoration('Label')       // Input field styling
```

## Common Patterns

### Button (Burgundy)
```dart
ElevatedButton(
  style: ILabaDesign.primaryButtonStyle(context),
  onPressed: () {},
  child: const Text('Action'),
)
```

### Button (Outline)
```dart
OutlinedButton(
  style: ILabaDesign.secondaryButtonStyle(context),
  onPressed: () {},
  child: const Text('Cancel'),
)
```

### Card
```dart
Container(
  decoration: ILabaDesign.cardDecoration,
  padding: const EdgeInsets.all(ILabaDesign.spacing16),
  child: Text('Content'),
)
```

### Text
```dart
Text(
  'Heading',
  style: TextStyle(
    color: ILabaColors.darkText,
    fontSize: ILabaDesign.fontSize24,
    fontWeight: FontWeight.bold,
  ),
)
```

### Input
```dart
TextField(
  decoration: ILabaDesign.inputDecoration('Email'),
)
```

## Screen Template

```dart
import 'package:ilaba/constants/ilaba_colors.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ILabaColors.white,
      body: Padding(
        padding: const EdgeInsets.all(ILabaDesign.spacing16),
        child: Column(
          children: [
            // Heading
            Text(
              'Title',
              style: TextStyle(
                color: ILabaColors.darkText,
                fontSize: ILabaDesign.fontSize24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: ILabaDesign.spacing16),
            
            // Card
            Container(
              decoration: ILabaDesign.cardDecoration,
              padding: const EdgeInsets.all(ILabaDesign.spacing16),
              child: Text(
                'Content',
                style: TextStyle(
                  color: ILabaColors.lightText,
                  fontSize: ILabaDesign.fontSize14,
                ),
              ),
            ),
            const SizedBox(height: ILabaDesign.spacing24),
            
            // Button
            ElevatedButton(
              style: ILabaDesign.primaryButtonStyle(context),
              onPressed: () {},
              child: const Text('Action'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Migration Checklist

For each screen:
- [ ] Import `ilaba_colors.dart`
- [ ] Set background to `ILabaColors.white`
- [ ] Replace hardcoded colors with `ILabaColors.*`
- [ ] Use `ILabaDesign` for spacing/radius
- [ ] Update buttons to burgundy accent
- [ ] Use proper text colors (dark/medium/light)
- [ ] Add shadows to cards
- [ ] Test appearance

## Do's ✅

✅ Use `ILabaColors` for all colors
✅ Use `ILabaDesign` for spacing and sizes
✅ White backgrounds with burgundy accents
✅ Consistent text hierarchy (dark/medium/light)
✅ Soft shadows on cards
✅ Rounded corners (12-16px)

## Don'ts ❌

❌ Hardcode colors
❌ Use random spacing values
❌ Mix multiple colors (stick to white + burgundy)
❌ Create sharp corners
❌ Skip text hierarchy
❌ Overuse burgundy (use for accents only)

## Files

- **Colors**: `lib/constants/ilaba_colors.dart`
- **Guide**: `SIMPLE_COLOR_SCHEME_GUIDE.md`
- **Summary**: `SIMPLE_COLOR_SCHEME_SUMMARY.txt`

## Visual

```
Clean White Backgrounds
     +
Burgundy Accents
     =
Professional Minimalist Design
```

---

Ready to apply! Start with Home screen, then Booking flow screens.

