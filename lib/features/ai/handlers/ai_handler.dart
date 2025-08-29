import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../../core/utils/handler_utils.dart';
import '../../../core/database/repositories/content_embedding_repository.dart';
import '../../../core/database/repositories/recommendation_repository.dart';
import '../services/ai_service.dart';

/// AI handler with service layer
class AiHandler {
  static late final AiService _aiService;

  /// Initialize services and repositories
  static Future<void> initialize() async {
    final contentEmbeddingRepository = ContentEmbeddingRepository();
    final recommendationRepository = RecommendationRepository();

    _aiService = AiService(
      contentEmbeddingRepository: contentEmbeddingRepository,
      recommendationRepository: recommendationRepository,
    );
  }

  /// Semantic search endpoint - find similar content
  static Handler semanticSearch() {
    return HandlerUtils.jsonHandlerWithBody((Request request, Map<String, dynamic> body) async {
      try {
        final queryVector = body['query_vector'];
        final limit = body['limit'] as int? ?? 10;

        if (queryVector == null || queryVector is! List) {
          return Response(400, body: jsonEncode({
            'error': 'query_vector is required and must be an array of numbers'
          }));
        }

        final vector = queryVector.map((v) => v as double).toList();
        final result = await _aiService.semanticSearch(vector, limit: limit);
        return result;
      } on AiException catch (e) {
        return Response(400, body: jsonEncode({'error': e.message}));
      } catch (e) {
        return Response(500, body: jsonEncode({
          'error': 'Failed to perform semantic search: ${e.toString()}'
        }));
      }
    });
  }

  /// Get recommendations for user
  static Handler getRecommendations() {
    return HandlerUtils.jsonHandlerWithBody((Request request, Map<String, dynamic> body) async {
      try {
        final userId = body['user_id'] as String?;
        final recommendationType = body['recommendation_type'] as String? ?? 'content';

        if (userId == null || userId.isEmpty) {
          return Response(400, body: jsonEncode({
            'error': 'user_id is required'
          }));
        }

        final result = await _aiService.getRecommendations(userId, recommendationType: recommendationType);
        return result;
      } on AiException catch (e) {
        return Response(400, body: jsonEncode({'error': e.message}));
      } catch (e) {
        return Response(500, body: jsonEncode({
          'error': 'Failed to get recommendations: ${e.toString()}'
        }));
      }
    });
  }

  /// Generate embedding for content
  static Handler generateEmbedding() {
    return HandlerUtils.jsonHandlerWithBody((Request request, Map<String, dynamic> body) async {
      try {
        final contentType = body['content_type'] as String?;
        final contentId = body['content_id'] as String?;
        final title = body['title'] as String?;
        final description = body['description'] as String?;
        final category = body['category'] as String?;
        final tags = body['tags'] != null ? List<String>.from(body['tags']) : null;
        final modelVersion = body['model_version'] as String? ?? 'demo-v1.0';

        final result = await _aiService.generateEmbedding(
          contentType: contentType!,
          contentId: contentId!,
          title: title!,
          description: description,
          category: category,
          tags: tags,
          modelVersion: modelVersion,
        );
        return result;
      } on AiException catch (e) {
        return Response(400, body: jsonEncode({'error': e.message}));
      } catch (e) {
        return Response(500, body: jsonEncode({
          'error': 'Failed to generate embedding: ${e.toString()}'
        }));
      }
    });
  }

  /// Track user interaction for recommendation system
  static Handler trackInteraction() {
    return HandlerUtils.jsonHandlerWithBody((Request request, Map<String, dynamic> body) async {
      try {
        final userId = body['user_id'] as String?;
        final contentType = body['content_type'] as String?;
        final contentId = body['content_id'] as String?;
        final interactionType = body['interaction_type'] as String?;
        final rating = body['rating'] as double?;
        final durationSeconds = body['duration_seconds'] as int?;
        final metadata = body['metadata'];

        final result = await _aiService.trackInteraction(
          userId: userId!,
          contentType: contentType!,
          contentId: contentId!,
          interactionType: interactionType!,
          rating: rating,
          durationSeconds: durationSeconds,
          metadata: metadata,
        );
        return result;
      } on AiException catch (e) {
        return Response(400, body: jsonEncode({'error': e.message}));
      } catch (e) {
        return Response(500, body: jsonEncode({
          'error': 'Failed to track interaction: ${e.toString()}'
        }));
      }
    });
  }

  /// Get AI analytics and metrics
  static Handler getAnalytics() {
    return HandlerUtils.jsonHandlerWithBody((Request request, Map<String, dynamic> body) async {
      try {
        final userId = body['user_id'] as String?;
        final result = await _aiService.getAnalytics(userId: userId);
        return result;
      } on AiException catch (e) {
        return Response(400, body: jsonEncode({'error': e.message}));
      } catch (e) {
        return Response(500, body: jsonEncode({
          'error': 'Failed to get analytics: ${e.toString()}'
        }));
      }
    });
  }
}
