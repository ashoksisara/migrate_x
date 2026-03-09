import 'package:flutter/material.dart';

/// Common down-arrow button used to proceed to the next section.
class ProceedArrowButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ProceedArrowButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton.filled(
      onPressed: onPressed,
      icon: const Icon(Icons.keyboard_arrow_down, size: 32),
      style: IconButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
    );
  }
}
