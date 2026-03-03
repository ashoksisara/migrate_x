import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../exceptions.dart';
import '../services/migration_service.dart';

Router migrationRoutes(MigrationService migrationService) {
  final router = Router();

  router.post('/dry-run/<id>', (Request request, String id) async {
    try {
      print('[migrate] running dart fix --dry-run for $id');
      final result = await migrationService.dryRun(id);
      print(
          '[migrate] dry-run done: ${result.totalFixes} fixes in ${result.totalFiles} files');

      return Response.ok(
        jsonEncode(result.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } on AppException catch (e) {
      print('[migrate] dry-run failed for $id: ${e.message}');
      return Response(e.statusCode,
          body: jsonEncode({'error': e.message}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print('[migrate] dry-run error for $id: $e');
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  });

  router.post('/apply/<id>', (Request request, String id) async {
    try {
      print('[migrate] applying dart fix for $id');
      final plan = await migrationService.applyFixes(id);
      print('[migrate] apply done: ${plan.fileDiffs.length} file diffs');

      return Response.ok(
        jsonEncode(plan.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } on AppException catch (e) {
      print('[migrate] apply failed for $id: ${e.message}');
      return Response(e.statusCode,
          body: jsonEncode({'error': e.message}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print('[migrate] apply error for $id: $e');
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  });

  return router;
}
