import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../models/migration_plan.dart';

Future<MigrationPlan> applyMigrationSSE(
  String url,
  void Function(String) onProgress,
) async {
  web.console.log('[SSE] applyMigrationSSE called, url=$url'.toJS);

  final headers = web.Headers();
  headers.set('Accept', 'text/event-stream');

  final response = await web.window
      .fetch(url.toJS, web.RequestInit(method: 'POST', headers: headers))
      .toDart;

  web.console.log('[SSE] fetch resolved, status=${response.status}'.toJS);

  if (!response.ok) {
    throw Exception('Apply migration failed (status ${response.status})');
  }

  final body = response.body;
  if (body == null) {
    throw Exception('Empty response body');
  }

  web.console.log('[SSE] got body, starting reader'.toJS);
  final reader = body.getReader() as web.ReadableStreamDefaultReader;
  final completer = Completer<MigrationPlan>();
  String? eventType;
  final dataBuffer = StringBuffer();
  var leftover = '';

  () async {
    final decoder = web.TextDecoder();
    try {
      var chunkCount = 0;
      while (true) {
        final result = await reader.read().toDart;
        if (result.done) {
          web.console.log('[SSE] stream done after $chunkCount chunks'.toJS);
          break;
        }
        chunkCount++;
        final value = result.value;
        if (value == null) continue;
        final chunk = decoder.decode(value as JSObject);
        web.console.log('[SSE] chunk #$chunkCount (${chunk.length} chars): ${chunk.substring(0, chunk.length > 120 ? 120 : chunk.length)}'.toJS);
        final combined = leftover + chunk;
        final parts = combined.split('\n');
        leftover = parts.removeLast();
        for (final line in parts) {
          _processLine(line, completer, onProgress, dataBuffer,
              () => eventType, (v) => eventType = v);
        }
      }
      if (leftover.isNotEmpty) {
        _processLine(leftover, completer, onProgress, dataBuffer,
            () => eventType, (v) => eventType = v);
      }
      if (!completer.isCompleted) {
        completer.completeError(Exception('Stream ended without result'));
      }
    } catch (e) {
      web.console.log('[SSE] error: $e'.toJS);
      if (!completer.isCompleted) completer.completeError(e);
    }
  }();

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
