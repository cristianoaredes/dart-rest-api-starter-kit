import 'dart:math';
import '../../../core/database/repositories/user_repository.dart';
import '../../../core/database/repositories/auth_token_repository.dart';
import '../../../core/database/repositories/password_reset_repository.dart';
import '../models/auth_models.dart';

/// Authentication service - handles business logic for authentication
class AuthService {
  final UserRepository _userRepository;
  final AuthTokenRepository _authTokenRepository;
  final PasswordResetRepository _passwordResetRepository;

  AuthService({
    required UserRepository userRepository,
    required AuthTokenRepository authTokenRepository,
    required PasswordResetRepository passwordResetRepository,
  })  : _userRepository = userRepository,
        _authTokenRepository = authTokenRepository,
        _passwordResetRepository = passwordResetRepository;

  /// Login user and return auth response
  Future<AuthResponse> login(String email, String password) async {
    // Validate credentials
    if (email.isEmpty || password.isEmpty) {
      throw AuthException('Invalid credentials');
    }

    // Find user by email
    final userModel = await _userRepository.findByEmail(email);
    if (userModel == null) {
      throw AuthException('Invalid credentials');
    }

    // Generate new tokens
    final tokenPair = _generateTokenPair();
    final expiresAt = DateTime.now().toUtc().add(Duration(hours: 1));

    // Create auth token in database
    final authToken = AuthTokenModel(
      id: 'token_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
      userId: userModel.id,
      accessToken: tokenPair['access']!,
      refreshToken: tokenPair['refresh']!,
      expiresAt: expiresAt,
      createdAt: DateTime.now().toUtc(),
    );

    await _authTokenRepository.create(authToken);

    // Convert to response models
    final user = User.fromJson(userModel.toMap());
    return AuthResponse(
      user: user,
      accessToken: authToken.accessToken,
      refreshToken: authToken.refreshToken,
      expiresIn: 3600,
      tokenType: 'Bearer',
    );
  }

  /// Register new user and return auth response
  Future<AuthResponse> register(String email, String name, String password,
      {String? cpf, String? phone}) async {
    // Validate input
    if (email.isEmpty || name.isEmpty || password.isEmpty) {
      throw AuthException('Email, name, and password are required');
    }

    // Check if user already exists
    final existingUser = await _userRepository.findByEmail(email);
    if (existingUser != null) {
      throw AuthException('User already exists');
    }

    // Create new user
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
    final now = DateTime.now().toUtc();
    final newUser = UserModel(
      id: userId,
      email: email,
      name: name,
      cpf: cpf,
      phone: phone,
      createdAt: now,
      updatedAt: now,
      preferences: {
        'language': 'pt-BR',
        'theme': 'system',
        'notificationsEnabled': true,
        'emailNotifications': true,
        'pushNotifications': true,
        'smsNotifications': false,
        'newsletter': false,
      },
    );

    final createdUser = await _userRepository.create(newUser);

    // Generate tokens
    final tokenPair = _generateTokenPair();
    final expiresAt = DateTime.now().toUtc().add(Duration(hours: 1));

    // Create auth token
    final authToken = AuthTokenModel(
      id: 'token_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
      userId: createdUser.id,
      accessToken: tokenPair['access']!,
      refreshToken: tokenPair['refresh']!,
      expiresAt: expiresAt,
      createdAt: DateTime.now().toUtc(),
    );

    await _authTokenRepository.create(authToken);

    // Convert to response models
    final user = User.fromJson(createdUser.toMap());
    return AuthResponse(
      user: user,
      accessToken: authToken.accessToken,
      refreshToken: authToken.refreshToken,
      expiresIn: 3600,
      tokenType: 'Bearer',
    );
  }

  /// Logout user by deleting auth token
  Future<void> logout(String refreshToken) async {
    if (refreshToken.isNotEmpty) {
      // Find and delete the auth token
      final authToken = await _authTokenRepository.findByRefreshToken(refreshToken);
      if (authToken != null) {
        await _authTokenRepository.delete(authToken.id);
      }
    }
  }

  /// Refresh access token using refresh token
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    if (refreshToken.isEmpty) {
      throw AuthException('Missing refresh_token');
    }

    // Find the auth token
    final authToken = await _authTokenRepository.findByRefreshToken(refreshToken);
    if (authToken == null || authToken.isExpired) {
      throw AuthException('Invalid or expired refresh token');
    }

    // Generate new tokens
    final tokenPair = _generateTokenPair();
    final expiresAt = DateTime.now().toUtc().add(Duration(hours: 1));

    // Update the auth token
    await _authTokenRepository.updateAccessToken(
      authToken.id,
      tokenPair['access']!,
      expiresAt,
    );

    return {
      'access_token': tokenPair['access'],
      'refresh_token': tokenPair['refresh'],
      'expires_in': 3600,
      'token_type': 'Bearer',
    };
  }

  /// Create password reset token
  Future<String> createPasswordReset(String email) async {
    // Find user by email
    final user = await _userRepository.findByEmail(email);
    if (user == null) {
      // Don't reveal if user exists or not for security
      return 'If the email exists, password reset instructions have been sent';
    }

    // Create password reset token
    final resetToken = 'reset_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
    final expiresAt = DateTime.now().toUtc().add(Duration(hours: 24));

    final passwordReset = PasswordResetModel(
      id: 'reset_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
      userId: user.id,
      token: resetToken,
      expiresAt: expiresAt,
      createdAt: DateTime.now().toUtc(),
    );

    await _passwordResetRepository.create(passwordReset);

    return 'Password reset email sent';
  }

  /// Reset password using token
  Future<String> resetPassword(String token, String newPassword) async {
    if (token.isEmpty || newPassword.isEmpty) {
      throw AuthException('Token and new password are required');
    }

    // Find password reset token
    final passwordReset = await _passwordResetRepository.findByToken(token);
    if (passwordReset == null || passwordReset.isExpired) {
      throw AuthException('Invalid or expired reset token');
    }

    // Delete the used token
    await _passwordResetRepository.delete(passwordReset.id);

    return 'Password reset successfully';
  }

  /// Send email verification (mock implementation)
  Future<String> sendEmailVerification() async {
    // In a real app, you'd send an email with a verification token
    return 'Verification email sent';
  }

  /// Verify email using token (mock implementation)
  Future<Map<String, dynamic>> verifyEmail(String token) async {
    // In a real app, you'd validate the token and mark email as verified
    return {
      'message': 'Email verified successfully',
      'token': token,
    };
  }

  /// Generate access and refresh token pair
  Map<String, String> _generateTokenPair() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);

    return {
      'access': 'access_${timestamp}_${random}',
      'refresh': 'refresh_${timestamp}_${random}',
    };
  }
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}
