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

  Future<List<AnalyzerIssue>> analyze(String id) async {
    final projectDir = Directory(p.join(workspacePath, id));
    if (!await projectDir.exists()) {
      throw AppException(404, 'Workspace $id not found');
    }

    final result = await runExecutableArguments(
      'dart',
      ['analyze', '--format=machine'],
      workingDirectory: projectDir.path,
    );

    final issues = <AnalyzerIssue>[];
    final lines = result.stdout.toString().split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      // Machine format: SEVERITY|TYPE|ERROR_CODE|FILE|LINE|COL|LENGTH|MESSAGE
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
