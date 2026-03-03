import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:process_run/process_run.dart';

import '../exceptions.dart';
import 'patch_service.dart';

class FixSuggestion {
  final String file;
  final String fixName;
  final int count;

  FixSuggestion({
    required this.file,
    required this.fixName,
    required this.count,
  });

  Map<String, dynamic> toJson() => {
        'file': file,
        'fixName': fixName,
        'count': count,
      };
}

class DryRunResult {
  final List<FixSuggestion> suggestions;
  final int totalFixes;
  final int totalFiles;

  DryRunResult({
    required this.suggestions,
    required this.totalFixes,
    required this.totalFiles,
  });

  Map<String, dynamic> toJson() => {
        'suggestions': suggestions.map((s) => s.toJson()).toList(),
        'totalFixes': totalFixes,
        'totalFiles': totalFiles,
      };
}

class MigrationPlanResult {
  final String summary;
  final List<FileDiff> fileDiffs;

  MigrationPlanResult({required this.summary, required this.fileDiffs});

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'fileDiffs': fileDiffs.map((d) => d.toJson()).toList(),
      };
}

class MigrationService {
  final String workspacePath;

  MigrationService(this.workspacePath);

  Future<Directory> _findFlutterRoot(String id) async {
    final workspaceDir = Directory(p.join(workspacePath, id));
    if (!await workspaceDir.exists()) {
      throw AppException(404, 'Workspace $id not found');
    }

    if (await File(p.join(workspaceDir.path, 'pubspec.yaml')).exists()) {
      return workspaceDir;
    }

    await for (final entity in workspaceDir.list()) {
      if (entity is Directory) {
        if (await File(p.join(entity.path, 'pubspec.yaml')).exists()) {
          return entity;
        }
      }
    }

    throw AppException(400, 'No Flutter/Dart project found in workspace $id');
  }

  Future<DryRunResult> dryRun(String id) async {
    final projectDir = await _findFlutterRoot(id);
    print('  -> dart fix --dry-run in ${projectDir.path}');

    final result = await runExecutableArguments(
      'dart',
      ['fix', '--dry-run'],
      workingDirectory: projectDir.path,
    );
    print('  -> dart fix --dry-run exited with ${result.exitCode}');

    final output = result.stdout.toString();
    return _parseDryRunOutput(output, projectDir.path);
  }

  DryRunResult _parseDryRunOutput(String output, String projectRoot) {
    final suggestions = <FixSuggestion>[];
    String? currentFile;
    final lines = output.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      if (!line.startsWith(' ') && line.trimRight().endsWith('.dart')) {
        currentFile = _toRelativePath(line.trim(), projectRoot);
        continue;
      }

      if (currentFile != null && line.startsWith('  ')) {
        final match =
            RegExp(r'^\s+(\S+)\s+[•·-]\s+(\d+)\s+fix').firstMatch(line);
        if (match != null) {
          suggestions.add(FixSuggestion(
            file: currentFile,
            fixName: match.group(1)!,
            count: int.parse(match.group(2)!),
          ));
        }
      }
    }

    final totalFixes =
        suggestions.fold<int>(0, (sum, s) => sum + s.count);
    final totalFiles =
        suggestions.map((s) => s.file).toSet().length;

    return DryRunResult(
      suggestions: suggestions,
      totalFixes: totalFixes,
      totalFiles: totalFiles,
    );
  }

  String _toRelativePath(String path, String projectRoot) {
    if (p.isAbsolute(path)) {
      return p.relative(path, from: projectRoot);
    }
    return path;
  }

  Future<MigrationPlanResult> applyFixes(String id) async {
    final projectDir = await _findFlutterRoot(id);

    final dartFiles = await _collectDartFiles(projectDir.path);
    final before = <String, String>{};
    for (final file in dartFiles) {
      final rel = p.relative(file.path, from: projectDir.path);
      before[rel] = await file.readAsString();
    }

    print('  -> dart fix --apply in ${projectDir.path}');
    final result = await runExecutableArguments(
      'dart',
      ['fix', '--apply'],
      workingDirectory: projectDir.path,
    );
    print('  -> dart fix --apply exited with ${result.exitCode}');

    final diffs = <FileDiff>[];
    final afterFiles = await _collectDartFiles(projectDir.path);
    for (final file in afterFiles) {
      final rel = p.relative(file.path, from: projectDir.path);
      final newText = await file.readAsString();
      final oldText = before[rel];
      if (oldText != null && oldText != newText) {
        diffs.add(FileDiff(filename: rel, oldText: oldText, newText: newText));
      }
    }

    print('  -> ${diffs.length} file(s) changed after dart fix --apply');

    return MigrationPlanResult(
      summary: '${diffs.length} file(s) updated by dart fix --apply.',
      fileDiffs: diffs,
    );
  }

  Future<List<File>> _collectDartFiles(String root) async {
    final files = <File>[];
    await for (final entity
        in Directory(root).list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final rel = p.relative(entity.path, from: root);
        if (!rel.startsWith('.dart_tool') && !rel.startsWith('build')) {
          files.add(entity);
        }
      }
    }
    return files;
  }
}
