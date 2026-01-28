#!/usr/bin/env python3
import re
import sys

file_path = r'c:\Users\USER\AndroidStudioProjects\ilaba-app\lib\screens\mobile_booking\mobile_booking_baskets_step.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix the main color replacements carefully
replacements = [
    # Colors.white -> ILabaColors.white
    (r'\bColors\.white\b', 'ILabaColors.white'),
    # Colors.grey.shade50 -> ILabaColors.lightGray
    (r'\bColors\.grey\.shade50\b', 'ILabaColors.lightGray'),
    # Colors.grey.shade300 -> ILabaColors.border (or lightGray if it's a light gray)
    (r'\bColors\.grey\.shade300\b', 'ILabaColors.lightGray'),
    # Colors.grey.shade600 -> ILabaColors.lightText
    (r'\bColors\.grey\.shade600\b', 'ILabaColors.lightText'),
    # Colors.grey.shade700 -> ILabaColors.lightText
    (r'\bColors\.grey\.shade700\b', 'ILabaColors.lightText'),
    # Colors.grey.shade800 -> ILabaColors.darkText
    (r'\bColors\.grey\.shade800\b', 'ILabaColors.darkText'),
    # Colors.grey.shade900 -> ILabaColors.darkText
    (r'\bColors\.grey\.shade900\b', 'ILabaColors.darkText'),
    # Color(0xFFC41D7F) -> ILabaColors.burgundy (watch out for const prefix)
    (r'const Color\(0xFFC41D7F\)', 'ILabaColors.burgundy'),
    (r'Color\(0xFFC41D7F\)', 'ILabaColors.burgundy'),
    (r'const Color\(0xffC41D7F\)', 'ILabaColors.burgundy'),
    (r'Color\(0xffC41D7F\)', 'ILabaColors.burgundy'),
    # Color(0xFFA01560) -> ILabaColors.burgundyDark
    (r'const Color\(0xFFA01560\)', 'ILabaColors.burgundyDark'),
    (r'Color\(0xFFA01560\)', 'ILabaColors.burgundyDark'),
]

for pattern, replacement in replacements:
    content = re.sub(pattern, replacement, content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Replacements completed successfully")
