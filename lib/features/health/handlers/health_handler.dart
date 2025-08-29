import 'package:shelf/shelf.dart';
import '../../../core/utils/handler_utils.dart';

/// Health check handler
class HealthHandler {
  /// Health check endpoint
  static Handler health() {
    return HandlerUtils.jsonHandler((Request request) {
      return {'status': 'ok', 'timestamp': DateTime.now().toIso8601String()};
    });
  }

  /// Version endpoint
  static Handler version() {
    return HandlerUtils.jsonHandler((Request request) {
      return {'version': '1.0.0', 'environment': 'mock'};
    });
  }
}
