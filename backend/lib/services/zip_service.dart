import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../exceptions.dart';

class ZipService {
  final String workspacePath;

  ZipService(this.workspacePath);

  Future<void> extract(List<int> zipBytes, String id) async {
    final outputDir = Directory(p.join(workspacePath, id));
    if (await outputDir.exists()) {
      await outputDir.delete(recursive: true);
    }
    await outputDir.create(recursive: true);

    final archive = ZipDecoder().decodeBytes(zipBytes);
    for (final entry in archive) {
      final filePath = p.join(outputDir.path, entry.name);
      if (entry.isFile) {
        final file = File(filePath);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.readBytes()!);
      } else {
        await Directory(filePath).create(recursive: true);
      }
    }
  }

  Future<List<int>> zip(String id) async {
    final sourceDir = Directory(p.join(workspacePath, id));
    if (!await sourceDir.exists()) {
      throw AppException(404, 'Workspace $id not found');
    }

    final archive = Archive();
    final entities = sourceDir.listSync(recursive: true);
    for (final entity in entities) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: sourceDir.path);
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      }
    }

    return ZipEncoder().encode(archive);
  }

  Future<void> delete(String id) async {
    final dir = Directory(p.join(workspacePath, id));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  String projectPath(String id) => p.join(workspacePath, id);
}
