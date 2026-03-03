import 'package:flutter/material.dart';

import '../models/analysis_result.dart';

class AnalysisCard extends StatelessWidget {
  final AnalysisResult result;

  const AnalysisCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _severityIcon(context),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${result.file}:${result.line}:${result.column}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _severityIcon(BuildContext context) {
    switch (result.severity.toUpperCase()) {
      case 'ERROR':
        return const Icon(Icons.error, color: Colors.red);
      case 'WARNING':
        return const Icon(Icons.warning_amber, color: Colors.orange);
      default:
        return const Icon(Icons.info_outline, color: Colors.blue);
    }
  }
}
