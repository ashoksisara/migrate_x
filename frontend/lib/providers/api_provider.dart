import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import '../services/mock_api_service.dart';

const _useMock = true;

final apiProvider = Provider<ApiService>((ref) {
  if (_useMock) return MockApiService();
  // TODO: Make base URL configurable via environment or settings
  return ApiService(baseUrl: 'http://localhost:8080');
});
