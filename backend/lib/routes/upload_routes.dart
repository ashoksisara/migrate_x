import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../exceptions.dart';
import '../services/zip_service.dart';

Router uploadRoutes(ZipService zipService) {
  final router = Router();
  final uuid = Uuid();

  router.post('/', (Request request) async {
    try {
      final multipart = request.multipart();
      if (multipart == null) {
        throw AppException(400, 'Expected a multipart request');
      }

      List<int>? fileBytes;
      await for (final part in multipart.parts) {
        final disposition = part.headers['content-disposition'] ?? '';
        if (disposition.contains('name="file"')) {
          fileBytes = await part.readBytes();
        }
      }

      if (fileBytes == null || fileBytes.isEmpty) {
        throw AppException(400, 'No zip file found in request');
      }

      final id = uuid.v4();
      print('[upload] extracting zip for $id (${fileBytes.length} bytes)');
      await zipService.extract(fileBytes, id);
      print('[upload] extracted to workspace/$id');

      return Response.ok(
        jsonEncode({'id': id}),
        headers: {'Content-Type': 'application/json'},
      );
    } on AppException catch (e) {
      print('[upload] failed: ${e.message}');
      return Response(e.statusCode,
          body: jsonEncode({'error': e.message}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print('[upload] error: $e');
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  });

  return router;
}
