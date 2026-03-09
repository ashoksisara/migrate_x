import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'package:migrate_x_backend/config.dart';
import 'package:migrate_x_backend/cors.dart';
import 'package:migrate_x_backend/logger.dart';
import 'package:migrate_x_backend/services/agent_service.dart';
import 'package:migrate_x_backend/services/analyzer_service.dart';
import 'package:migrate_x_backend/services/migration_service.dart';
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

  AgentService? agentService;
  if (config.anthropicApiKey != null && config.anthropicApiKey!.isNotEmpty) {
    agentService = AgentService(apiKey: config.anthropicApiKey!);
    print('Claude agent enabled (API key configured)');
  } else {
    print('Claude agent disabled (no ANTHROPIC_API_KEY)');
  }

  final zipService = ZipService(config.workspacePath);
  final analyzerService = AnalyzerService(config.workspacePath);
  final migrationService =
      MigrationService(config.workspacePath, agentService: agentService);

  final router = Router()
    ..mount('/upload', uploadRoutes(zipService, migrationService).call)
    ..mount('/analyze', analysisRoutes(analyzerService).call)
    ..mount('/migrate', migrationRoutes(migrationService).call)
    ..mount('/download', downloadRoutes(zipService, migrationService).call);

  final handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(requestLogger())
      .addHandler(router.call);

  final server = await HttpServer.bind(InternetAddress.anyIPv4, config.port);
  server.autoCompress = true;

  server.listen((HttpRequest request) async {
    if (request.headers.value('accept')?.contains('text/event-stream') == true) {
      request.response.bufferOutput = false;
    }
    await shelf_io.handleRequest(request, handler);
  });

  print('Migrate X backend running at http://${server.address.host}:${server.port}');
}
