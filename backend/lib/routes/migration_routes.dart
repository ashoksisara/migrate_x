import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../exceptions.dart';
import '../services/migration_service.dart';

Router migrationRoutes(MigrationService migrationService) {
  final router = Router();

  router.get('/<id>', (Request request, String id) async {
    try {
      print('[migrate] generating migration plan for $id');
      final plan = await migrationService.generatePlan(id);
      print('[migrate] plan ready: ${plan.fileDiffs.length} file diffs');

      return Response.ok(
        jsonEncode(plan.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } on AppException catch (e) {
      print('[migrate] failed for $id: ${e.message}');
      return Response(e.statusCode,
          body: jsonEncode({'error': e.message}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print('[migrate] error for $id: $e');
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  });

  return router;
}
