import 'package:shelf/shelf.dart';

Middleware requestLogger() {
  return (Handler innerHandler) {
    return (Request request) async {
      final stopwatch = Stopwatch()..start();
      final method = request.method;
      final path = request.requestedUri.path;

      Response response;
      try {
        response = await innerHandler(request);
      } catch (e) {
        stopwatch.stop();
        print('${_timestamp()} $method $path -> 500 (${stopwatch.elapsedMilliseconds}ms)');
        rethrow;
      }

      stopwatch.stop();
      print(
        '${_timestamp()} $method $path -> ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)',
      );
      return response;
    };
  };
}

String _timestamp() {
  final now = DateTime.now();
  return '[${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}:'
      '${now.second.toString().padLeft(2, '0')}]';
}
