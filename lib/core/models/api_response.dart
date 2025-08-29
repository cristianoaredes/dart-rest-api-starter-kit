/// Base response model for API responses
class ApiResponse {
  final dynamic data;
  final String? message;
  final int statusCode;

  const ApiResponse({
    required this.data,
    this.message,
    this.statusCode = 200,
  });

  Map<String, dynamic> toJson() {
    return {
      if (data != null) 'data': data,
      if (message != null) 'message': message,
    };
  }
}

/// Common utilities for handling JSON responses
class ResponseUtils {
  static Map<String, dynamic> jsonResponse(dynamic data, {String? message}) {
    return {
      if (data != null) 'data': data,
      if (message != null) 'message': message,
    };
  }

  static Map<String, dynamic> errorResponse(String message, {int statusCode = 400}) {
    return {
      'error': message,
      'statusCode': statusCode,
    };
  }

  static Map<String, dynamic> successResponse(dynamic data, {String? message}) {
    return {
      if (data != null) 'data': data,
      if (message != null) 'message': message,
    };
  }
}
