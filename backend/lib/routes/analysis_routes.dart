import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../exceptions.dart';
import '../services/analyzer_service.dart';

Router analysisRoutes(AnalyzerService analyzerService) {
  final router = Router();

  router.post('/resolve/<id>', (Request request, String id) async {
    try {
      print('[analyze] resolving dependencies for $id');
      await analyzerService.resolveDependencies(id);
      print('[analyze] dependencies resolved for $id');
      return Response.ok(
        jsonEncode({'status': 'ok'}),
        headers: {'Content-Type': 'application/json'},
      );
    } on AppException catch (e) {
      print('[analyze] resolve failed for $id: ${e.message}');
      return Response(e.statusCode,
          body: jsonEncode({'error': e.message}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print('[analyze] resolve error for $id: $e');
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  });

  router.get('/<id>', (Request request, String id) async {
    try {
      print('[analyze] running dart analyze for $id');
      final issues = await analyzerService.analyze(id);
      print('[analyze] found ${issues.length} issues for $id');
      final json = issues.map((i) => i.toJson()).toList();

      return Response.ok(
        jsonEncode({'issues': json}),
        headers: {'Content-Type': 'application/json'},
      );
    } on AppException catch (e) {
      print('[analyze] failed for $id: ${e.message}');
      return Response(e.statusCode,
          body: jsonEncode({'error': e.message}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print('[analyze] error for $id: $e');
      return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'});
    }
  });

  return router;
}
