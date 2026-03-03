import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/api_provider.dart';

class DownloadButton extends ConsumerStatefulWidget {
  final String workspaceId;
  final VoidCallback? onStartOver;
  const DownloadButton({
    super.key,
    required this.workspaceId,
    this.onStartOver,
  });

  @override
  ConsumerState<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends ConsumerState<DownloadButton> {
  bool _downloading = false;
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.check),
            label: const Text('Download Complete'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: widget.onStartOver,
            icon: const Icon(Icons.refresh),
            label: const Text('Start Over'),
          ),
        ],
      );
    }

    return FilledButton.icon(
      onPressed: _downloading ? null : _download,
      icon: _downloading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download),
      label: Text(_downloading ? 'Preparing...' : 'Download Migrated Zip'),
    );
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final api = ref.read(apiProvider);
      await api.downloadZip(widget.workspaceId);
      // TODO: Trigger browser file save with the returned bytes
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted && !_done) setState(() => _downloading = false);
    }
  }
}
