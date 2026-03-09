import 'dart:io';

import 'package:dotenv/dotenv.dart';

class Config {
  final int port;
  final String workspacePath;
  final String? anthropicApiKey;

  Config({
    required this.port,
    required this.workspacePath,
    this.anthropicApiKey,
  });

  factory Config.fromEnvironment({DotEnv? env}) {
    final portStr = env?['PORT'] ?? Platform.environment['PORT'];
    final port = int.tryParse(portStr ?? '') ?? 8080;

    final workspacePath =
        env?['WORKSPACE_PATH'] ?? Platform.environment['WORKSPACE_PATH'] ?? './workspace';

    final anthropicApiKey =
        env?['ANTHROPIC_API_KEY'] ?? Platform.environment['ANTHROPIC_API_KEY'];

    return Config(
      port: port,
      workspacePath: workspacePath,
      anthropicApiKey: anthropicApiKey,
    );
  }
}
