import 'package:flutter/material.dart';

import 'pipeline_card.dart';

class LoadingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? progressMessage;

  const LoadingCard({
    super.key,
    this.icon = Icons.auto_fix_high_outlined,
    required this.title,
    required this.subtitle,
    this.progressMessage,
  });

  @override
  Widget build(BuildContext context) {
    final message = progressMessage ?? subtitle;
    return PipelineCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              message,
              key: ValueKey(message),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }
}
