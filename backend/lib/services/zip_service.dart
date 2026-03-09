import 'dart:convert';
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

  /// Zips the workspace. [overrides] maps project-relative paths to content.
  /// Used to revert declined files to original content. [projectSubdir] is
  /// the workspace subdir containing the project (e.g. 'my_app' or '' if root).
  Future<List<int>> zip(
    String id, {
    String projectSubdir = '',
    Map<String, String> overrides = const {},
  }) async {
    final sourceDir = Directory(p.join(workspacePath, id));
    if (!await sourceDir.exists()) {
      throw AppException(404, 'Workspace $id not found');
    }

    final archive = Archive();
    final entities = sourceDir.listSync(recursive: true);
    for (final entity in entities) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: sourceDir.path);
        String? overrideContent;
        if (overrides.isNotEmpty && projectSubdir.isNotEmpty) {
          if (relativePath == projectSubdir ||
              relativePath.startsWith('$projectSubdir/')) {
            final projectRel =
                relativePath == projectSubdir
                    ? ''
                    : relativePath.substring(projectSubdir.length + 1);
            overrideContent = overrides[projectRel];
          }
        } else if (overrides.isNotEmpty && projectSubdir.isEmpty) {
          overrideContent = overrides[relativePath];
        }
        final bytes = overrideContent != null
            ? utf8.encode(overrideContent)
            : await entity.readAsBytes();
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
