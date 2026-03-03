class FixSuggestion {
  final String file;
  final String fixName;
  final int count;

  FixSuggestion({
    required this.file,
    required this.fixName,
    required this.count,
  });

  factory FixSuggestion.fromJson(Map<String, dynamic> json) {
    return FixSuggestion(
      file: json['file'] as String,
      fixName: json['fixName'] as String,
      count: json['count'] as int,
    );
  }
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

  factory DryRunResult.fromJson(Map<String, dynamic> json) {
    final suggestions = (json['suggestions'] as List<dynamic>)
        .map((e) => FixSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
    return DryRunResult(
      suggestions: suggestions,
      totalFixes: json['totalFixes'] as int,
      totalFiles: json['totalFiles'] as int,
    );
  }
}
