import 'dart:convert';
import 'package:shelf/shelf.dart';

/// JWT Authentication middleware for protected routes
class AuthMiddleware {
  /// Middleware to check JWT authentication
  static Middleware get authentication {
    return (inner) => (Request request) async {
      try {
        // Get Authorization header
        final authHeader = request.headers['authorization'];

        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          return Response(401, body: jsonEncode({
            'error': 'Authentication required',
            'message': 'Missing or invalid authorization header'
          }));
        }

        // Extract token
        final token = authHeader.substring(7); // Remove 'Bearer ' prefix

        if (token.isEmpty) {
          return Response(401, body: jsonEncode({
            'error': 'Authentication required',
            'message': 'Empty token provided'
          }));
        }

        // TODO: Implement actual JWT validation here
        // For now, just check if token exists
        // In production, you would:
        // 1. Verify JWT signature
        // 2. Check token expiration
        // 3. Extract user claims
        // 4. Validate user exists in database

        // Add user info to request context for handlers to use
        final authenticatedRequest = request.change(context: {
          'authenticated': true,
          'token': token,
          'user_id': _extractUserIdFromToken(token), // Implement this
        });

        return await inner(authenticatedRequest);

      } catch (e) {
        return Response(500, body: jsonEncode({
          'error': 'Authentication error',
          'message': 'Failed to process authentication'
        }));
      }
    };
  }

  /// Middleware for admin-only routes (future implementation)
  static Middleware get adminOnly {
    return (inner) => (Request request) async {
      // Check if user is authenticated
      if (!request.context.containsKey('authenticated')) {
        return Response(401, body: jsonEncode({
          'error': 'Authentication required'
        }));
      }

      // TODO: Check if user has admin role
      // For now, just pass through
      return await inner(request);
    };
  }

  /// Extract user ID from token (placeholder implementation)
  static String _extractUserIdFromToken(String token) {
    // TODO: Implement actual JWT decoding and user ID extraction
    // This is just a placeholder
    return 'user_123'; // Default demo user
  }
}
