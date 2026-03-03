import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/dry_run_result.dart';

class MigrationFixCard extends StatelessWidget {
  final FixSuggestion suggestion;

  const MigrationFixCard({super.key, required this.suggestion});

  String get _relativePath {
    final raw = suggestion.file;
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final location = '$_relativePath';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.build_outlined, color: Colors.teal, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.fixName,
                    style: text.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          location,
                          style: text.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () =>
                            Clipboard.setData(ClipboardData(text: location)),
                        child: Icon(Icons.copy,
                            size: 13, color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${suggestion.count} fix${suggestion.count == 1 ? '' : 'es'}',
                style: text.labelSmall?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
