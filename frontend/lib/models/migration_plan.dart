class FileDiff {
  final String filename;
  final String oldText;
  final String newText;

  FileDiff({
    required this.filename,
    required this.oldText,
    required this.newText,
  });

  factory FileDiff.fromJson(Map<String, dynamic> json) {
    return FileDiff(
      filename: json['filename'] as String,
      oldText: json['oldText'] as String,
      newText: json['newText'] as String,
    );
  }
}

class MigrationPlan {
  final String summary;
  final List<FileDiff> fileDiffs;

  MigrationPlan({
    required this.summary,
    required this.fileDiffs,
  });

  factory MigrationPlan.fromJson(Map<String, dynamic> json) {
    final diffs = (json['fileDiffs'] as List<dynamic>)
        .map((e) => FileDiff.fromJson(e as Map<String, dynamic>))
        .toList();
    return MigrationPlan(
      summary: json['summary'] as String,
      fileDiffs: diffs,
    );
  }
}
