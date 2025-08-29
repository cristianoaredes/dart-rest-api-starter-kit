import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../../../core/utils/handler_utils.dart';
import '../../../core/database/repositories/user_repository.dart';
import '../services/user_service.dart';

/// User handler with service layer
class UserHandler {
  static late final UserService _userService;

  /// Initialize services and repositories
  static Future<void> initialize() async {
    final userRepository = UserRepository();

    _userService = UserService(userRepository: userRepository);
  }

  /// Get user profile endpoint
  static Handler getProfile() {
    return HandlerUtils.jsonHandler((Request request) async {
      try {
        // In a real app, you'd get user ID from JWT token or session
        // For now, we'll use the demo user
        const userId = 'user_123';
        final user = await _userService.getUserProfile(userId);
        return {'user': user.toJson()};
      } on UserException catch (e) {
        return Response(404, body: jsonEncode({'message': e.message}));
      } catch (e) {
        return Response(500, body: jsonEncode({'message': 'Internal server error'}));
      }
    });
  }

  /// Update user profile endpoint
  static Handler updateProfile() {
    return HandlerUtils.jsonHandlerWithBody((Request request, Map<String, dynamic> body) async {
      try {
        // In a real app, you'd get user ID from JWT token or session
        const userId = 'user_123';
        final user = await _userService.updateUserProfile(userId, body);
        return {'user': user.toJson()};
      } on UserException catch (e) {
        return Response(404, body: jsonEncode({'message': e.message}));
      } catch (e) {
        return Response(500, body: jsonEncode({'message': 'Internal server error'}));
      }
    });
  }

  /// Change password endpoint
  static Handler changePassword() {
    return HandlerUtils.jsonHandlerWithBody((Request request, Map<String, dynamic> body) async {
      try {
        const userId = 'user_123'; // In real app, get from JWT
        final currentPassword = body['current_password']?.toString() ?? '';
        final newPassword = body['new_password']?.toString() ?? '';
        final message = await _userService.changePassword(userId, currentPassword, newPassword);
        return {'message': message};
      } on UserException catch (e) {
        return Response(400, body: jsonEncode({'message': e.message}));
      } catch (e) {
        return Response(500, body: jsonEncode({'message': 'Internal server error'}));
      }
    });
  }
}
