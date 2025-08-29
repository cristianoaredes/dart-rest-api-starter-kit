/// User model for authentication
class User {
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

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.cpf,
    this.phone,
    this.dateOfBirth,
    this.avatar,
    this.isEmailVerified = true,
    this.isPhoneVerified = false,
    required this.createdAt,
    required this.updatedAt,
    required this.preferences,
  });

  Map<String, dynamic> toJson() {
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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      cpf: json['cpf'],
      phone: json['phone'],
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth']) : null,
      avatar: json['avatar'],
      isEmailVerified: json['isEmailVerified'] ?? true,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      preferences: json['preferences'] ?? {},
    );
  }
}

/// Auth response model
class AuthResponse {
  final User user;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;

  const AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
  });

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
      'token_type': tokenType,
    };
  }
}
