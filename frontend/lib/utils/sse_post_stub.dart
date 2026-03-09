import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/migration_plan.dart';

Future<MigrationPlan> applyMigrationSSE(
  String url,
  void Function(String) onProgress,
) async {
  final client = http.Client();
  final request = http.Request('POST', Uri.parse(url))
    ..headers['Accept'] = 'text/event-stream';
  final response = await client.send(request);

  if (response.statusCode != 200) {
    final body = await response.stream.bytesToString();
    throw Exception('Apply migration failed: $body');
  }

  final completer = Completer<MigrationPlan>();
  String? eventType;
  final dataBuffer = StringBuffer();

  response.stream
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(
        (line) => _processLine(line, completer, onProgress, dataBuffer,
            () => eventType, (v) => eventType = v),
        onError: (e) {
          if (!completer.isCompleted) completer.completeError(e);
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.completeError(Exception('Stream ended without result'));
          }
        },
      );

  return completer.future;
}

void _processLine(
  String line,
  Completer<MigrationPlan> completer,
  void Function(String) onProgress,
  StringBuffer dataBuffer,
  String? Function() getEventType,
  void Function(String?) setEventType,
) {
  if (line.startsWith('event:')) {
    setEventType(line.substring(6).trim());
  } else if (line.startsWith('data:')) {
    dataBuffer.writeln(line.substring(5));
  } else if (line.isEmpty && getEventType() != null && dataBuffer.isNotEmpty) {
    final data = dataBuffer.toString().trim();
    dataBuffer.clear();
    final eventType = getEventType();
    if (eventType == 'progress') {
      onProgress(data);
    } else if (eventType == 'complete') {
      if (!completer.isCompleted) {
        completer.complete(
          MigrationPlan.fromJson(jsonDecode(data) as Map<String, dynamic>),
        );
      }
    } else if (eventType == 'error') {
      if (!completer.isCompleted) {
        completer.completeError(Exception(data));
      }
    }
    setEventType(null);
  }
}
