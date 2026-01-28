#!/usr/bin/env python3
import re
import os
import glob

# Find all dart files in screens folder, excluding tests
patterns = [
    r'c:\Users\USER\AndroidStudioProjects\ilaba-app\lib\screens\**\*.dart',
]

files_to_update = set()
for pattern in patterns:
    for file_path in glob.glob(pattern, recursive=True):
        if 'test' not in file_path and file_path not in files_to_update:
            files_to_update.add(file_path)

# Exclude files already done
already_done = {
    r'c:\Users\USER\AndroidStudioProjects\ilaba-app\lib\screens\mobile_booking\mobile_booking_baskets_step.dart',
    r'c:\Users\USER\AndroidStudioProjects\ilaba-app\lib\screens\mobile_booking\order_summary_expandable.dart',
    r'c:\Users\USER\AndroidStudioProjects\ilaba-app\lib\screens\mobile_booking\mobile_booking_products_step.dart',
    r'c:\Users\USER\AndroidStudioProjects\ilaba-app\lib\screens\mobile_booking\mobile_booking_handling_step.dart',
    r'c:\Users\USER\AndroidStudioProjects\ilaba-app\lib\screens\mobile_booking\mobile_booking_payment_step.dart',
    r'c:\Users\USER\AndroidStudioProjects\ilaba-app\lib\screens\mobile_booking\mobile_booking_flow_screen.dart',
    r'c:\Users\USER\AndroidStudioProjects\ilaba-app\lib\screens\mobile_booking\mobile_booking_success_screen.dart',
    r'c:\Users\USER\AndroidStudioProjects\ilaba-app\lib\screens\navigation\home_menu_screen.dart',
    r'c:\Users\USER\AndroidStudioProjects\ilaba-app\lib\screens\navigation\menu_side_screen.dart',
    r'c:\Users\USER\AndroidStudioProjects\ilaba-app\lib\screens\login_screen.dart',
    r'c:\Users\USER\AndroidStudioProjects\ilaba-app\lib\widgets\menu_card.dart',
}

files_to_update = files_to_update - already_done

replacements = [
    # Colors.white -> ILabaColors.white
    (r'\bColors\.white\b', 'ILabaColors.white'),
    # Colors.black -> ILabaColors.darkText or similar
    (r'\bColors\.black\b', 'ILabaColors.darkText'),
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

print(f"Found {len(files_to_update)} files to update\n")

updated_count = 0
for file_path in sorted(files_to_update):
    if not os.path.exists(file_path):
        continue
    
    rel_path = file_path.replace(r'c:\Users\USER\AndroidStudioProjects\ilaba-app\lib\screens\\', '')
    print(f"Processing {rel_path}...", end=' ')
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
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
        
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print("✓ Updated")
            updated_count += 1
        else:
            print("No changes needed")
    except Exception as e:
        print(f"✗ Error: {e}")

print(f"\n✓ Successfully updated {updated_count} files!")
