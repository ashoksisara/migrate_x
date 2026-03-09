import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../exceptions.dart';
import '../services/migration_service.dart';
import '../services/zip_service.dart';

Router uploadRoutes(ZipService zipService, MigrationService migrationService) {
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

      final workspaceDir =
          Directory(p.join(zipService.workspacePath, id));
      final pubspecFound = await _findPubspec(workspaceDir);
      if (!pubspecFound) {
        print('[upload] no pubspec.yaml found – cleaning up $id');
        await workspaceDir.delete(recursive: true);
        throw AppException(
            400, 'Not a valid Flutter/Dart project (pubspec.yaml not found)');
      }
      print('[upload] pubspec.yaml found for $id');

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

  router.delete('/<id>', (Request request, String id) async {
    try {
      print('[upload] deleting workspace $id');
      migrationService.clearBefore(id);
      await zipService.delete(id);
      print('[upload] workspace $id deleted');
      return Response.ok(
        jsonEncode({'status': 'ok'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('[upload] delete error for $id: $e');
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  });

  return router;
}

Future<bool> _findPubspec(Directory dir) async {
  if (await File(p.join(dir.path, 'pubspec.yaml')).exists()) return true;
  await for (final entity in dir.list()) {
    if (entity is Directory) {
      if (await File(p.join(entity.path, 'pubspec.yaml')).exists()) {
        return true;
      }
    }
  }
  return false;
}
