class PackageInfo {
  final String name;
  final String currentVersion;
  final String targetVersion;

  PackageInfo({
    required this.name,
    required this.currentVersion,
    required this.targetVersion,
  });

  factory PackageInfo.fromJson(Map<String, dynamic> json) {
    return PackageInfo(
      name: json['name'] as String,
      currentVersion: json['currentVersion'] as String,
      targetVersion: json['targetVersion'] as String,
    );
  }
}
