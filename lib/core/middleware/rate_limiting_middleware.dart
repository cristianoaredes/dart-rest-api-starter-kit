import 'dart:collection';
import 'dart:convert';
import 'package:shelf/shelf.dart';

/// Rate limiting middleware for production
class RateLimitingMiddleware {
  final Map<String, Queue<DateTime>> _requestHistory = {};
  final int _maxRequests;
  final Duration _window;

  RateLimitingMiddleware({
    int maxRequests = 100,
    Duration window = const Duration(minutes: 15),
  }) : _maxRequests = maxRequests,
       _window = window;

  /// Rate limiting middleware
  Middleware get rateLimit {
    return (inner) => (Request request) async {
      try {
        // Get client identifier (IP address)
        final clientId = _getClientId(request);

        // Clean old requests
        _cleanOldRequests(clientId);

        // Check if rate limit exceeded
        if (_isRateLimitExceeded(clientId)) {
          final resetTime = _getResetTime(clientId);
          final remainingTime = resetTime.difference(DateTime.now());

          return Response(429, body: jsonEncode({
            'error': 'Too Many Requests',
            'message': 'Rate limit exceeded. Please try again later.',
            'retry_after': remainingTime.inSeconds,
            'reset_time': resetTime.toIso8601String(),
            'timestamp': DateTime.now().toIso8601String(),
          }), headers: {
            'X-RateLimit-Limit': _maxRequests.toString(),
            'X-RateLimit-Remaining': '0',
            'X-RateLimit-Reset': resetTime.millisecondsSinceEpoch.toString(),
            'Retry-After': remainingTime.inSeconds.toString(),
          });
        }

        // Record the request
        _recordRequest(clientId);

        // Add rate limit headers to response
        final response = await inner(request);
        final remainingRequests = _getRemainingRequests(clientId);
        final resetTime = _getResetTime(clientId);

        return response.change(headers: {
          ...response.headers,
          'X-RateLimit-Limit': _maxRequests.toString(),
          'X-RateLimit-Remaining': remainingRequests.toString(),
          'X-RateLimit-Reset': resetTime.millisecondsSinceEpoch.toString(),
        });

      } catch (e) {
        return Response(500, body: jsonEncode({
          'error': 'Internal Server Error',
          'message': 'Rate limiting error',
          'timestamp': DateTime.now().toIso8601String(),
        }));
      }
    };
  }

  /// Get client identifier from request
  String _getClientId(Request request) {
    // Try to get real IP from headers (for production with reverse proxy)
    final forwardedFor = request.headers['x-forwarded-for'];
    final realIp = request.headers['x-real-ip'];

    if (forwardedFor != null && forwardedFor.isNotEmpty) {
      return forwardedFor.split(',').first.trim();
    }

    if (realIp != null) {
      return realIp;
    }

    // For direct connections, return a default identifier
    return 'direct-connection';
  }

  /// Clean old requests from history
  void _cleanOldRequests(String clientId) {
    if (!_requestHistory.containsKey(clientId)) {
      return;
    }

    final cutoffTime = DateTime.now().subtract(_window);
    final queue = _requestHistory[clientId]!;

    while (queue.isNotEmpty && queue.first.isBefore(cutoffTime)) {
      queue.removeFirst();
    }
  }

  /// Check if rate limit is exceeded
  bool _isRateLimitExceeded(String clientId) {
    return (_requestHistory[clientId]?.length ?? 0) >= _maxRequests;
  }

  /// Record a new request
  void _recordRequest(String clientId) {
    if (!_requestHistory.containsKey(clientId)) {
      _requestHistory[clientId] = Queue<DateTime>();
    }

    _requestHistory[clientId]!.add(DateTime.now());
  }

  /// Get remaining requests for client
  int _getRemainingRequests(String clientId) {
    final currentRequests = _requestHistory[clientId]?.length ?? 0;
    return _maxRequests - currentRequests;
  }

  /// Get reset time for client
  DateTime _getResetTime(String clientId) {
    if (!_requestHistory.containsKey(clientId) ||
        _requestHistory[clientId]!.isEmpty) {
      return DateTime.now().add(_window);
    }

    final oldestRequest = _requestHistory[clientId]!.first;
    return oldestRequest.add(_window);
  }

  /// Get rate limit statistics
  Map<String, dynamic> getStats() {
    final clients = <Map<String, dynamic>>[];
    _requestHistory.forEach((clientId, queue) {
      clients.add({
        'client_id': clientId,
        'requests': queue.length,
        'oldest_request': queue.isNotEmpty ? queue.first.toIso8601String() : null,
        'remaining_requests': _maxRequests - queue.length,
        'reset_time': _getResetTime(clientId).toIso8601String(),
      });
    });

    return {
      'total_clients': _requestHistory.length,
      'max_requests': _maxRequests,
      'window_seconds': _window.inSeconds,
      'clients': clients,
    };
  }
}
