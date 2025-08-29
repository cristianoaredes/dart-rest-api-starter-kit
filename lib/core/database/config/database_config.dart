import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as path;

/// Database configuration and connection manager
class DatabaseConfig {
  static Database? _database;
  static const String _dbFileName = 'mock_server.db';

  /// Get the database instance (singleton pattern)
  static Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initializeDatabase();
    return _database!;
  }

  /// Initialize the database connection
  static Future<Database> _initializeDatabase() async {
    // Get the database file path
    final dbPath = await _getDatabasePath();

    // Initialize SQLite database
    final db = sqlite3.open(dbPath);

    // Create tables if they don't exist
    await _createTables(db);

    // Seed with initial data
    await _seedDatabase(db);

    return db;
  }

  /// Get the database file path
  static Future<String> _getDatabasePath() async {
    final directory = Directory.current;
    final dbPath = path.join(directory.path, 'data', _dbFileName);

    // Ensure the data directory exists
    final dataDir = Directory(path.dirname(dbPath));
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }

    return dbPath;
  }

  /// Create database tables
  static Future<void> _createTables(Database db) async {
    // Create users table
    db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        cpf TEXT,
        phone TEXT,
        date_of_birth TEXT,
        avatar TEXT,
        is_email_verified INTEGER DEFAULT 1,
        is_phone_verified INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        preferences TEXT
      )
    ''');

    // Create auth_tokens table for refresh tokens
    db.execute('''
      CREATE TABLE IF NOT EXISTS auth_tokens (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        access_token TEXT NOT NULL,
        refresh_token TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create password_resets table
    db.execute('''
      CREATE TABLE IF NOT EXISTS password_resets (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        token TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create AI tables
    _createAiTables(db);
  }

  /// Create AI-specific tables
  static void _createAiTables(Database db) {
    // User embeddings for recommendation system
    db.execute('''
      CREATE TABLE IF NOT EXISTS user_embeddings (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        embedding_vector TEXT NOT NULL, -- JSON array of floats
        embedding_type TEXT NOT NULL, -- 'profile', 'behavior', 'preferences'
        model_version TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Content/service embeddings
    db.execute('''
      CREATE TABLE IF NOT EXISTS content_embeddings (
        id TEXT PRIMARY KEY,
        content_type TEXT NOT NULL, -- 'service', 'news', 'document', 'emergency'
        content_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        embedding_vector TEXT NOT NULL, -- JSON array of floats
        category TEXT,
        tags TEXT, -- JSON array of tags
        model_version TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // User interactions for recommendation system
    db.execute('''
      CREATE TABLE IF NOT EXISTS user_interactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        content_type TEXT NOT NULL,
        content_id TEXT NOT NULL,
        interaction_type TEXT NOT NULL, -- 'view', 'click', 'save', 'share', 'rate'
        rating REAL, -- 1.0 to 5.0 for rated content
        duration_seconds INTEGER, -- time spent viewing
        metadata TEXT, -- JSON additional data
        timestamp TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Recommendations cache
    db.execute('''
      CREATE TABLE IF NOT EXISTS recommendations (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        recommendation_type TEXT NOT NULL, -- 'content', 'service', 'personalized'
        recommended_items TEXT NOT NULL, -- JSON array of recommended item IDs
        scores TEXT, -- JSON object with scores for each recommendation
        algorithm_used TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // AI model analytics
    db.execute('''
      CREATE TABLE IF NOT EXISTS ai_analytics (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        event_type TEXT NOT NULL, -- 'embedding_generated', 'recommendation_shown', 'similarity_search'
        model_name TEXT NOT NULL,
        model_version TEXT NOT NULL,
        input_tokens INTEGER,
        output_tokens INTEGER,
        processing_time_ms INTEGER,
        accuracy_score REAL,
        feedback_score REAL, -- -1 to 1 user feedback
        metadata TEXT, -- JSON additional context
        timestamp TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL
      )
    ''');

    // Search queries for semantic search
    db.execute('''
      CREATE TABLE IF NOT EXISTS search_queries (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        query_text TEXT NOT NULL,
        query_embedding TEXT, -- JSON array of floats
        search_type TEXT NOT NULL, -- 'semantic', 'keyword', 'category'
        results_count INTEGER,
        clicked_result_id TEXT,
        model_version TEXT,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL
      )
    ''');
  }

  /// Seed database with initial demo data
  static Future<void> _seedDatabase(Database db) async {
    // Check if demo user exists
    final result = db.select('SELECT COUNT(*) as count FROM users WHERE email = ?', ['demo@example.com']);

    if (result.isNotEmpty && result[0]['count'] == 0) {
      // Create demo user
      final now = DateTime.now().toUtc().toIso8601String();

      db.execute('''
        INSERT INTO users (id, email, name, cpf, phone, date_of_birth, avatar, is_email_verified, is_phone_verified, created_at, updated_at, preferences)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        'user_123',
        'demo@example.com',
        'Demo User',
        null,
        null,
        null,
        null,
        1,
        0,
        now,
        now,
        '{"language": "pt-BR", "theme": "system", "notificationsEnabled": true, "emailNotifications": true, "pushNotifications": true, "smsNotifications": false, "newsletter": false}'
      ]);

      // Seed AI demo data
      _seedAiDemoData(db, 'user_123', now);

      print('Database seeded with demo user and AI data');
    }
  }

  /// Seed demo AI data
  static void _seedAiDemoData(Database db, String userId, String now) {
    // Demo user embedding
    db.execute('''
      INSERT INTO user_embeddings (id, user_id, embedding_vector, embedding_type, model_version, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', [
      'embedding_user_123_profile',
      userId,
      '[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 0.9, 0.8, 0.7, 0.6, 0.5]',
      'profile',
      'demo-v1.0',
      now,
      now,
    ]);

    // Demo content embeddings
    final contents = [
      {
        'id': 'service_1',
        'type': 'service',
        'title': 'Emissão de Carteira de Identidade',
        'description': 'Serviço para emissão de RG',
        'category': 'documentos',
        'tags': '["identidade", "documento", "rg"]',
        'embedding': '[0.2, 0.3, 0.1, 0.5, 0.4, 0.8, 0.6, 0.9, 0.7, 0.1, 0.3, 0.2, 0.4, 0.5, 0.6]'
      },
      {
        'id': 'service_2',
        'type': 'service',
        'title': 'Consulta de IPTU',
        'description': 'Verificar valor do IPTU',
        'category': 'financeiro',
        'tags': '["iptu", "imposto", "financeiro"]',
        'embedding': '[0.3, 0.1, 0.4, 0.2, 0.6, 0.5, 0.8, 0.7, 0.9, 0.2, 0.1, 0.3, 0.5, 0.4, 0.7]'
      },
      {
        'id': 'news_1',
        'type': 'news',
        'title': 'Nova legislação ambiental',
        'description': 'Mudanças na legislação de meio ambiente',
        'category': 'meio-ambiente',
        'tags': '["meio-ambiente", "lei", "legislação"]',
        'embedding': '[0.4, 0.5, 0.2, 0.3, 0.1, 0.7, 0.6, 0.8, 0.9, 0.3, 0.2, 0.1, 0.6, 0.5, 0.4]'
      }
    ];

    for (final content in contents) {
      db.execute('''
        INSERT INTO content_embeddings (id, content_type, content_id, title, description, embedding_vector, category, tags, model_version, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        'embedding_${content['id']}',
        content['type'],
        content['id'],
        content['title'],
        content['description'],
        content['embedding'],
        content['category'],
        content['tags'],
        'demo-v1.0',
        now,
        now,
      ]);
    }

    // Demo user interactions
    db.execute('''
      INSERT INTO user_interactions (id, user_id, content_type, content_id, interaction_type, rating, duration_seconds, metadata, timestamp)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      'interaction_1',
      userId,
      'service',
      'service_1',
      'view',
      4.5,
      120,
      '{"source": "home", "device": "mobile"}',
      now,
    ]);

    // Demo recommendation
    final futureTime = DateTime.now().toUtc().add(Duration(hours: 24)).toIso8601String();
    db.execute('''
      INSERT INTO recommendations (id, user_id, recommendation_type, recommended_items, scores, algorithm_used, expires_at, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      'rec_user_123_content',
      userId,
      'content',
      '["service_2", "news_1"]',
      '{"service_2": 0.85, "news_1": 0.72}',
      'cosine_similarity',
      futureTime,
      now,
    ]);
  }

  /// Close the database connection
  static Future<void> close() async {
    if (_database != null) {
      _database!.dispose();
      _database = null;
    }
  }

  /// Reset database (for testing purposes)
  static Future<void> reset() async {
    if (_database != null) {
      _database!.dispose();
      _database = null;
    }

    final dbPath = await _getDatabasePath();
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
  }
}
