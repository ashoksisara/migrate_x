import 'package:flutter/material.dart';
import 'package:pretty_diff_text/pretty_diff_text.dart';

class DiffViewer extends StatelessWidget {
  final String oldText;
  final String newText;

  const DiffViewer({
    super.key,
    required this.oldText,
    required this.newText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: PrettyDiffText(
            oldText: oldText,
            newText: newText,
            defaultTextStyle: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            addedTextStyle: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Colors.green.shade800,
              backgroundColor: Colors.green.shade50,
            ),
            deletedTextStyle: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Colors.red.shade800,
              backgroundColor: Colors.red.shade50,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ),
      ),
    );
  }
}
