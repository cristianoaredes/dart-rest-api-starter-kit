import 'package:shelf_router/shelf_router.dart';
import '../handlers/auth_handler.dart';

/// Authentication feature routes
class AuthRoutes {
  static Router get router {
    final router = Router();

    // Authentication endpoints
    router.post('/v1/auth/login', AuthHandler.login());
    router.post('/v1/auth/register', AuthHandler.register());
    router.post('/v1/auth/logout', AuthHandler.logout());
    router.post('/v1/auth/refresh', AuthHandler.refresh());
    router.post('/v1/auth/forgot-password', AuthHandler.forgotPassword());
    router.post('/v1/auth/reset-password', AuthHandler.resetPassword());
    router.post('/v1/auth/send-email-verification', AuthHandler.sendEmailVerification());
    router.post('/v1/auth/verify-email/<token>', AuthHandler.verifyEmail());

    return router;
  }
}
