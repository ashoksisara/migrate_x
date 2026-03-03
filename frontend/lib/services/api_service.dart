import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/analysis_result.dart';
import '../models/migration_plan.dart';

class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  Future<String> uploadZip(Uint8List bytes, String filename) async {
    final uri = Uri.parse('$baseUrl/upload');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ));

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception('Upload failed: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['id'] as String;
  }

  Future<void> resolveDependencies(String id) async {
    final uri = Uri.parse('$baseUrl/analyze/resolve/$id');
    final response = await _client.post(uri);

    if (response.statusCode != 200) {
      throw Exception('Dependency resolution failed: ${response.body}');
    }
  }

  Future<List<AnalysisResult>> getAnalysis(String id) async {
    final uri = Uri.parse('$baseUrl/analyze/$id');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Analysis failed: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final issues = json['issues'] as List<dynamic>;
    return issues
        .map((e) => AnalysisResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MigrationPlan> getMigrationPlan(String id) async {
    final uri = Uri.parse('$baseUrl/migrate/$id');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Migration failed: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return MigrationPlan.fromJson(json);
  }

  Future<Uint8List> downloadZip(String id) async {
    final uri = Uri.parse('$baseUrl/download/$id');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Download failed: ${response.body}');
    }

    return response.bodyBytes;
  }
}
