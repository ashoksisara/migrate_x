import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../exceptions.dart';
import '../services/migration_service.dart';
import '../services/zip_service.dart';

Router downloadRoutes(ZipService zipService, MigrationService migrationService) {
  final router = Router();

  router.post('/<id>', (Request request, String id) async {
    try {
      // TODO: Accept/decline - re-enable when needed
      // List<String> declinedFiles = [];
      // final body = await request.readAsString();
      // if (body.isNotEmpty) {
      //   try {
      //     final json = jsonDecode(body) as Map<String, dynamic>;
      //     final list = json['declinedFiles'];
      //     if (list is List) {
      //       declinedFiles =
      //           list.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
      //     }
      //   } catch (_) {}
      // }
      // final before = migrationService.getBefore(id);
      // String projectSubdir = '';
      // Map<String, String> overrides = {};
      // if (before != null && declinedFiles.isNotEmpty) {
      //   projectSubdir = before.projectSubdir;
      //   for (final path in declinedFiles) {
      //     final content = before.before[path];
      //     if (content != null) overrides[path] = content;
      //   }
      // }

      print('[download] zipping workspace $id');
      final zipBytes = await zipService.zip(id);
      print('[download] zip ready (${zipBytes.length} bytes)');

      return Response.ok(
        zipBytes,
        headers: {
          'Content-Type': 'application/zip',
          'Content-Disposition': 'attachment; filename="$id.zip"',
        },
      );
    } on AppException catch (e) {
      print('[download] failed for $id: ${e.message}');
      return Response(e.statusCode,
          body: jsonEncode({'error': e.message}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print('[download] error for $id: $e');
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  });

  return router;
}
