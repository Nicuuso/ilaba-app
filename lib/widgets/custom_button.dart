import 'package:flutter/material.dart';
import 'package:ilaba/constants/ilaba_colors.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final ButtonStyle? style;
  final bool isLoading;
  final double? width;
  final double? height;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style,
    this.isLoading = false,
    this.width,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        style:
            style ??
            ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 253, 132, 174),
              foregroundColor: ILabaColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(ILabaColors.white),
                ),
              )
            : Text(label),
      ),
    );
  }
}
