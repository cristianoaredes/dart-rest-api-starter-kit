import '../repositories/base_repository.dart';

/// Content Embedding data model
class ContentEmbeddingModel {
  final String id;
  final String contentType;
  final String contentId;
  final String title;
  final String? description;
  final List<double> embeddingVector;
  final String? category;
  final List<String> tags;
  final String modelVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContentEmbeddingModel({
    required this.id,
    required this.contentType,
    required this.contentId,
    required this.title,
    this.description,
    required this.embeddingVector,
    this.category,
    required this.tags,
    required this.modelVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create ContentEmbeddingModel from database row
  factory ContentEmbeddingModel.fromMap(Map<String, dynamic> map) {
    return ContentEmbeddingModel(
      id: map['id'],
      contentType: map['content_type'],
      contentId: map['content_id'],
      title: map['title'],
      description: map['description'],
      embeddingVector: _parseEmbeddingVector(map['embedding_vector']),
      category: map['category'],
      tags: _parseTags(map['tags']),
      modelVersion: map['model_version'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  /// Convert ContentEmbeddingModel to database row
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content_type': contentType,
      'content_id': contentId,
      'title': title,
      'description': description,
      'embedding_vector': _serializeEmbeddingVector(embeddingVector),
      'category': category,
      'tags': _serializeTags(tags),
      'model_version': modelVersion,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static List<double> _parseEmbeddingVector(String vectorJson) {
    if (vectorJson.startsWith('[') && vectorJson.endsWith(']')) {
      final values = vectorJson
          .substring(1, vectorJson.length - 1)
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

  static List<String> _parseTags(String? tagsJson) {
    if (tagsJson == null || tagsJson.isEmpty) return [];
    if (tagsJson.startsWith('[') && tagsJson.endsWith(']')) {
      final tags = tagsJson
          .substring(1, tagsJson.length - 1)
          .split(',')
          .map((s) => s.trim().replaceAll('"', '').replaceAll("'", ''))
          .where((s) => s.isNotEmpty)
          .toList();
      return tags;
    }
    return [];
  }

  static String _serializeTags(List<String> tags) {
    return '[${tags.map((tag) => '"$tag"').join(', ')}]';
  }
}

/// Content Embedding repository
class ContentEmbeddingRepository extends BaseRepository {
  /// Create a new content embedding
  Future<ContentEmbeddingModel> create(ContentEmbeddingModel embedding) async {
    execute('''
      INSERT INTO content_embeddings (id, content_type, content_id, title, description, embedding_vector, category, tags, model_version, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      embedding.id,
      embedding.contentType,
      embedding.contentId,
      embedding.title,
      embedding.description,
      embedding.embeddingVector.toString(),
      embedding.category,
      embedding.tags.toString(),
      embedding.modelVersion,
      embedding.createdAt.toIso8601String(),
      embedding.updatedAt.toIso8601String(),
    ]);

    return embedding;
  }

  /// Find content embedding by ID
  Future<ContentEmbeddingModel?> findById(String id) async {
    final result = await querySingle(
      'SELECT * FROM content_embeddings WHERE id = ?',
      [id],
    );

    if (result != null) {
      return ContentEmbeddingModel.fromMap(result);
    }
    return null;
  }

  /// Find content embeddings by type
  Future<List<ContentEmbeddingModel>> findByType(String contentType) async {
    final results = await query(
      'SELECT * FROM content_embeddings WHERE content_type = ? ORDER BY created_at DESC',
      [contentType],
    );

    return results.map((row) => ContentEmbeddingModel.fromMap(row)).toList();
  }

  /// Find content embeddings by category
  Future<List<ContentEmbeddingModel>> findByCategory(String category) async {
    final results = await query(
      'SELECT * FROM content_embeddings WHERE category = ? ORDER BY created_at DESC',
      [category],
    );

    return results.map((row) => ContentEmbeddingModel.fromMap(row)).toList();
  }

  /// Search content by title/description
  Future<List<ContentEmbeddingModel>> searchByText(String searchQuery) async {
    final results = await query('''
      SELECT * FROM content_embeddings
      WHERE title LIKE ? OR description LIKE ?
      ORDER BY created_at DESC
    ''', ['%$searchQuery%', '%$searchQuery%']);

    return results.map((row) => ContentEmbeddingModel.fromMap(row)).toList();
  }

  /// Find similar content using cosine similarity
  Future<List<Map<String, dynamic>>> findSimilarContent(
      List<double> queryVector,
      {int limit = 10}) async {
    final contents = await query('SELECT * FROM content_embeddings');
    final similarities = <Map<String, dynamic>>[];

    for (final row in contents) {
      final embedding = ContentEmbeddingModel.fromMap(row);
      final similarity =
          _calculateCosineSimilarity(queryVector, embedding.embeddingVector);
      similarities.add({
        'content': embedding,
        'similarity': similarity,
      });
    }

    // Sort by similarity (descending) and limit results
    similarities.sort((a, b) => b['similarity'].compareTo(a['similarity']));
    return similarities.take(limit).toList();
  }

  /// Update content embedding
  Future<ContentEmbeddingModel> update(
      String id, List<double> newVector) async {
    final now = DateTime.now().toUtc().toIso8601String();

    execute('''
      UPDATE content_embeddings SET
        embedding_vector = ?,
        updated_at = ?
      WHERE id = ?
    ''', [
      newVector.toString(),
      now,
      id,
    ]);

    // Return updated content
    final result = await querySingle(
      'SELECT * FROM content_embeddings WHERE id = ?',
      [id],
    );

    if (result != null) {
      return ContentEmbeddingModel.fromMap(result);
    }
    throw Exception('Content embedding not found');
  }

  /// Delete content embedding
  Future<void> delete(String id) async {
    execute('DELETE FROM content_embeddings WHERE id = ?', [id]);
  }

  /// Calculate cosine similarity between two vectors
  double _calculateCosineSimilarity(
      List<double> vectorA, List<double> vectorB) {
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

    return dotProduct / (_sqrt(normA) * _sqrt(normB));
  }

  double _sqrt(double x) {
    if (x < 0) return double.nan;
    if (x == 0 || x.isInfinite) return x;

    double result = x;
    double epsilon = 1e-10;

    while ((result * result - x).abs() > epsilon) {
      result = (result + x / result) / 2;
    }

    return result;
  }
}
