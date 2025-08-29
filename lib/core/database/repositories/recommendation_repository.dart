import '../repositories/base_repository.dart';

/// Recommendation data model
class RecommendationModel {
  final String id;
  final String userId;
  final String recommendationType;
  final List<String> recommendedItems;
  final Map<String, double> scores;
  final String algorithmUsed;
  final DateTime expiresAt;
  final DateTime createdAt;

  const RecommendationModel({
    required this.id,
    required this.userId,
    required this.recommendationType,
    required this.recommendedItems,
    required this.scores,
    required this.algorithmUsed,
    required this.expiresAt,
    required this.createdAt,
  });

  /// Create RecommendationModel from database row
  factory RecommendationModel.fromMap(Map<String, dynamic> map) {
    return RecommendationModel(
      id: map['id'],
      userId: map['user_id'],
      recommendationType: map['recommendation_type'],
      recommendedItems: _parseItems(map['recommended_items']),
      scores: _parseScores(map['scores']),
      algorithmUsed: map['algorithm_used'],
      expiresAt: DateTime.parse(map['expires_at']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  /// Convert RecommendationModel to database row
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'recommendation_type': recommendationType,
      'recommended_items': _serializeItems(recommendedItems),
      'scores': _serializeScores(scores),
      'algorithm_used': algorithmUsed,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  static List<String> _parseItems(String itemsJson) {
    if (itemsJson.startsWith('[') && itemsJson.endsWith(']')) {
      final items = itemsJson.substring(1, itemsJson.length - 1)
          .split(',')
          .map((s) => s.trim().replaceAll('"', '').replaceAll("'", ''))
          .where((s) => s.isNotEmpty)
          .toList();
      return items;
    }
    return [];
  }

  static String _serializeItems(List<String> items) {
    return '[${items.map((item) => '"$item"').join(', ')}]';
  }

  static Map<String, double> _parseScores(String scoresJson) {
    final scores = <String, double>{};
    if (scoresJson.startsWith('{') && scoresJson.endsWith('}')) {
      // Simple parsing - in production you'd use json.decode
      final content = scoresJson.substring(1, scoresJson.length - 1);
      final pairs = content.split(',');
      for (final pair in pairs) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          final key = parts[0].trim().replaceAll('"', '').replaceAll("'", '');
          final value = double.tryParse(parts[1].trim()) ?? 0.0;
          scores[key] = value;
        }
      }
    }
    return scores;
  }

  static String _serializeScores(Map<String, double> scores) {
    final pairs = scores.entries.map((e) => '"${e.key}": ${e.value}').join(', ');
    return '{$pairs}';
  }

  /// Check if recommendation is expired
  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  /// Check if recommendation is valid (not expired)
  bool get isValid => !isExpired;
}

/// Recommendation repository
class RecommendationRepository extends BaseRepository {

  /// Create a new recommendation
  Future<RecommendationModel> create(RecommendationModel recommendation) async {
    execute('''
      INSERT INTO recommendations (id, user_id, recommendation_type, recommended_items, scores, algorithm_used, expires_at, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      recommendation.id,
      recommendation.userId,
      recommendation.recommendationType,
      recommendation.recommendedItems.toString(),
      recommendation.scores.toString(),
      recommendation.algorithmUsed,
      recommendation.expiresAt.toIso8601String(),
      recommendation.createdAt.toIso8601String(),
    ]);

    return recommendation;
  }

  /// Find recommendations by user ID
  Future<List<RecommendationModel>> findByUserId(String userId) async {
    final results = await query(
      'SELECT * FROM recommendations WHERE user_id = ? ORDER BY created_at DESC',
      [userId],
    );

    return results.map((row) => RecommendationModel.fromMap(row)).toList();
  }

  /// Find recommendations by type
  Future<List<RecommendationModel>> findByType(String recommendationType) async {
    final results = await query(
      'SELECT * FROM recommendations WHERE recommendation_type = ? ORDER BY created_at DESC',
      [recommendationType],
    );

    return results.map((row) => RecommendationModel.fromMap(row)).toList();
  }

  /// Find valid (non-expired) recommendations for user
  Future<List<RecommendationModel>> findValidForUser(String userId, String recommendationType) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final results = await query('''
      SELECT * FROM recommendations
      WHERE user_id = ? AND recommendation_type = ? AND expires_at > ?
      ORDER BY created_at DESC
    ''', [userId, recommendationType, now]);

    return results.map((row) => RecommendationModel.fromMap(row)).toList();
  }

  /// Update recommendation
  Future<RecommendationModel> update(String id, List<String> newItems, Map<String, double> newScores) async {
    final futureTime = DateTime.now().toUtc().add(Duration(hours: 24)).toIso8601String();

    execute('''
      UPDATE recommendations SET
        recommended_items = ?,
        scores = ?,
        expires_at = ?
      WHERE id = ?
    ''', [
      newItems.toString(),
      newScores.toString(),
      futureTime,
      id,
    ]);

    // Return updated recommendation
    final result = await querySingle(
      'SELECT * FROM recommendations WHERE id = ?',
      [id],
    );

    if (result != null) {
      return RecommendationModel.fromMap(result);
    }
    throw Exception('Recommendation not found');
  }

  /// Delete recommendation
  Future<void> delete(String id) async {
    execute('DELETE FROM recommendations WHERE id = ?', [id]);
  }

  /// Delete expired recommendations
  Future<void> deleteExpired() async {
    final now = DateTime.now().toUtc().toIso8601String();
    execute('DELETE FROM recommendations WHERE expires_at < ?', [now]);
  }

  /// Get latest recommendation for user and type
  Future<RecommendationModel?> getLatestForUser(String userId, String recommendationType) async {
    final result = await querySingle('''
      SELECT * FROM recommendations
      WHERE user_id = ? AND recommendation_type = ?
      ORDER BY created_at DESC
      LIMIT 1
    ''', [userId, recommendationType]);

    if (result != null) {
      return RecommendationModel.fromMap(result);
    }
    return null;
  }

  /// Generate personalized recommendations based on user behavior
  Future<RecommendationModel> generateRecommendations(
    String userId,
    String recommendationType,
    String algorithmUsed,
    {Duration validityDuration = const Duration(hours: 24)}
  ) async {
    // In a real system, this would analyze user behavior, embeddings, etc.
    // For demo purposes, we'll generate simple recommendations

    final recommendedItems = <String>[];
    final scores = <String, double>{};

    // Get user's recent interactions
    final interactions = await query('''
      SELECT content_type, content_id, rating, interaction_type
      FROM user_interactions
      WHERE user_id = ? AND timestamp > datetime('now', '-30 days')
      ORDER BY timestamp DESC
      LIMIT 10
    ''', [userId]);

    // Simple recommendation logic based on interactions
    if (interactions.isNotEmpty) {
      // Recommend similar content based on user's interactions
      final likedContent = interactions.where((i) =>
        (i['rating'] != null && i['rating'] > 3.0) ||
        i['interaction_type'] == 'save' ||
        i['interaction_type'] == 'share'
      ).toList();

      if (likedContent.isNotEmpty) {
        // Find similar content (simplified logic)
        for (final interaction in likedContent.take(3)) {
          final contentType = interaction['content_type'];
          final similarContent = await query('''
            SELECT content_id, title FROM content_embeddings
            WHERE content_type = ? AND content_id != ?
            LIMIT 2
          ''', [contentType, interaction['content_id']]);

          for (final content in similarContent) {
            final contentId = content['content_id'];
            if (!recommendedItems.contains(contentId)) {
              recommendedItems.add(contentId);
              scores[contentId] = 0.8; // Simplified scoring
            }
          }
        }
      }
    } else {
      // Default recommendations for new users
      recommendedItems.addAll(['service_1', 'service_2', 'news_1']);
      scores.addAll({'service_1': 0.7, 'service_2': 0.6, 'news_1': 0.5});
    }

    // Create recommendation
    final now = DateTime.now().toUtc();
    final expiresAt = now.add(validityDuration);
    final recommendationId = 'rec_${userId}_${recommendationType}_${now.millisecondsSinceEpoch}';

    final recommendation = RecommendationModel(
      id: recommendationId,
      userId: userId,
      recommendationType: recommendationType,
      recommendedItems: recommendedItems,
      scores: scores,
      algorithmUsed: algorithmUsed,
      expiresAt: expiresAt,
      createdAt: now,
    );

    return await create(recommendation);
  }
}
