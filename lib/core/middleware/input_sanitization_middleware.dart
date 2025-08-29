import 'dart:convert';
import 'package:shelf/shelf.dart';

/// Input sanitization and XSS protection middleware
class InputSanitizationMiddleware {
  /// Sanitize HTML input to prevent XSS attacks
  static String _sanitizeHtml(String input) {
    // Remove potentially dangerous HTML tags and attributes
    final dangerousTags = [
      'script', 'iframe', 'object', 'embed', 'form', 'input', 'button',
      'link', 'meta', 'style', 'javascript:', 'data:', 'vbscript:'
    ];

    final dangerousAttributes = [
      'onclick', 'onload', 'onerror', 'onmouseover', 'onmouseout',
      'onkeydown', 'onkeyup', 'onkeypress', 'onsubmit', 'onchange',
      'javascript:', 'data:', 'vbscript:'
    ];

    String sanitized = input;

    // Remove dangerous tags
    for (final tag in dangerousTags) {
      final tagRegex = RegExp('<$tag[^>]*>.*?</$tag>', caseSensitive: false);
      sanitized = sanitized.replaceAll(tagRegex, '');

      final selfClosingRegex = RegExp('<$tag[^>]*/>', caseSensitive: false);
      sanitized = sanitized.replaceAll(selfClosingRegex, '');
    }

    // Remove dangerous attributes
    for (final attr in dangerousAttributes) {
      final attrRegex = RegExp('$attr\\s*=\\s*["\'][^"\']*["\']', caseSensitive: false);
      sanitized = sanitized.replaceAll(attrRegex, '');
    }

    // Remove javascript: and data: URLs
    sanitized = sanitized.replaceAll(RegExp(r'javascript:[^"\s]*', caseSensitive: false), '');
    sanitized = sanitized.replaceAll(RegExp(r'data:[^"\s]*', caseSensitive: false), '');
    sanitized = sanitized.replaceAll(RegExp(r'vbscript:[^"\s]*', caseSensitive: false), '');

    return sanitized;
  }

  /// Sanitize SQL injection attempts (basic protection)
  static String _sanitizeSql(String input) {
    // Remove common SQL injection patterns
    final sqlPatterns = [
      RegExp(r';\s*drop\s+table', caseSensitive: false),
      RegExp(r';\s*delete\s+from', caseSensitive: false),
      RegExp(r';\s*update.*set', caseSensitive: false),
      RegExp(r'union\s+select', caseSensitive: false),
      RegExp(r'--\s*$', multiLine: true),
      RegExp(r'/\*.*?\*/', dotAll: true),
    ];

    String sanitized = input;
    for (final pattern in sqlPatterns) {
      sanitized = sanitized.replaceAll(pattern, '');
    }

    return sanitized;
  }

  /// General input sanitization middleware
  static Middleware get sanitizeInput {
    return (inner) => (Request request) async {
      try {
        // Only sanitize for methods that accept body
        if (['POST', 'PUT', 'PATCH'].contains(request.method)) {
          final contentType = request.headers['content-type'];

          if (contentType != null && contentType.contains('application/json')) {
            final body = await request.readAsString();

            if (body.isNotEmpty) {
              Map<String, dynamic> data = jsonDecode(body);
              data = _sanitizeMap(data);

              // Create new request with sanitized body
              final sanitizedBody = jsonEncode(data);
              final sanitizedRequest = request.change(
                body: sanitizedBody,
              );

              return await inner(sanitizedRequest);
            }
          }
        }

        return await inner(request);
      } catch (e) {
        // If sanitization fails, return bad request
        return Response(400, body: jsonEncode({
          'error': 'Input Sanitization Error',
          'message': 'Failed to process request input',
          'timestamp': DateTime.now().toIso8601String(),
        }));
      }
    };
  }

  /// Recursively sanitize map values
  static Map<String, dynamic> _sanitizeMap(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    data.forEach((key, value) {
      if (value is String) {
        // Sanitize string values
        var sanitizedValue = _sanitizeHtml(value);
        sanitizedValue = _sanitizeSql(sanitizedValue);
        sanitized[key] = sanitizedValue;
      } else if (value is Map<String, dynamic>) {
        // Recursively sanitize nested maps
        sanitized[key] = _sanitizeMap(value);
      } else if (value is List) {
        // Sanitize list items
        sanitized[key] = value.map((item) {
          if (item is String) {
            var sanitizedItem = _sanitizeHtml(item);
            sanitizedItem = _sanitizeSql(sanitizedItem);
            return sanitizedItem;
          } else if (item is Map<String, dynamic>) {
            return _sanitizeMap(item);
          }
          return item;
        }).toList();
      } else {
        // Keep other types as-is
        sanitized[key] = value;
      }
    });

    return sanitized;
  }

  /// Check for suspicious patterns that might indicate attacks
  static bool containsSuspiciousPatterns(String input) {
    final suspiciousPatterns = [
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'vbscript:', caseSensitive: false),
      RegExp(r'data:text/html', caseSensitive: false),
      RegExp(r';\s*drop\s+table', caseSensitive: false),
      RegExp(r'union\s+select.*--', caseSensitive: false),
      RegExp(r'<\s*iframe', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
    ];

    return suspiciousPatterns.any((pattern) => pattern.hasMatch(input));
  }
}
