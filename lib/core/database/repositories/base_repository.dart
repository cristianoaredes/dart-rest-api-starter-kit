import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

/// Base repository class with common database operations
abstract class BaseRepository {
  Database? _database;

  /// Get database instance
  Future<Database> get database async {
    _database ??= sqlite3.open(await _getDatabasePath());
    return _database!;
  }

  /// Execute query
  Future<List<Map<String, dynamic>>> query(String sql, [List<dynamic>? params]) async {
    final db = await database;
    final result = db.select(sql, params ?? []);
    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  /// Execute single query
  Future<Map<String, dynamic>?> querySingle(String sql, [List<dynamic>? params]) async {
    final results = await query(sql, params);
    return results.isNotEmpty ? results.first : null;
  }

  /// Execute command
  Future<void> execute(String sql, [List<dynamic>? params]) async {
    final db = await database;
    db.execute(sql, params ?? []);
  }

  /// Get database file path
  Future<String> _getDatabasePath() async {
    final directory = Directory.current;
    final dbPath = '${directory.path}/data/dart_rest_api_starter_kit.db';

    // Ensure the data directory exists
    final dataDir = Directory('${directory.path}/data');
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }

    return dbPath;
  }
}
