import 'package:flutter/material.dart';

import '../models/migration_plan.dart';
import 'diff_viewer.dart';

class FileDiffCard extends StatefulWidget {
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
  State<FileDiffCard> createState() => _FileDiffCardState();
}

class _FileDiffCardState extends State<FileDiffCard> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAccepted = widget.decision == true;

    final oldLineCount = widget.diff.oldText.split('\n').length;
    final newLineCount = widget.diff.newText.split('\n').length;
    final added = (newLineCount - oldLineCount).clamp(0, 999999);
    final removed = (oldLineCount - newLineCount).clamp(0, 999999);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: widget.decision == null
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.5)
              : isAccepted
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _collapsed = !_collapsed),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.4),
              ),
              child: Row(
                children: [
                  Icon(
                    _collapsed
                        ? Icons.chevron_right
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.description_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.diff.filename,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (added > 0)
                    _changeBadge('+$added', const Color(0xFF2ea043)),
                  if (added > 0 && removed > 0) const SizedBox(width: 6),
                  if (removed > 0)
                    _changeBadge('-$removed', const Color(0xFFcf222e)),
                  if (widget.decision != null) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isAccepted
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAccepted ? Icons.check : Icons.close,
                            size: 13,
                            color: isAccepted
                                ? Colors.green.shade400
                                : Colors.red.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAccepted ? 'Accepted' : 'Declined',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isAccepted
                                  ? Colors.green.shade400
                                  : Colors.red.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!_collapsed) ...[
            DiffViewer(
                oldText: widget.diff.oldText, newText: widget.diff.newText),
            if (widget.decision == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: widget.onDecline,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: widget.onAccept,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _changeBadge(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 11.5,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }
}
