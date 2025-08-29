import 'dart:convert';
import 'package:shelf/shelf.dart';

/// CSRF protection middleware
class CSRFProtectionMiddleware {
  static const String _csrfTokenHeader = 'X-CSRF-Token';

  /// Generate a CSRF token
  static String _generateCSRFToken() {
    // In production, use a cryptographically secure random generator
    // For now, use a simple approach (replace with proper crypto in production)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 1000000;
    return '${timestamp}_$random';
  }

  /// CSRF protection middleware for state-changing operations
  static Middleware get csrfProtection {
    return (inner) => (Request request) async {
      try {
        // Only protect state-changing operations
        if (['POST', 'PUT', 'PATCH', 'DELETE'].contains(request.method)) {
          // Skip CSRF protection for API endpoints that use JWT (stateless)
          if (request.url.path.startsWith('/v1/')) {
            // These endpoints should use JWT authentication instead of CSRF
            return await inner(request);
          }

          // For form-based endpoints, check CSRF token
          final csrfToken = _extractCSRFToken(request);

          if (csrfToken == null || !_isValidCSRFToken(csrfToken)) {
            return Response(403, body: jsonEncode({
              'error': 'CSRF Protection',
              'message': 'Invalid or missing CSRF token',
              'timestamp': DateTime.now().toIso8601String(),
            }));
          }
        }

        // Add CSRF token to response for future requests
        final response = await inner(request);
        final newToken = _generateCSRFToken();

        return response.change(headers: {
          ...response.headers,
          'X-CSRF-Token': newToken,
        });

      } catch (e) {
        return Response(500, body: jsonEncode({
          'error': 'CSRF Protection Error',
          'message': 'Failed to process CSRF protection',
          'timestamp': DateTime.now().toIso8601String(),
        }));
      }
    };
  }

  /// Extract CSRF token from request
  static String? _extractCSRFToken(Request request) {
    // Try header first
    final headerToken = request.headers[_csrfTokenHeader.toLowerCase()];
    if (headerToken != null && headerToken.isNotEmpty) {
      return headerToken;
    }

    // Try from form data
    if (request.method == 'POST') {
      // In a real implementation, you'd parse form data here
      // For now, return null (CSRF protection disabled for this demo)
    }

    return null;
  }

  /// Validate CSRF token (basic validation)
  static bool _isValidCSRFToken(String token) {
    // In production, implement proper token validation:
    // 1. Check token format
    // 2. Verify token hasn't expired
    // 3. Check token against session/user
    // 4. Use cryptographically secure validation

    // For demo purposes, accept any non-empty token
    return token.isNotEmpty && token.length > 10;
  }

  /// Middleware to add CSRF token to GET responses
  static Middleware get csrfTokenInjector {
    return (inner) => (Request request) async {
      final response = await inner(request);

      // Add CSRF token to HTML responses
      if (response.headers['content-type']?.contains('text/html') == true) {
        final csrfToken = _generateCSRFToken();
        return response.change(headers: {
          ...response.headers,
          _csrfTokenHeader: csrfToken,
        });
      }

      return response;
    };
  }
}
