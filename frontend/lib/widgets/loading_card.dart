import 'package:flutter/material.dart';

import 'pipeline_card.dart';

class LoadingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const LoadingCard({
    super.key,
    this.icon = Icons.auto_fix_high_outlined,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return PipelineCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }
}
