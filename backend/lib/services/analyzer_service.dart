import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:process_run/process_run.dart';

import '../exceptions.dart';

class AnalyzerIssue {
  final String severity;
  final String file;
  final int line;
  final int column;
  final String message;

  AnalyzerIssue({
    required this.severity,
    required this.file,
    required this.line,
    required this.column,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        'severity': severity,
        'file': file,
        'line': line,
        'column': column,
        'message': message,
      };
}

class AnalyzerService {
  final String workspacePath;

  AnalyzerService(this.workspacePath);

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
        final pubspec = File(p.join(entity.path, 'pubspec.yaml'));
        if (await pubspec.exists()) {
          return entity;
        }
      }
    }

    throw AppException(400, 'No Flutter/Dart project found in workspace $id');
  }

  Future<void> resolveDependencies(String id) async {
    final projectDir = await _findFlutterRoot(id);
    print('  -> flutter pub get in ${projectDir.path}');
    final result = await runExecutableArguments(
      'flutter',
      ['pub', 'get'],
      workingDirectory: projectDir.path,
    );
    print('  -> flutter pub get exited with ${result.exitCode}');
    if (result.exitCode != 0) {
      print('  -> stderr: ${result.stderr}');
    }
  }

  Future<List<AnalyzerIssue>> analyze(String id) async {
    final projectDir = await _findFlutterRoot(id);
    print('  -> dart analyze --format=machine in ${projectDir.path}');
    final result = await runExecutableArguments(
      'dart',
      ['analyze', '--format=machine'],
      workingDirectory: projectDir.path,
    );
    print('  -> dart analyze exited with ${result.exitCode}');

    final issues = <AnalyzerIssue>[];
    final lines = result.stdout.toString().split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final parts = line.split('|');
      if (parts.length >= 8) {
        issues.add(AnalyzerIssue(
          severity: parts[0],
          file: parts[3],
          line: int.tryParse(parts[4]) ?? 0,
          column: int.tryParse(parts[5]) ?? 0,
          message: parts[7],
        ));
      }
    }

    return issues;
  }
}
