# 🎨 ILABA Simple Color Scheme - White & Burgundy Red

## Overview

The ILABA app now uses a **simple, clean two-color palette**:
- **White** - Primary background
- **Burgundy Red** (#C41D7F) - Primary accent color

This creates a professional, minimalist aesthetic.

---

## Color Constants

**File**: `lib/constants/ilaba_colors.dart`

### Main Colors
```dart
ILabaColors.burgundy        // #C41D7F (Primary accent)
ILabaColors.burgundyDark    // #A01560 (Darker accent)
ILabaColors.white           // #FFFFFF (Primary background)
ILabaColors.lightGray       // #F5F5F5 (Light background)
```

### Text Colors
```dart
ILabaColors.darkText        // #1A1A1A (Headings, primary text)
ILabaColors.lightText       // #666666 (Secondary text)
ILabaColors.lightGrayText   // #AAAAAA (Hints, captions)
```

### Semantic Colors
```dart
ILabaColors.success         // #27AE60 (Green)
ILabaColors.warning         // #E67E22 (Orange)
ILabaColors.error           // #E74C3C (Red)
```

---

## How to Use

### 1. Import
```dart
import 'package:ilaba/constants/ilaba_colors.dart';
```

### 2. Use in Widgets

#### Text
```dart
Text(
  'Title',
  style: TextStyle(
    color: ILabaColors.darkText,
    fontSize: ILabaDesign.fontSize24,
    fontWeight: FontWeight.bold,
  ),
)
```

#### Buttons
```dart
ElevatedButton(
  style: ILabaDesign.primaryButtonStyle(context),
  onPressed: () {},
  child: const Text('Action'),
)

OutlinedButton(
  style: ILabaDesign.secondaryButtonStyle(context),
  onPressed: () {},
  child: const Text('Cancel'),
)
```

#### Input Fields
```dart
TextField(
  decoration: ILabaDesign.inputDecoration('Email Address'),
)
```

#### Cards
```dart
Container(
  decoration: ILabaDesign.cardDecoration,
  padding: const EdgeInsets.all(ILabaDesign.spacing16),
  child: YourContent(),
)
```

#### Backgrounds
```dart
Container(
  color: ILabaColors.white,
  child: YourContent(),
)
```

---

## Spacing System

Simple 4dp-based spacing for consistency:

```dart
spacing4    // 4px
spacing8    // 8px
spacing12   // 12px
spacing16   // 16px (⭐ Most common)
spacing20   // 20px
spacing24   // 24px
spacing32   // 32px
spacing40   // 40px
```

**Usage:**
```dart
Padding(
  padding: const EdgeInsets.all(ILabaDesign.spacing16),
  child: content,
)

SizedBox(height: ILabaDesign.spacing12)
```

---

## Border Radius

```dart
radius8     // 8px
radius12    // 12px (⭐ Buttons, inputs)
radius16    // 16px (⭐ Cards)
radius20    // 20px (Modals)
```

---

## Typography Sizes

```dart
fontSize10  // 10px (Tiny text)
fontSize12  // 12px (Captions)
fontSize14  // 14px (Labels)
fontSize16  // 16px (⭐ Body text)
fontSize18  // 18px
fontSize20  // 20px
fontSize24  // 24px (⭐ Titles)
fontSize28  // 28px (Headings)
fontSize32  // 32px (Large headings)
```

---

## Shadows

```dart
ILabaColors.softShadow      // Light shadow (cards)
ILabaColors.mediumShadow    // Medium shadow (buttons)
ILabaColors.strongShadow    // Strong shadow (modals)
```

**Usage:**
```dart
Container(
  decoration: BoxDecoration(
    color: ILabaColors.white,
    borderRadius: BorderRadius.circular(ILabaDesign.radius16),
    boxShadow: ILabaColors.softShadow,
  ),
)
```

---

## Application Guide

### For Each Screen

1. **Import colors**
   ```dart
   import 'package:ilaba/constants/ilaba_colors.dart';
   ```

2. **Set background to white**
   ```dart
   body: Container(
     color: ILabaColors.white,
     child: content,
   )
   ```

3. **Use burgundy for accents**
   - Primary buttons → burgundy
   - Links → burgundy
   - Icons (when prominent) → burgundy
   - Borders/dividers → light gray

4. **Use consistent text colors**
   - Headings → dark text
   - Body → light text
   - Hints → light gray text

5. **Use design spacing**
   - Standard padding → 16px
   - Section gaps → 24px
   - Card radius → 16px

---

## Common Patterns

### Primary Button
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: ILabaColors.burgundy,
    foregroundColor: ILabaColors.white,
    padding: const EdgeInsets.symmetric(
      horizontal: ILabaDesign.spacing24,
      vertical: ILabaDesign.spacing12,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ILabaDesign.radius12),
    ),
  ),
  onPressed: onPressed,
  child: const Text('Button'),
)
```

### Card
```dart
Container(
  decoration: ILabaDesign.cardDecoration,
  padding: const EdgeInsets.all(ILabaDesign.spacing16),
  child: content,
)
```

### List Item
```dart
Container(
  margin: const EdgeInsets.symmetric(vertical: ILabaDesign.spacing8),
  padding: const EdgeInsets.all(ILabaDesign.spacing16),
  decoration: BoxDecoration(
    color: ILabaColors.lightGray,
    borderRadius: BorderRadius.circular(ILabaDesign.radius12),
  ),
  child: content,
)
```

### Input Field
```dart
TextField(
  decoration: ILabaDesign.inputDecoration(
    'Email',
    hint: 'your@email.com',
    icon: Icons.email,
  ),
)
```

---

## Do's and Don'ts

### ✅ DO
- Use burgundy for primary actions and accents
- Use white/light gray for backgrounds
- Use dark text for headings, light text for body
- Use consistent spacing (multiples of 4)
- Use predefined border radius values
- Use design system shadows

### ❌ DON'T
- Hardcode colors (use `ILabaColors`)
- Use random spacing values
- Mix different shades of burgundy
- Add unnecessary gradients or effects
- Create sharp corners (use radius)
- Ignore text hierarchy

---

## Migration Checklist

For each screen you update:

- [ ] Replace hardcoded colors with `ILabaColors`
- [ ] Set backgrounds to `ILabaColors.white` or `ILabaColors.lightGray`
- [ ] Update buttons to use burgundy `ILabaColors.burgundy`
- [ ] Update text colors based on hierarchy
- [ ] Use spacing from `ILabaDesign`
- [ ] Use border radius from `ILabaDesign`
- [ ] Add shadows from `ILabaColors`
- [ ] Remove any gradients
- [ ] Test on white background
- [ ] Verify burgundy accents stand out

---

## Visual Results

**Before:** Complex gradient waves, multiple colors, inconsistent styling
**After:** Clean white backgrounds, burgundy accents, professional minimalist design

---

## Summary

A simple, professional two-color scheme:
- **White** backgrounds for clean, minimalist look
- **Burgundy red** accents for call-to-action
- **Grayscale** for text hierarchy
- **Consistent** spacing and typography
- **Professional** shadows and radius
- **Easy to maintain** - all colors in one file

**Status**: ✅ Ready to apply to all screens

