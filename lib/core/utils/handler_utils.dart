import 'dart:convert';
import 'package:shelf/shelf.dart';

/// Common utilities for request/response handling
class HandlerUtils {
  /// Parse JSON from request body
  static Future<Map<String, dynamic>> readJson(Request request) async {
    final body = await request.readAsString();
    if (body.isEmpty) return {};
    final dynamic decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  /// Create a JSON response handler
  static Handler jsonHandler(dynamic Function(Request) handler) {
    return (Request request) async {
      try {
        final result = await handler(request);
        if (result is Response) return result;

        return Response.ok(
          jsonEncode(result),
          headers: {'content-type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Internal server error', 'details': e.toString()}),
          headers: {'content-type': 'application/json'},
        );
      }
    };
  }

  /// Create a JSON response handler with request body parsing
  static Handler jsonHandlerWithBody(dynamic Function(Request, Map<String, dynamic>) handler) {
    return (Request request) async {
      try {
        final body = await readJson(request);
        final result = await handler(request, body);
        if (result is Response) return result;

        return Response.ok(
          jsonEncode(result),
          headers: {'content-type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Internal server error', 'details': e.toString()}),
          headers: {'content-type': 'application/json'},
        );
      }
    };
  }
}
