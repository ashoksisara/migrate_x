import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pipeline_provider.dart';

class UploadButton extends ConsumerWidget {
  const UploadButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = ref.watch(pipelineProvider.select((s) => s.stage));
    final busy = stage == PipelineStage.uploading;

    return FilledButton.icon(
      onPressed: busy ? null : () => _pickAndUpload(ref),
      icon: const Icon(Icons.folder_zip_outlined),
      label: Text(busy ? 'Uploading...' : 'Select .zip File'),
    );
  }

  Future<void> _pickAndUpload(WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    ref.read(pipelineProvider.notifier).upload(file.bytes!, file.name);
  }
}
