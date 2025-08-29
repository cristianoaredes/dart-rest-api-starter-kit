import '../../../core/database/repositories/content_embedding_repository.dart';
import '../../../core/database/repositories/recommendation_repository.dart';

/// AI service - handles business logic for AI operations
class AiService {
  final ContentEmbeddingRepository _contentEmbeddingRepository;
  final RecommendationRepository _recommendationRepository;

  AiService({
    required ContentEmbeddingRepository contentEmbeddingRepository,
    required RecommendationRepository recommendationRepository,
  })  : _contentEmbeddingRepository = contentEmbeddingRepository,
        _recommendationRepository = recommendationRepository;

  /// Perform semantic search using vector similarity
  Future<Map<String, dynamic>> semanticSearch(List<double> queryVector, {int limit = 10}) async {
    if (queryVector.isEmpty) {
      throw AiException('query_vector is required and must be an array of numbers');
    }

    try {
      final similarContent = await _contentEmbeddingRepository.findSimilarContent(
        queryVector,
        limit: limit,
      );

      final results = similarContent.map((item) {
        final content = item['content'] as ContentEmbeddingModel;
        return {
          'content': {
            'id': content.contentId,
            'type': content.contentType,
            'title': content.title,
            'description': content.description,
            'category': content.category,
            'tags': content.tags,
          },
          'similarity_score': item['similarity'],
        };
      }).toList();

      return {
        'query_vector_length': queryVector.length,
        'results_count': results.length,
        'results': results,
      };
    } catch (e) {
      throw AiException('Failed to perform semantic search: ${e.toString()}');
    }
  }

  /// Get recommendations for user
  Future<Map<String, dynamic>> getRecommendations(String userId, {String recommendationType = 'content'}) async {
    if (userId.isEmpty) {
      throw AiException('user_id is required');
    }

    try {
      // Try to get existing valid recommendations
      var recommendations = await _recommendationRepository.findValidForUser(
        userId,
        recommendationType,
      );

      // If no valid recommendations exist, generate new ones
      if (recommendations.isEmpty) {
        final newRecommendation = await _recommendationRepository.generateRecommendations(
          userId,
          recommendationType,
          'cosine_similarity',
        );
        recommendations = [newRecommendation];
      }

      final results = recommendations.map((rec) {
        return {
          'recommendation_id': rec.id,
          'user_id': rec.userId,
          'type': rec.recommendationType,
          'recommended_items': rec.recommendedItems,
          'scores': rec.scores,
          'algorithm_used': rec.algorithmUsed,
          'expires_at': rec.expiresAt.toIso8601String(),
          'created_at': rec.createdAt.toIso8601String(),
        };
      }).toList();

      return {
        'user_id': userId,
        'recommendation_type': recommendationType,
        'recommendations': results,
      };
    } catch (e) {
      throw AiException('Failed to get recommendations: ${e.toString()}');
    }
  }

  /// Generate embedding for content
  Future<Map<String, dynamic>> generateEmbedding({
    required String contentType,
    required String contentId,
    required String title,
    String? description,
    String? category,
    List<String>? tags,
    String modelVersion = 'demo-v1.0',
  }) async {
    if (contentType.isEmpty || contentId.isEmpty || title.isEmpty) {
      throw AiException('content_type, content_id, and title are required');
    }

    try {
      // Generate a simple demo embedding (in real app, this would call an ML model)
      final embeddingVector = _generateDemoEmbedding(title, description ?? '');

      // Create content embedding
      final embeddingId = 'embedding_${contentId}';
      final embedding = ContentEmbeddingModel(
        id: embeddingId,
        contentType: contentType,
        contentId: contentId,
        title: title,
        description: description,
        embeddingVector: embeddingVector,
        category: category,
        tags: tags ?? [],
        modelVersion: modelVersion,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      final savedEmbedding = await _contentEmbeddingRepository.create(embedding);

      return {
        'embedding_id': savedEmbedding.id,
        'content_id': savedEmbedding.contentId,
        'content_type': savedEmbedding.contentType,
        'embedding_vector': savedEmbedding.embeddingVector,
        'vector_length': savedEmbedding.embeddingVector.length,
        'model_version': savedEmbedding.modelVersion,
        'created_at': savedEmbedding.createdAt.toIso8601String(),
      };
    } catch (e) {
      throw AiException('Failed to generate embedding: ${e.toString()}');
    }
  }

  /// Track user interaction for recommendation system
  Future<Map<String, dynamic>> trackInteraction({
    required String userId,
    required String contentType,
    required String contentId,
    required String interactionType,
    double? rating,
    int? durationSeconds,
    Map<String, dynamic>? metadata,
  }) async {
    if (userId.isEmpty || contentType.isEmpty || contentId.isEmpty || interactionType.isEmpty) {
      throw AiException('user_id, content_type, content_id, and interaction_type are required');
    }

    try {
      // In a real app, this would be stored in user_interactions table
      // For demo purposes, we'll just acknowledge the interaction
      return {
        'interaction_id': 'interaction_${DateTime.now().millisecondsSinceEpoch}',
        'user_id': userId,
        'content_type': contentType,
        'content_id': contentId,
        'interaction_type': interactionType,
        'rating': rating,
        'duration_seconds': durationSeconds,
        'metadata': metadata,
        'tracked_at': DateTime.now().toUtc().toIso8601String(),
        'message': 'Interaction tracked successfully',
      };
    } catch (e) {
      throw AiException('Failed to track interaction: ${e.toString()}');
    }
  }

  /// Get AI analytics and metrics
  Future<Map<String, dynamic>> getAnalytics({String? userId}) async {
    try {
      // In a real app, this would query ai_analytics table
      // For demo purposes, we'll return mock analytics data

      return {
        'user_id': userId,
        'total_embeddings_generated': 42,
        'total_recommendations_shown': 156,
        'total_similarity_searches': 89,
        'average_processing_time_ms': 245.67,
        'model_performance': {
          'embedding_model': {
            'version': 'demo-v1.0',
            'accuracy': 0.87,
            'avg_response_time_ms': 180.5,
          },
          'recommendation_model': {
            'version': 'cosine-v2.0',
            'click_through_rate': 0.23,
            'avg_response_time_ms': 65.2,
          }
        },
        'recent_events': [
          {
            'event_type': 'embedding_generated',
            'model_name': 'text-embedding',
            'processing_time_ms': 156,
            'timestamp': DateTime.now().toUtc().subtract(Duration(minutes: 5)).toIso8601String(),
          },
          {
            'event_type': 'recommendation_shown',
            'model_name': 'recommendation-engine',
            'processing_time_ms': 42,
            'timestamp': DateTime.now().toUtc().subtract(Duration(minutes: 3)).toIso8601String(),
          },
          {
            'event_type': 'similarity_search',
            'model_name': 'vector-search',
            'processing_time_ms': 78,
            'timestamp': DateTime.now().toUtc().subtract(Duration(minutes: 1)).toIso8601String(),
          }
        ]
      };
    } catch (e) {
      throw AiException('Failed to get analytics: ${e.toString()}');
    }
  }

  /// Generate demo embedding vector based on text content
  List<double> _generateDemoEmbedding(String title, String description) {
    final text = '$title $description'.toLowerCase();
    final vector = <double>[];

    // Simple hash-based embedding generation (demo purposes only)
    for (int i = 0; i < 15; i++) {
      final hash = text.hashCode + i * 31;
      final normalized = (hash % 2000 - 1000) / 1000.0; // -1.0 to 1.0
      vector.add(normalized.clamp(-1.0, 1.0));
    }

    return vector;
  }
}

/// Custom exception for AI-related errors
class AiException implements Exception {
  final String message;

  AiException(this.message);

  @override
  String toString() => message;
}
