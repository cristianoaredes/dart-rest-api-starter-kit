import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_static/shelf_static.dart';
import 'core/config/app_config.dart';
import 'core/middleware/error_handling_middleware.dart';
import 'core/middleware/validation_middleware.dart';
import 'core/middleware/rate_limiting_middleware.dart';
import 'core/middleware/security_headers_middleware.dart';
import 'core/middleware/input_sanitization_middleware.dart';
import 'core/middleware/csrf_protection_middleware.dart';

import '../features/health/routes/health_routes.dart';
import '../features/auth/routes/auth_routes.dart';
import '../features/user/routes/user_routes.dart';
import '../features/auth/handlers/auth_handler.dart';
import '../features/user/handlers/user_handler.dart';
import '../features/ai/routes/ai_routes.dart';
import '../features/ai/handlers/ai_handler.dart';

/// Main application server
class ApiServer {
  final int port;
  final InternetAddress ip;
  late final AppConfig _config;
  late final RateLimitingMiddleware _rateLimiter;

  ApiServer({
    int? port,
    InternetAddress? ip,
  }) : port = port ?? 8080,
       ip = ip ?? InternetAddress.anyIPv4;

  /// Start the server
  Future<HttpServer> start() async {
    // Initialize configuration
    _config = AppConfig();
    await _config.initialize();

    // Initialize rate limiter
    _rateLimiter = RateLimitingMiddleware(
      maxRequests: _config.rateLimiting['max_requests'] as int,
      window: Duration(minutes: _config.rateLimiting['window_minutes'] as int),
    );

    // Initialize database and repositories
    await _initializeDatabase();

    final app = Router();

    // Combine all feature routes
    app.mount('/v1/', _createMainRouter().call);

    // Serve Swagger UI static files
    final swaggerHandler = createStaticHandler(
      'swagger-ui/dist',
      defaultDocument: 'index.html',
      listDirectories: true,
    );

    // Serve OpenAPI specification
    final openApiHandler = createStaticHandler(
      '.',
      listDirectories: false,
    );

    // Custom handler that routes requests
    final customHandler = (Request request) async {
      // Try API routes first
      try {
        final apiResponse = await app(request);
        if (apiResponse.statusCode != 404) {
          return apiResponse;
        }
      } catch (_) {
        // Continue to try other handlers
      }

      // Try Swagger UI
      try {
        final swaggerResponse = await swaggerHandler(request);
        if (swaggerResponse.statusCode != 404) {
          return swaggerResponse;
        }
      } catch (_) {
        // Continue to try other handlers
      }

      // Try OpenAPI spec
      try {
        final openApiResponse = await openApiHandler(request);
        if (openApiResponse.statusCode != 404) {
          return openApiResponse;
        }
      } catch (_) {
        // Continue to next handler
      }

      // Return 404 if nothing matched
      return Response.notFound('Not Found');
    };

    // Apply production-ready middleware pipeline with comprehensive security
    final handler = const Pipeline()
        .addMiddleware(ErrorHandlingMiddleware.errorHandler) // Global error handling first
        .addMiddleware(_config.isProduction
            ? SecurityHeadersMiddleware.securityHeaders
            : SecurityHeadersMiddleware.developmentHeaders) // Security headers
        .addMiddleware(_contentType()) // Content type handling
        .addMiddleware(_config.cors['enabled'] == true ? corsHeaders() : (inner) => inner) // CORS
        .addMiddleware(_config.rateLimiting['enabled'] == true ? _rateLimiter.rateLimit : (inner) => inner) // Rate limiting
        .addMiddleware(InputSanitizationMiddleware.sanitizeInput) // Input sanitization & XSS protection
        .addMiddleware(CSRFProtectionMiddleware.csrfProtection) // CSRF protection
        .addMiddleware(_config.validation['json_only'] == true ? ValidationMiddleware.jsonValidation : (inner) => inner) // JSON validation
        .addMiddleware(_config.validation['max_body_size'] != null ? ValidationMiddleware.maxBodySize(_config.validation['max_body_size'] as int) : (inner) => inner) // Body size limit
        .addMiddleware(logRequests()) // Request logging
        .addHandler(customHandler);

    final server = await serve(handler, ip, port);
    print('🚀 Dart REST API Starter Kit - Production-Ready!');
    print('🌐 Listening on http://${server.address.host}:${server.port}');
    print('📊 Environment: ${_config.environment}');
    print('🔧 Features:');
    print('  - Health: /v1/health, /v1/health/database');
    print('  - Auth: /v1/auth/* (public)');
    print('  - User: /v1/user/* (protected)');
    print('  - AI: /v1/ai/* (protected)');
    print('  - API Docs: http://${server.address.host}:${server.port}/');
    print('  - OpenAPI Spec: http://${server.address.host}:${server.port}/openapi.yaml');
    print('🛡️ Security: JWT Authentication + Rate Limiting');
    print('📈 Monitoring: Error handling + Request logging');
    print('💾 Database: SQLite initialized with demo data');

    return server;
  }

  /// Initialize database and repositories
  Future<void> _initializeDatabase() async {
    // Database is initialized automatically when accessed
    // Initialize handler repositories
    await AuthHandler.initialize();
    await UserHandler.initialize();
    await AiHandler.initialize();
  }

  /// Create main router with all features
  Router _createMainRouter() {
    final router = Router();

    // Mount feature routes
    router.mount('/health/', HealthRoutes.router);
    router.mount('/version/', HealthRoutes.router); // Health routes handle version too
    router.mount('/auth/', AuthRoutes.router);
    router.mount('/user/', UserRoutes.router);
    router.mount('/ai/', AiRoutes.router);

    return router;
  }

  /// Middleware to set appropriate content type
  Middleware _contentType() {
    return (inner) => (req) async {
      final res = await inner(req);

      // Check if this is an HTML file request
      if (req.url.path.endsWith('.html') ||
          req.url.path == '/' ||
          req.url.path.isEmpty) {
        return res.change(headers: {
          ...res.headers,
          HttpHeaders.contentTypeHeader: ContentType.html.mimeType,
        });
      }

      // Check if this is a YAML file request
      if (req.url.path.endsWith('.yaml') || req.url.path.endsWith('.yml')) {
        return res.change(headers: {
          ...res.headers,
          HttpHeaders.contentTypeHeader: 'application/x-yaml',
        });
      }

      // Default to JSON for API responses
      return res.change(headers: {
        ...res.headers,
        HttpHeaders.contentTypeHeader: ContentType.json.mimeType,
      });
    };
  }
}

/// Convenience function to start the server
Future<HttpServer> startServer({
  int port = 8080,
  InternetAddress? ip,
}) async {
  final server = ApiServer(port: port, ip: ip);
  return await server.start();
}
