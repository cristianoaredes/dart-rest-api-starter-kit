import '../../../core/database/repositories/user_repository.dart';
import '../../auth/models/auth_models.dart';

/// User service - handles business logic for user operations
class UserService {
  final UserRepository _userRepository;

  UserService({
    required UserRepository userRepository,
  }) : _userRepository = userRepository;

  /// Get user profile by ID
  Future<User> getUserProfile(String userId) async {
    final userModel = await _userRepository.findById(userId);

    if (userModel == null) {
      throw UserException('User not found');
    }

    return User.fromJson(userModel.toMap());
  }

  /// Update user profile
  Future<User> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    // Get current user
    final currentUser = await _userRepository.findById(userId);
    if (currentUser == null) {
      throw UserException('User not found');
    }

    // Create updated user model
    final updatedUser = UserModel(
      id: currentUser.id,
      email: updates['email'] ?? currentUser.email,
      name: updates['name'] ?? currentUser.name,
      cpf: updates['cpf'] ?? currentUser.cpf,
      phone: updates['phone'] ?? currentUser.phone,
      dateOfBirth: updates['dateOfBirth'] != null
          ? DateTime.parse(updates['dateOfBirth'])
          : currentUser.dateOfBirth,
      avatar: updates['avatar'] ?? currentUser.avatar,
      isEmailVerified: currentUser.isEmailVerified,
      isPhoneVerified: currentUser.isPhoneVerified,
      createdAt: currentUser.createdAt,
      updatedAt: DateTime.now().toUtc(),
      preferences: updates['preferences'] ?? currentUser.preferences,
    );

    // Update user in database
    final savedUser = await _userRepository.update(updatedUser);

    return User.fromJson(savedUser.toMap());
  }

  /// Change user password
  Future<String> changePassword(String userId, String currentPassword, String newPassword) async {
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      throw UserException('Both current_password and new_password are required');
    }

    // In a real app, you'd validate the current password against stored hash
    // For now, we'll just accept any current password

    return 'Password changed successfully';
  }

  /// Get all users (admin functionality)
  Future<List<User>> getAllUsers() async {
    final userModels = await _userRepository.findAll();
    return userModels.map((model) => User.fromJson(model.toMap())).toList();
  }

  /// Find user by email
  Future<User?> findUserByEmail(String email) async {
    final userModel = await _userRepository.findByEmail(email);
    return userModel != null ? User.fromJson(userModel.toMap()) : null;
  }
}

/// Custom exception for user-related errors
class UserException implements Exception {
  final String message;

  UserException(this.message);

  @override
  String toString() => message;
}
