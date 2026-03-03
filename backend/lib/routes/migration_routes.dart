import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../exceptions.dart';
import '../services/migration_service.dart';

Router migrationRoutes(MigrationService migrationService) {
  final router = Router();

  router.get('/<id>', (Request request, String id) async {
    try {
      final plan = await migrationService.generatePlan(id);

      return Response.ok(
        jsonEncode(plan.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } on AppException catch (e) {
      return Response(e.statusCode,
          body: jsonEncode({'error': e.message}),
          headers: {'Content-Type': 'application/json'});
    }
  });

  return router;
}
