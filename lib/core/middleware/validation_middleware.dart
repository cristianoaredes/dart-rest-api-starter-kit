import 'dart:convert';
import 'package:shelf/shelf.dart';

/// Input validation middleware for production
class ValidationMiddleware {
  /// JSON body validation middleware
  static Middleware get jsonValidation {
    return (inner) => (Request request) async {
      try {
        // Only validate JSON for POST, PUT, PATCH requests
        if (['POST', 'PUT', 'PATCH'].contains(request.method)) {
          // Check if content-type is application/json
          final contentType = request.headers['content-type'];
          if (contentType == null || !contentType.contains('application/json')) {
            return Response(400, body: jsonEncode({
              'error': 'Bad Request',
              'message': 'Content-Type must be application/json',
              'timestamp': DateTime.now().toIso8601String(),
            }));
          }

          // Try to parse JSON to validate format
          try {
            final body = await request.readAsString();
            if (body.isNotEmpty) {
              jsonDecode(body);
            }
          } catch (e) {
            return Response(400, body: jsonEncode({
              'error': 'Bad Request',
              'message': 'Invalid JSON format',
              'timestamp': DateTime.now().toIso8601String(),
            }));
          }
        }

        return await inner(request);
      } catch (e) {
        return Response(500, body: jsonEncode({
          'error': 'Internal Server Error',
          'message': 'Validation middleware error',
          'timestamp': DateTime.now().toIso8601String(),
        }));
      }
    };
  }

  /// Request size limit middleware
  static Middleware maxBodySize(int maxSizeInBytes) {
    return (inner) => (Request request) async {
      try {
        // Check content-length header
        final contentLength = request.headers['content-length'];
        if (contentLength != null) {
          final size = int.tryParse(contentLength);
          if (size != null && size > maxSizeInBytes) {
            return Response(413, body: jsonEncode({
              'error': 'Payload Too Large',
              'message': 'Request body exceeds maximum size of ${maxSizeInBytes} bytes',
              'timestamp': DateTime.now().toIso8601String(),
            }));
          }
        }

        // For requests with body, check actual size
        if (['POST', 'PUT', 'PATCH'].contains(request.method)) {
          final body = await request.readAsString();
          if (body.length > maxSizeInBytes) {
            return Response(413, body: jsonEncode({
              'error': 'Payload Too Large',
              'message': 'Request body exceeds maximum size of ${maxSizeInBytes} bytes',
              'timestamp': DateTime.now().toIso8601String(),
            }));
          }
        }

        return await inner(request);
      } catch (e) {
        return Response(500, body: jsonEncode({
          'error': 'Internal Server Error',
          'message': 'Request size validation error',
          'timestamp': DateTime.now().toIso8601String(),
        }));
      }
    };
  }

  /// Required fields validation for specific endpoints
  static Middleware validateRequiredFields(List<String> requiredFields, {String? endpoint}) {
    return (inner) => (Request request) async {
      try {
        if (['POST', 'PUT', 'PATCH'].contains(request.method)) {
          final body = await request.readAsString();
          if (body.isNotEmpty) {
            final Map<String, dynamic> data = jsonDecode(body);

            final missingFields = requiredFields.where((field) {
              return !data.containsKey(field) ||
                     data[field] == null ||
                     (data[field] is String && (data[field] as String).isEmpty);
            }).toList();

            if (missingFields.isNotEmpty) {
              return Response(400, body: jsonEncode({
                'error': 'Bad Request',
                'message': 'Missing required fields: ${missingFields.join(', ')}',
                'missing_fields': missingFields,
                'endpoint': endpoint,
                'timestamp': DateTime.now().toIso8601String(),
              }));
            }
          }
        }

        return await inner(request);
      } catch (e) {
        return Response(500, body: jsonEncode({
          'error': 'Internal Server Error',
          'message': 'Field validation error',
          'timestamp': DateTime.now().toIso8601String(),
        }));
      }
    };
  }

  /// Email validation middleware
  static Middleware validateEmail(String emailField) {
    return (inner) => (Request request) async {
      try {
        if (['POST', 'PUT', 'PATCH'].contains(request.method)) {
          final body = await request.readAsString();
          if (body.isNotEmpty) {
            final Map<String, dynamic> data = jsonDecode(body);

            if (data.containsKey(emailField)) {
              final email = data[emailField]?.toString() ?? '';
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

              if (email.isNotEmpty && !emailRegex.hasMatch(email)) {
                return Response(400, body: jsonEncode({
                  'error': 'Bad Request',
                  'message': 'Invalid email format',
                  'field': emailField,
                  'timestamp': DateTime.now().toIso8601String(),
                }));
              }
            }
          }
        }

        return await inner(request);
      } catch (e) {
        return Response(500, body: jsonEncode({
          'error': 'Internal Server Error',
          'message': 'Email validation error',
          'timestamp': DateTime.now().toIso8601String(),
        }));
      }
    };
  }
}
