import 'package:flutter/material.dart';
import 'package:ilaba/constants/ilaba_colors.dart';

class MenuCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onPressed;

  const MenuCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ILabaColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: ILabaColors.softShadow,
          border: Border.all(
            color: ILabaColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Left: Title and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ILabaColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: ILabaColors.lightText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right: Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ILabaColors.burgundy.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: ILabaColors.burgundy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
