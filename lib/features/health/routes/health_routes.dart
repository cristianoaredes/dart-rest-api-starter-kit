import 'package:shelf_router/shelf_router.dart';
import '../handlers/health_handler.dart';

/// Health feature routes
class HealthRoutes {
  static Router get router {
    final router = Router();

    // Health check
    router.get('/v1/health', HealthHandler.health());

    // Version info
    router.get('/v1/version', HealthHandler.version());

    return router;
  }
}
