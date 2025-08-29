import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../../core/middleware/auth_middleware.dart';
import '../handlers/ai_handler.dart';

/// AI routes - Machine Learning and AI endpoints
class AiRoutes {
  /// AI router with all AI endpoints
  static Router get router {
    final router = Router();

    // Protected AI endpoints (require authentication)
    router.post('/search/semantic', Pipeline()
        .addMiddleware(AuthMiddleware.authentication)
        .addHandler(AiHandler.semanticSearch()));

    router.post('/recommendations', Pipeline()
        .addMiddleware(AuthMiddleware.authentication)
        .addHandler(AiHandler.getRecommendations()));

    router.post('/embeddings/generate', Pipeline()
        .addMiddleware(AuthMiddleware.authentication)
        .addHandler(AiHandler.generateEmbedding()));

    router.post('/interactions/track', Pipeline()
        .addMiddleware(AuthMiddleware.authentication)
        .addHandler(AiHandler.trackInteraction()));

    router.post('/analytics', Pipeline()
        .addMiddleware(AuthMiddleware.authentication)
        .addHandler(AiHandler.getAnalytics()));

    return router;
  }
}
