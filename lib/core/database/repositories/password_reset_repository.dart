import '../repositories/base_repository.dart';

/// Password reset data model
class PasswordResetModel {
  final String id;
  final String userId;
  final String token;
  final DateTime expiresAt;
  final DateTime createdAt;

  const PasswordResetModel({
    required this.id,
    required this.userId,
    required this.token,
    required this.expiresAt,
    required this.createdAt,
  });

  /// Create PasswordResetModel from database row
  factory PasswordResetModel.fromMap(Map<String, dynamic> map) {
    return PasswordResetModel(
      id: map['id'],
      userId: map['user_id'],
      token: map['token'],
      expiresAt: DateTime.parse(map['expires_at']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  /// Convert PasswordResetModel to database row
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'token': token,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Check if reset token is expired
  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  /// Check if reset token is valid (not expired)
  bool get isValid => !isExpired;
}

/// Password reset repository for database operations
class PasswordResetRepository extends BaseRepository {

  /// Create a new password reset request
  Future<PasswordResetModel> create(PasswordResetModel reset) async {
    execute('''
      INSERT INTO password_resets (id, user_id, token, expires_at, created_at)
      VALUES (?, ?, ?, ?, ?)
    ''', [
      reset.id,
      reset.userId,
      reset.token,
      reset.expiresAt.toIso8601String(),
      reset.createdAt.toIso8601String(),
    ]);

    return reset;
  }

  /// Find password reset by token
  Future<PasswordResetModel?> findByToken(String token) async {
    final result = await querySingle(
      'SELECT * FROM password_resets WHERE token = ?',
      [token],
    );

    if (result != null) {
      return PasswordResetModel.fromMap(result);
    }
    return null;
  }

  /// Find password resets by user ID
  Future<List<PasswordResetModel>> findByUserId(String userId) async {
    final results = await query(
      'SELECT * FROM password_resets WHERE user_id = ? ORDER BY created_at DESC',
      [userId],
    );

    return results.map((row) => PasswordResetModel.fromMap(row)).toList();
  }

  /// Delete password reset by ID
  Future<void> delete(String id) async {
    execute('DELETE FROM password_resets WHERE id = ?', [id]);
  }

  /// Delete password resets by user ID
  Future<void> deleteByUserId(String userId) async {
    execute('DELETE FROM password_resets WHERE user_id = ?', [userId]);
  }

  /// Delete expired password resets
  Future<void> deleteExpired() async {
    final now = DateTime.now().toUtc().toIso8601String();
    execute('DELETE FROM password_resets WHERE expires_at < ?', [now]);
  }

  /// Get all valid (non-expired) password resets for a user
  Future<List<PasswordResetModel>> getValidResetsForUser(String userId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final results = await query('''
      SELECT * FROM password_resets
      WHERE user_id = ? AND expires_at > ?
      ORDER BY created_at DESC
    ''', [userId, now]);

    return results.map((row) => PasswordResetModel.fromMap(row)).toList();
  }
}
