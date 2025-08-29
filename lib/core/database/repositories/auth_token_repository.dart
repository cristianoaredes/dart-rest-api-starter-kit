import '../repositories/base_repository.dart';

/// Auth token data model
class AuthTokenModel {
  final String id;
  final String userId;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final DateTime createdAt;

  const AuthTokenModel({
    required this.id,
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.createdAt,
  });

  /// Create AuthTokenModel from database row
  factory AuthTokenModel.fromMap(Map<String, dynamic> map) {
    return AuthTokenModel(
      id: map['id'],
      userId: map['user_id'],
      accessToken: map['access_token'],
      refreshToken: map['refresh_token'],
      expiresAt: DateTime.parse(map['expires_at']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  /// Convert AuthTokenModel to database row
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Check if token is expired
  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  /// Check if token is valid (not expired)
  bool get isValid => !isExpired;
}

/// Auth token repository for database operations
class AuthTokenRepository extends BaseRepository {

  /// Create a new auth token
  Future<AuthTokenModel> create(AuthTokenModel token) async {
    execute('''
      INSERT INTO auth_tokens (id, user_id, access_token, refresh_token, expires_at, created_at)
      VALUES (?, ?, ?, ?, ?, ?)
    ''', [
      token.id,
      token.userId,
      token.accessToken,
      token.refreshToken,
      token.expiresAt.toIso8601String(),
      token.createdAt.toIso8601String(),
    ]);

    return token;
  }

  /// Find auth token by access token
  Future<AuthTokenModel?> findByAccessToken(String accessToken) async {
    final result = await querySingle(
      'SELECT * FROM auth_tokens WHERE access_token = ?',
      [accessToken],
    );

    return result != null ? AuthTokenModel.fromMap(result) : null;
  }

  /// Find auth token by refresh token
  Future<AuthTokenModel?> findByRefreshToken(String refreshToken) async {
    final result = await querySingle(
      'SELECT * FROM auth_tokens WHERE refresh_token = ?',
      [refreshToken],
    );

    if (result != null) {
      return AuthTokenModel.fromMap(result);
    }
    return null;
  }

  /// Find auth tokens by user ID
  Future<List<AuthTokenModel>> findByUserId(String userId) async {
    final results = await query(
      'SELECT * FROM auth_tokens WHERE user_id = ? ORDER BY created_at DESC',
      [userId],
    );

    return results.map((row) => AuthTokenModel.fromMap(row)).toList();
  }

  /// Delete auth token by ID
  Future<void> delete(String id) async {
    execute('DELETE FROM auth_tokens WHERE id = ?', [id]);
  }

  /// Delete auth tokens by user ID
  Future<void> deleteByUserId(String userId) async {
    execute('DELETE FROM auth_tokens WHERE user_id = ?', [userId]);
  }

  /// Delete expired tokens
  Future<void> deleteExpired() async {
    final now = DateTime.now().toUtc().toIso8601String();
    execute('DELETE FROM auth_tokens WHERE expires_at < ?', [now]);
  }

  /// Update access token
  Future<void> updateAccessToken(String id, String newAccessToken, DateTime newExpiry) async {
    execute('''
      UPDATE auth_tokens SET
        access_token = ?,
        expires_at = ?
      WHERE id = ?
    ''', [
      newAccessToken,
      newExpiry.toIso8601String(),
      id,
    ]);
  }

  /// Get all valid tokens for a user
  Future<List<AuthTokenModel>> getValidTokensForUser(String userId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final results = await query('''
      SELECT * FROM auth_tokens
      WHERE user_id = ? AND expires_at > ?
      ORDER BY created_at DESC
    ''', [userId, now]);

    return results.map((row) => AuthTokenModel.fromMap(row)).toList();
  }
}
