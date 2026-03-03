import 'package:flutter/material.dart';

import '../models/migration_plan.dart';
import 'diff_viewer.dart';

class FileDiffCard extends StatelessWidget {
  final FileDiff diff;
  final bool? decision;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const FileDiffCard({
    super.key,
    required this.diff,
    required this.decision,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final isAccepted = decision == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insert_drive_file_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  diff.filename,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ),
              if (decision != null)
                Chip(
                  label: Text(isAccepted ? 'Accepted' : 'Declined'),
                  avatar: Icon(
                    isAccepted ? Icons.check_circle : Icons.cancel,
                    size: 18,
                    color: isAccepted ? Colors.green : Colors.red,
                  ),
                  side: BorderSide.none,
                  backgroundColor: isAccepted
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                ),
            ],
          ),
          const SizedBox(height: 8),
          DiffViewer(oldText: diff.oldText, newText: diff.newText),
          if (decision == null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onDecline,
                  icon: const Icon(Icons.close),
                  label: const Text('Decline'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check),
                  label: const Text('Accept'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
