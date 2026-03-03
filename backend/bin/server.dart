import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'package:migrate_x_backend/config.dart';
import 'package:migrate_x_backend/cors.dart';
import 'package:migrate_x_backend/logger.dart';
import 'package:migrate_x_backend/services/analyzer_service.dart';
import 'package:migrate_x_backend/services/migration_service.dart';
import 'package:migrate_x_backend/services/patch_service.dart';
import 'package:migrate_x_backend/services/zip_service.dart';
import 'package:migrate_x_backend/routes/upload_routes.dart';
import 'package:migrate_x_backend/routes/analysis_routes.dart';
import 'package:migrate_x_backend/routes/migration_routes.dart';
import 'package:migrate_x_backend/routes/download_routes.dart';

Future<void> main() async {
  DotEnv? env;
  if (File('.env').existsSync()) {
    env = DotEnv()..load(['.env']);
  }

  final config = Config.fromEnvironment(env: env);

  final workspaceDir = Directory(config.workspacePath);
  if (!await workspaceDir.exists()) {
    await workspaceDir.create(recursive: true);
  }

  final zipService = ZipService(config.workspacePath);
  final analyzerService = AnalyzerService(config.workspacePath);
  final patchService = PatchService();
  final migrationService = MigrationService(patchService);

  final router = Router()
    ..mount('/upload', uploadRoutes(zipService).call)
    ..mount('/analyze', analysisRoutes(analyzerService).call)
    ..mount('/migrate', migrationRoutes(migrationService).call)
    ..mount('/download', downloadRoutes(zipService).call);

  final handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(requestLogger())
      .addHandler(router.call);

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, config.port);
  server.autoCompress = true;

  print('Migrate X backend running at http://${server.address.host}:${server.port}');
}
