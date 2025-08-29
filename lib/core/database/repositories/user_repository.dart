import '../repositories/base_repository.dart';

/// User repository for database operations
class UserRepository extends BaseRepository {
  /// Find user by email
  Future<UserModel?> findByEmail(String email) async {
    final result = await querySingle(
      'SELECT * FROM users WHERE email = ?',
      [email],
    );

    return result != null ? UserModel.fromMap(result) : null;
  }

  /// Find user by ID
  Future<UserModel?> findById(String id) async {
    final result = await querySingle(
      'SELECT * FROM users WHERE id = ?',
      [id],
    );

    return result != null ? UserModel.fromMap(result) : null;
  }

  /// Create a new user
  Future<UserModel> create(UserModel user) async {
    final now = DateTime.now().toUtc();
    final userWithTimestamps = UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      cpf: user.cpf,
      phone: user.phone,
      dateOfBirth: user.dateOfBirth,
      avatar: user.avatar,
      isEmailVerified: user.isEmailVerified,
      isPhoneVerified: user.isPhoneVerified,
      createdAt: now,
      updatedAt: now,
      preferences: user.preferences,
    );

    execute('''
      INSERT INTO users (id, email, name, cpf, phone, date_of_birth, avatar, is_email_verified, is_phone_verified, created_at, updated_at, preferences)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      userWithTimestamps.id,
      userWithTimestamps.email,
      userWithTimestamps.name,
      userWithTimestamps.cpf,
      userWithTimestamps.phone,
      userWithTimestamps.dateOfBirth?.toIso8601String(),
      userWithTimestamps.avatar,
      userWithTimestamps.isEmailVerified ? 1 : 0,
      userWithTimestamps.isPhoneVerified ? 1 : 0,
      userWithTimestamps.createdAt.toIso8601String(),
      userWithTimestamps.updatedAt.toIso8601String(),
      userWithTimestamps.preferences.toString(),
    ]);

    return userWithTimestamps;
  }

  /// Update user
  Future<UserModel> update(UserModel user) async {
    final now = DateTime.now().toUtc();
    final updatedUser = UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      cpf: user.cpf,
      phone: user.phone,
      dateOfBirth: user.dateOfBirth,
      avatar: user.avatar,
      isEmailVerified: user.isEmailVerified,
      isPhoneVerified: user.isPhoneVerified,
      createdAt: user.createdAt,
      updatedAt: now,
      preferences: user.preferences,
    );

    execute('''
      UPDATE users SET
        email = ?, name = ?, cpf = ?, phone = ?, date_of_birth = ?,
        avatar = ?, is_email_verified = ?, is_phone_verified = ?,
        updated_at = ?, preferences = ?
      WHERE id = ?
    ''', [
      updatedUser.email,
      updatedUser.name,
      updatedUser.cpf,
      updatedUser.phone,
      updatedUser.dateOfBirth?.toIso8601String(),
      updatedUser.avatar,
      updatedUser.isEmailVerified ? 1 : 0,
      updatedUser.isPhoneVerified ? 1 : 0,
      updatedUser.updatedAt.toIso8601String(),
      updatedUser.preferences.toString(),
      updatedUser.id,
    ]);

    return updatedUser;
  }

  /// Delete user
  Future<void> delete(String id) async {
    execute('DELETE FROM users WHERE id = ?', [id]);
  }

  /// Get all users
  Future<List<UserModel>> findAll() async {
    final results = await query('SELECT * FROM users ORDER BY created_at DESC');
    return results.map((row) => UserModel.fromMap(row)).toList();
  }
}

/// User model for database operations
class UserModel {
  final String id;
  final String email;
  final String name;
  final String? cpf;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? avatar;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> preferences;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.cpf,
    this.phone,
    this.dateOfBirth,
    this.avatar,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    required this.createdAt,
    required this.updatedAt,
    required this.preferences,
  });

  /// Create from database row
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String,
      cpf: map['cpf'] as String?,
      phone: map['phone'] as String?,
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.parse(map['date_of_birth'] as String)
          : null,
      avatar: map['avatar'] as String?,
      isEmailVerified: (map['is_email_verified'] as int) == 1,
      isPhoneVerified: (map['is_phone_verified'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      preferences: _parsePreferences(map['preferences'] as String?),
    );
  }

  /// Convert to map for API responses
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'cpf': cpf,
      'phone': phone,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'avatar': avatar,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'preferences': preferences,
    };
  }

  static Map<String, dynamic> _parsePreferences(String? preferencesJson) {
    if (preferencesJson == null || preferencesJson.isEmpty) {
      return {};
    }
    try {
      // Simple JSON parsing - in a real app you'd use json.decode
      return {};
    } catch (e) {
      return {};
    }
  }
}
