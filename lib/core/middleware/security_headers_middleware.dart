import 'package:shelf/shelf.dart';

/// Security headers middleware for production
class SecurityHeadersMiddleware {
  /// Add comprehensive security headers
  static Middleware get securityHeaders {
    return (inner) => (Request request) async {
      final response = await inner(request);

      // Create comprehensive security headers
      final securityHeaders = <String, String>{
        // Prevent clickjacking
        'X-Frame-Options': 'DENY',
        'Content-Security-Policy': "default-src 'self'; script-src 'self' 'unsafe-inline' https://unpkg.com; style-src 'self' 'unsafe-inline' https://unpkg.com; img-src 'self' data: https:; font-src 'self' https://fonts.googleapis.com https://fonts.gstatic.com;",

        // Prevent MIME type sniffing
        'X-Content-Type-Options': 'nosniff',

        // Enable XSS protection
        'X-XSS-Protection': '1; mode=block',

        // Referrer policy
        'Referrer-Policy': 'strict-origin-when-cross-origin',

        // Permissions policy (restrict features)
        'Permissions-Policy': 'camera=(), microphone=(), geolocation=(), payment=()',

        // HSTS (HTTP Strict Transport Security) - only in production with HTTPS
        'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',

        // Server information (hide server details)
        'Server': 'DartRESTAPIStarterKit/1.0',

        // Cache control for sensitive endpoints
        if (_isSensitiveEndpoint(request.url.path))
          'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0',
      };

      return response.change(headers: {
        ...response.headers,
        ...securityHeaders,
      });
    };
  }

  /// Check if endpoint contains sensitive data
  static bool _isSensitiveEndpoint(String path) {
    final sensitivePaths = [
      '/v1/user',
      '/v1/auth',
      '/v1/ai',
      '/api',
    ];

    return sensitivePaths.any((sensitivePath) => path.startsWith(sensitivePath));
  }

  /// Development mode headers (relaxed for development)
  static Middleware get developmentHeaders {
    return (inner) => (Request request) async {
      final response = await inner(request);

      return response.change(headers: {
        ...response.headers,
        'X-Frame-Options': 'SAMEORIGIN', // More permissive for development
        'Content-Security-Policy': "default-src 'self' 'unsafe-inline' 'unsafe-eval' http://localhost:* https://unpkg.com; script-src 'self' 'unsafe-inline' 'unsafe-eval' http://localhost:* https://unpkg.com;",
      });
    };
  }
}
