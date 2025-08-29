import 'dart:convert';
import 'package:shelf/shelf.dart';

/// Production-ready error handling middleware
class ErrorHandlingMiddleware {
  /// Global error handling middleware
  static Middleware get errorHandler {
    return (inner) => (Request request) async {
      try {
        final response = await inner(request);
        return response;
      } catch (e, stackTrace) {
        // Log the error (in production, use a proper logging service)
        print('Error processing request: $e');
        print('Stack trace: $stackTrace');

        // Return appropriate error response based on error type
        if (e is FormatException) {
          return Response(400, body: jsonEncode({
            'error': 'Bad Request',
            'message': 'Invalid JSON format',
            'timestamp': DateTime.now().toIso8601String(),
          }));
        } else if (e is ArgumentError) {
          return Response(400, body: jsonEncode({
            'error': 'Bad Request',
            'message': e.message,
            'timestamp': DateTime.now().toIso8601String(),
          }));
        } else if (e is UnsupportedError) {
          return Response(501, body: jsonEncode({
            'error': 'Not Implemented',
            'message': 'Feature not implemented',
            'timestamp': DateTime.now().toIso8601String(),
          }));
        } else {
          // Generic server error
          return Response(500, body: jsonEncode({
            'error': 'Internal Server Error',
            'message': 'An unexpected error occurred',
            'timestamp': DateTime.now().toIso8601String(),
          }));
        }
      }
    };
  }

  /// Validation error handler
  static Response validationError(String message, [Map<String, dynamic>? details]) {
    return Response(422, body: jsonEncode({
      'error': 'Validation Error',
      'message': message,
      'details': details,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }

  /// Not found error handler
  static Response notFound(String resource) {
    return Response(404, body: jsonEncode({
      'error': 'Not Found',
      'message': '$resource not found',
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }

  /// Forbidden error handler
  static Response forbidden(String message) {
    return Response(403, body: jsonEncode({
      'error': 'Forbidden',
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }

  /// Conflict error handler
  static Response conflict(String message) {
    return Response(409, body: jsonEncode({
      'error': 'Conflict',
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }
}
