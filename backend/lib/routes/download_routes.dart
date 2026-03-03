import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../exceptions.dart';
import '../services/zip_service.dart';

Router downloadRoutes(ZipService zipService) {
  final router = Router();

  router.get('/<id>', (Request request, String id) async {
    try {
      final zipBytes = await zipService.zip(id);

      return Response.ok(
        zipBytes,
        headers: {
          'Content-Type': 'application/zip',
          'Content-Disposition': 'attachment; filename="$id.zip"',
        },
      );
    } on AppException catch (e) {
      return Response(e.statusCode,
          body: jsonEncode({'error': e.message}),
          headers: {'Content-Type': 'application/json'});
    }
  });

  return router;
}
