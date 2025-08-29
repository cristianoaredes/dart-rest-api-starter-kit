import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../../core/middleware/auth_middleware.dart';
import '../handlers/user_handler.dart';

/// User feature routes
class UserRoutes {
  static Router get router {
    final router = Router();

    // Protected user profile endpoints (require authentication)
    router.get('/v1/user/profile', Pipeline()
        .addMiddleware(AuthMiddleware.authentication)
        .addHandler(UserHandler.getProfile()));

    router.put('/v1/user/profile', Pipeline()
        .addMiddleware(AuthMiddleware.authentication)
        .addHandler(UserHandler.updateProfile()));

    router.put('/v1/user/change-password', Pipeline()
        .addMiddleware(AuthMiddleware.authentication)
        .addHandler(UserHandler.changePassword()));

    return router;
  }
}
