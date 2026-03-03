import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../exceptions.dart';
import '../services/zip_service.dart';

Router downloadRoutes(ZipService zipService) {
  final router = Router();

  router.get('/<id>', (Request request, String id) async {
    try {
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
