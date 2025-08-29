import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

void main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final ip = InternetAddress.anyIPv4;

  final app = Router();

  // In-memory state
  Map<String, dynamic> currentUser = _demoUser();
  String accessToken = 'demo_access_token';
  String refreshToken = 'demo_refresh_token';

  // Health/version
  app.get('/v1/health', _json((Request req) => {'status': 'ok'}));
  app.get('/v1/version', _json((Request req) => {'version': '0.1.0'}));

  // Auth
  app.post('/v1/auth/login', _json((Request req) async {
    final body = await _readJson(req);
    final email = body['email']?.toString() ?? '';
    final password = body['password']?.toString() ?? '';

    // Super-simple auth check
    if (email.isEmpty || password.isEmpty) {
      return Response(400, body: jsonEncode({'message': 'Invalid credentials'}));
    }

    // Update demo user email
    currentUser = {
      ...currentUser,
      'email': email,
      'name': currentUser['name'] ?? 'Demo User',
    };

    accessToken = 'access_${DateTime.now().millisecondsSinceEpoch}';
    refreshToken = 'refresh_${DateTime.now().millisecondsSinceEpoch}';

    return {
      'user': currentUser,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': 3600,
      'token_type': 'Bearer',
    };
  }));

  app.post('/v1/auth/register', _json((Request req) async {
    final body = await _readJson(req);
    final email = body['email']?.toString() ?? 'demo@example.com';
    final name = body['name']?.toString() ?? 'Demo User';
    currentUser = _demoUser(email: email, name: name);
    accessToken = 'access_${DateTime.now().millisecondsSinceEpoch}';
    refreshToken = 'refresh_${DateTime.now().millisecondsSinceEpoch}';
    return {
      'user': currentUser,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': 3600,
      'token_type': 'Bearer',
    };
  }));

  app.post('/v1/auth/logout', _json((Request req) => {'ok': true}));

  app.post('/v1/auth/refresh', _json((Request req) async {
    final body = await _readJson(req);
    final incoming = body['refresh_token']?.toString();
    if (incoming == null || incoming.isEmpty) {
      return Response(400, body: jsonEncode({'message': 'Missing refresh_token'}));
    }
    accessToken = 'access_${DateTime.now().millisecondsSinceEpoch}';
    refreshToken = 'refresh_${DateTime.now().millisecondsSinceEpoch}';
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': 3600,
      'token_type': 'Bearer',
    };
  }));

  app.post('/v1/auth/forgot-password', _json((Request req) => {'ok': true}));
  app.post('/v1/auth/reset-password', _json((Request req) => {'ok': true}));
  app.post('/v1/auth/send-email-verification', _json((Request req) => {'ok': true}));
  app.post('/v1/auth/verify-email/<token>', _json((Request req, String token) => {'ok': true, 'token': token}));

  // User profile
  app.get('/v1/user/profile', _json((Request req) => {'user': currentUser}));

  app.put('/v1/user/profile', _json((Request req) async {
    final body = await _readJson(req);
    currentUser = {...currentUser, ...body};
    return {'user': currentUser};
  }));

  app.put('/v1/user/change-password', _json((Request req) async {
    // no-op
    return {'ok': true};
  }));

  // Middlewares: CORS + JSON content-type + logging
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addMiddleware(_jsonContentType())
      .addHandler(app);

  final server = await serve(handler, ip, port);
  print('Demo API server listening on http://${server.address.host}:${server.port}');
}

Map<String, dynamic> _demoUser({String email = 'demo@example.com', String name = 'Demo User'}) {
  final now = DateTime.now().toUtc();
  return {
    'id': 'user_123',
    'email': email,
    'name': name,
    'cpf': null,
    'phone': null,
    'dateOfBirth': null,
    'avatar': null,
    'isEmailVerified': true,
    'isPhoneVerified': false,
    'createdAt': now.toIso8601String(),
    'updatedAt': now.toIso8601String(),
    'preferences': {
      'language': 'pt-BR',
      'theme': 'system',
      'notificationsEnabled': true,
      'emailNotifications': true,
      'pushNotifications': true,
      'smsNotifications': false,
      'newsletter': false,
    },
    'addresses': [],
  };
}

// Helpers
Middleware _jsonContentType() => (inner) => (req) async {
      final res = await inner(req);
      return res.change(headers: {
        ...res.headers,
        HttpHeaders.contentTypeHeader: ContentType.json.mimeType,
      });
    };

Handler _json(dynamic fn) => (Request req, [a, b, c]) async {
      final result = await Function.apply(fn, _filterArgs([req, a, b, c]));
      if (result is Response) return result;
      return Response.ok(jsonEncode(result));
    };

List _filterArgs(List args) => args.where((e) => e != null).toList();

Future<Map<String, dynamic>> _readJson(Request req) async {
  final body = await req.readAsString();
  if (body.isEmpty) return {};
  final dynamic decoded = jsonDecode(body);
  return decoded is Map<String, dynamic> ? decoded : {};
}
