import 'dart:io';

import 'package:dotenv/dotenv.dart';

class Config {
  final int port;
  final String workspacePath;

  Config({required this.port, required this.workspacePath});

  factory Config.fromEnvironment({DotEnv? env}) {
    final portStr = env?['PORT'] ?? Platform.environment['PORT'];
    final port = int.tryParse(portStr ?? '') ?? 8080;

    final workspacePath =
        env?['WORKSPACE_PATH'] ?? Platform.environment['WORKSPACE_PATH'] ?? './workspace';

    return Config(port: port, workspacePath: workspacePath);
  }
}
