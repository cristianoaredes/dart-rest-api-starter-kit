import '../repositories/base_repository.dart';

/// Embedding data model
class EmbeddingModel {
  final String id;
  final String? userId;
  final List<double> embeddingVector;
  final String embeddingType;
  final String modelVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EmbeddingModel({
    required this.id,
    this.userId,
    required this.embeddingVector,
    required this.embeddingType,
    required this.modelVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create EmbeddingModel from database row
  factory EmbeddingModel.fromMap(Map<String, dynamic> map) {
    return EmbeddingModel(
      id: map['id'],
      userId: map['user_id'],
      embeddingVector: _parseEmbeddingVector(map['embedding_vector']),
      embeddingType: map['embedding_type'],
      modelVersion: map['model_version'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  /// Convert EmbeddingModel to database row
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'embedding_vector': _serializeEmbeddingVector(embeddingVector),
      'embedding_type': embeddingType,
      'model_version': modelVersion,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static List<double> _parseEmbeddingVector(String vectorJson) {
    // Simple parsing - in production you'd use json.decode
    if (vectorJson.startsWith('[') && vectorJson.endsWith(']')) {
      final values = vectorJson.substring(1, vectorJson.length - 1)
          .split(',')
          .map((s) => double.tryParse(s.trim()) ?? 0.0)
          .toList();
      return values;
    }
    return [];
  }

  static String _serializeEmbeddingVector(List<double> vector) {
    return '[${vector.join(', ')}]';
  }
}

/// Embedding repository for AI operations
class EmbeddingRepository extends BaseRepository {

  /// Create a new embedding
  Future<EmbeddingModel> create(EmbeddingModel embedding) async {
    execute('''
      INSERT INTO user_embeddings (id, user_id, embedding_vector, embedding_type, model_version, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', [
      embedding.id,
      embedding.userId,
      embedding.embeddingVector.toString(),
      embedding.embeddingType,
      embedding.modelVersion,
      embedding.createdAt.toIso8601String(),
      embedding.updatedAt.toIso8601String(),
    ]);

    return embedding;
  }

  /// Find embeddings by user ID
  Future<List<EmbeddingModel>> findByUserId(String userId) async {
    final results = await query(
      'SELECT * FROM user_embeddings WHERE user_id = ? ORDER BY created_at DESC',
      [userId],
    );

    return results.map((row) => EmbeddingModel.fromMap(row)).toList();
  }

  /// Find embeddings by type
  Future<List<EmbeddingModel>> findByType(String embeddingType) async {
    final results = await query(
      'SELECT * FROM user_embeddings WHERE embedding_type = ? ORDER BY created_at DESC',
      [embeddingType],
    );

    return results.map((row) => EmbeddingModel.fromMap(row)).toList();
  }

  /// Update embedding
  Future<EmbeddingModel> update(String id, List<double> newVector) async {
    final now = DateTime.now().toUtc().toIso8601String();

    execute('''
      UPDATE user_embeddings SET
        embedding_vector = ?,
        updated_at = ?
      WHERE id = ?
    ''', [
      newVector.toString(),
      now,
      id,
    ]);

    // Return updated embedding
    final result = await querySingle(
      'SELECT * FROM user_embeddings WHERE id = ?',
      [id],
    );

    if (result != null) {
      return EmbeddingModel.fromMap(result);
    }
    throw Exception('Embedding not found');
  }

  /// Delete embedding
  Future<void> delete(String id) async {
    execute('DELETE FROM user_embeddings WHERE id = ?', [id]);
  }

  /// Calculate cosine similarity between two embeddings
  double calculateCosineSimilarity(List<double> vectorA, List<double> vectorB) {
    if (vectorA.length != vectorB.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < vectorA.length; i++) {
      dotProduct += vectorA[i] * vectorB[i];
      normA += vectorA[i] * vectorA[i];
      normB += vectorB[i] * vectorB[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// Find similar embeddings using cosine similarity
  Future<List<Map<String, dynamic>>> findSimilarEmbeddings(
    List<double> queryVector,
    String embeddingType,
    {int limit = 10}
  ) async {
    final embeddings = await findByType(embeddingType);
    final similarities = <Map<String, dynamic>>[];

    for (final embedding in embeddings) {
      final similarity = calculateCosineSimilarity(queryVector, embedding.embeddingVector);
      similarities.add({
        'embedding': embedding,
        'similarity': similarity,
      });
    }

    // Sort by similarity (descending) and limit results
    similarities.sort((a, b) => b['similarity'].compareTo(a['similarity']));
    return similarities.take(limit).toList();
  }
}

/// Helper function for square root calculation
double sqrt(double x) {
  if (x < 0) return double.nan;
  if (x == 0 || x.isInfinite) return x;

  double result = x;
  double epsilon = 1e-10;

  while ((result * result - x).abs() > epsilon) {
    result = (result + x / result) / 2;
  }

  return result;
}
