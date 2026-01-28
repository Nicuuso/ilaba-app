#!/usr/bin/env python3
import re

files_to_update = [
    r'c:\Users\USER\AndroidStudioProjects\ilaba-app\lib\screens\mobile_booking\mobile_booking_products_step.dart',
    r'c:\Users\USER\AndroidStudioProjects\ilaba-app\lib\screens\mobile_booking\mobile_booking_handling_step.dart',
    r'c:\Users\USER\AndroidStudioProjects\ilaba-app\lib\screens\mobile_booking\mobile_booking_payment_step.dart',
]

replacements = [
    # Colors.white -> ILabaColors.white
    (r'\bColors\.white\b', 'ILabaColors.white'),
    # Colors.grey.shade50 -> ILabaColors.lightGray
    (r'\bColors\.grey\.shade50\b', 'ILabaColors.lightGray'),
    # Colors.grey.shade300 -> ILabaColors.lightGray
    (r'\bColors\.grey\.shade300\b', 'ILabaColors.lightGray'),
    # Colors.grey.shade600 -> ILabaColors.lightText
    (r'\bColors\.grey\.shade600\b', 'ILabaColors.lightText'),
    # Colors.grey.shade700 -> ILabaColors.lightText
    (r'\bColors\.grey\.shade700\b', 'ILabaColors.lightText'),
    # Colors.grey.shade800 -> ILabaColors.darkText
    (r'\bColors\.grey\.shade800\b', 'ILabaColors.darkText'),
    # Colors.grey.shade900 -> ILabaColors.darkText
    (r'\bColors\.grey\.shade900\b', 'ILabaColors.darkText'),
    # Color(0xFFC41D7F) -> ILabaColors.burgundy
    (r'const Color\(0xFFC41D7F\)', 'ILabaColors.burgundy'),
    (r'Color\(0xFFC41D7F\)', 'ILabaColors.burgundy'),
    (r'const Color\(0xffC41D7F\)', 'ILabaColors.burgundy'),
    (r'Color\(0xffC41D7F\)', 'ILabaColors.burgundy'),
    # Color(0xFFA01560) -> ILabaColors.burgundyDark
    (r'const Color\(0xFFA01560\)', 'ILabaColors.burgundyDark'),
    (r'Color\(0xFFA01560\)', 'ILabaColors.burgundyDark'),
]

for file_path in files_to_update:
    print(f"Processing {file_path.split(chr(92))[-1]}...")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Add import if not already there
    if "import 'package:ilaba/constants/ilaba_colors.dart';" not in content:
        # Find the last import statement
        last_import_match = None
        for match in re.finditer(r"^import .+;$", content, re.MULTILINE):
            last_import_match = match
        
        if last_import_match:
            insert_pos = last_import_match.end()
            content = content[:insert_pos] + "\nimport 'package:ilaba/constants/ilaba_colors.dart';" + content[insert_pos:]
    
    # Apply color replacements
    for pattern, replacement in replacements:
        content = re.sub(pattern, replacement, content)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"  ✓ Updated successfully")

print("\nAll files updated!")
