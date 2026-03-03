class AnalysisResult {
  final String severity;
  final String file;
  final int line;
  final int column;
  final String message;

  AnalysisResult({
    required this.severity,
    required this.file,
    required this.line,
    required this.column,
    required this.message,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      severity: json['severity'] as String,
      file: json['file'] as String,
      line: json['line'] as int,
      column: json['column'] as int,
      message: json['message'] as String,
    );
  }
}
