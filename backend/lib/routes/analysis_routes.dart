import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../exceptions.dart';
import '../services/analyzer_service.dart';

Router analysisRoutes(AnalyzerService analyzerService) {
  final router = Router();

  router.get('/<id>', (Request request, String id) async {
    try {
      final issues = await analyzerService.analyze(id);
      final json = issues.map((i) => i.toJson()).toList();

      return Response.ok(
        jsonEncode({'issues': json}),
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
