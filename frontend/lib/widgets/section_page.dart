import 'package:flutter/material.dart';

class SectionPage extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const SectionPage({
    super.key,
    required this.child,
    this.maxWidth = 560,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
