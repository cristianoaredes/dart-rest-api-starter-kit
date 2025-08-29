import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../../core/utils/handler_utils.dart';
import '../../../core/database/repositories/user_repository.dart';
import '../../../core/database/repositories/auth_token_repository.dart';
import '../../../core/database/repositories/password_reset_repository.dart';
import '../services/auth_service.dart';

/// Authentication handler with service layer
class AuthHandler {
  static late final AuthService _authService;

  /// Initialize services and repositories
  static Future<void> initialize() async {
    final userRepository = UserRepository();
    final authTokenRepository = AuthTokenRepository();
    final passwordResetRepository = PasswordResetRepository();

    _authService = AuthService(
      userRepository: userRepository,
      authTokenRepository: authTokenRepository,
      passwordResetRepository: passwordResetRepository,
    );
  }

  /// Login endpoint
  static Handler login() {
    return HandlerUtils.jsonHandlerWithBody((Request request, Map<String, dynamic> body) async {
      try {
        final email = body['email']?.toString() ?? '';
        final password = body['password']?.toString() ?? '';

        final authResponse = await _authService.login(email, password);
        return authResponse.toJson();
      } on AuthException catch (e) {
        return Response(401, body: jsonEncode({'message': e.message}));
      } catch (e) {
        return Response(500, body: jsonEncode({'message': 'Internal server error'}));
      }
    });
  }

  /// Register endpoint
  static Handler register() {
    return HandlerUtils.jsonHandlerWithBody((Request request, Map<String, dynamic> body) async {
      try {
        final email = body['email']?.toString() ?? '';
        final name = body['name']?.toString() ?? '';
        final password = body['password']?.toString() ?? '';
        final cpf = body['cpf']?.toString();
        final phone = body['phone']?.toString();

        final authResponse = await _authService.register(email, name, password,
            cpf: cpf, phone: phone);
        return authResponse.toJson();
      } on AuthException catch (e) {
        return Response(409, body: jsonEncode({'message': e.message}));
      } catch (e) {
        return Response(500, body: jsonEncode({'message': 'Internal server error'}));
      }
    });
  }

  /// Logout endpoint
  static Handler logout() {
    return HandlerUtils.jsonHandlerWithBody((Request request, Map<String, dynamic> body) async {
      try {
        final refreshToken = body['refresh_token']?.toString() ?? '';
        await _authService.logout(refreshToken);
        return {'message': 'Logged out successfully'};
      } catch (e) {
        return Response(500, body: jsonEncode({'message': 'Internal server error'}));
      }
    });
  }

  /// Refresh token endpoint
  static Handler refresh() {
    return HandlerUtils.jsonHandlerWithBody((Request request, Map<String, dynamic> body) async {
      try {
        final refreshToken = body['refresh_token']?.toString() ?? '';
        final tokenResponse = await _authService.refreshToken(refreshToken);
        return tokenResponse;
      } on AuthException catch (e) {
        return Response(401, body: jsonEncode({'message': e.message}));
      } catch (e) {
        return Response(500, body: jsonEncode({'message': 'Internal server error'}));
      }
    });
  }

  /// Forgot password endpoint
  static Handler forgotPassword() {
    return HandlerUtils.jsonHandlerWithBody((Request request, Map<String, dynamic> body) async {
      try {
        final email = body['email']?.toString() ?? '';
        final message = await _authService.createPasswordReset(email);
        return {'message': message};
      } on AuthException catch (e) {
        return Response(400, body: jsonEncode({'message': e.message}));
      } catch (e) {
        return Response(500, body: jsonEncode({'message': 'Internal server error'}));
      }
    });
  }

  /// Reset password endpoint
  static Handler resetPassword() {
    return HandlerUtils.jsonHandlerWithBody((Request request, Map<String, dynamic> body) async {
      try {
        final token = body['token']?.toString() ?? '';
        final newPassword = body['new_password']?.toString() ?? '';
        final message = await _authService.resetPassword(token, newPassword);
        return {'message': message};
      } on AuthException catch (e) {
        return Response(400, body: jsonEncode({'message': e.message}));
      } catch (e) {
        return Response(500, body: jsonEncode({'message': 'Internal server error'}));
      }
    });
  }

  /// Send email verification endpoint
  static Handler sendEmailVerification() {
    return HandlerUtils.jsonHandler((Request request) async {
      try {
        final message = await _authService.sendEmailVerification();
        return {'message': message};
      } catch (e) {
        return Response(500, body: jsonEncode({'message': 'Internal server error'}));
      }
    });
  }

  /// Verify email endpoint
  static Handler verifyEmail() {
    return HandlerUtils.jsonHandler((Request request) async {
      try {
        final token = request.url.pathSegments.last;
        final result = await _authService.verifyEmail(token);
        return result;
      } catch (e) {
        return Response(500, body: jsonEncode({'message': 'Internal server error'}));
      }
    });
  }
}
