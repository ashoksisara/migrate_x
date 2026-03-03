import 'package:flutter/material.dart';

const kPipelineCardWidth = 520.0;
const kPipelineCardHeight = 340.0;

class PipelineCard extends StatelessWidget {
  final Widget child;

  const PipelineCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: kPipelineCardWidth,
          maxWidth: kPipelineCardWidth,
          minHeight: kPipelineCardHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
