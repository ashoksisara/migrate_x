import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/analysis_result.dart';

class AnalysisCard extends StatelessWidget {
  final AnalysisResult result;

  const AnalysisCard({super.key, required this.result});

  String get _relativePath {
    final raw = result.file;
    final markers = ['lib/', 'test/', 'bin/', 'web/', 'example/', 'tool/'];
    for (final m in markers) {
      final idx = raw.indexOf(m);
      if (idx != -1) return raw.substring(idx);
    }
    final segments = raw.split('/');
    return segments.length > 2
        ? segments.sublist(segments.length - 2).join('/')
        : segments.last;
  }

  String get _location => '$_relativePath:${result.line}:${result.column}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _severityIcon(),
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _location,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontFamily: 'monospace',
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () =>
                            Clipboard.setData(ClipboardData(text: _location)),
                        child: Icon(Icons.copy,
                            size: 13, color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _severityIcon() {
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
