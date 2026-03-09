import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../exceptions.dart';
import '../services/migration_service.dart';

String _sseData(String s) => s.split('\n').map((l) => 'data: $l').join('\n');

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
    final streamed = request.headers['accept']?.contains('text/event-stream') ??
        false;
    if (streamed) {
      return _streamApply(migrationService, id);
    }
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

Future<Response> _streamApply(MigrationService migrationService, String id) async {
  final controller = StreamController<List<int>>();
  final utf8Stream = controller.stream;

  void emit(String event, String data) {
    final payload = 'event: $event\n${_sseData(data)}\n\n';
    controller.add(utf8.encode(payload));
  }

  unawaited(() async {
    try {
      print('[migrate] applying dart fix (stream) for $id');
      final plan = await migrationService.applyFixes(id,
          onProgress: (line) => emit('progress', line));
      print('[migrate] apply done: ${plan.fileDiffs.length} file diffs');
      emit('complete', jsonEncode(plan.toJson()));
    } on AppException catch (e) {
      print('[migrate] apply failed for $id: ${e.message}');
      emit('error', e.message);
    } catch (e) {
      print('[migrate] apply error for $id: $e');
      emit('error', e.toString());
    } finally {
      await controller.close();
    }
  }());

  return Response.ok(
    utf8Stream,
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'Content-Encoding': 'identity',
    },
  );
}
