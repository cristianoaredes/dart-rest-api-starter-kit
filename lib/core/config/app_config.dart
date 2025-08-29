import 'dart:convert';
import 'dart:io';

/// Production configuration management
class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  late final Map<String, dynamic> _config;

  /// Initialize configuration
  Future<void> initialize() async {
    _config = await _loadConfig();
  }

  /// Get configuration value
  T get<T>(String key, [T? defaultValue]) {
    final keys = key.split('.');
    dynamic current = _config;

    for (final k in keys) {
      if (current is Map && current.containsKey(k)) {
        current = current[k];
      } else {
        return defaultValue as T;
      }
    }

    return current as T;
  }

  /// Get all configuration
  Map<String, dynamic> get all => Map.from(_config);

  /// Load configuration from multiple sources
  Future<Map<String, dynamic>> _loadConfig() async {
    final config = <String, dynamic>{};

    // Load default configuration
    config.addAll(_getDefaultConfig());

    // Load from environment variables
    config.addAll(_loadFromEnvironment());

    // Load from config file if exists
    config.addAll(await _loadFromFile());

    return config;
  }

  /// Default configuration
  Map<String, dynamic> _getDefaultConfig() {
    return {
      'server': {
        'port': 8080,
        'host': '0.0.0.0',
        'timeout': 30,
      },
      'database': {
        'type': 'sqlite',
        'path': 'data/dart_rest_api_starter_kit.db',
        'max_connections': 10,
        'timeout': 30,
      },
      'cors': {
        'enabled': true,
        'origins': ['*'],
        'methods': ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
        'headers': ['content-type', 'authorization', 'x-requested-with'],
        'credentials': true,
      },
      'rate_limiting': {
        'enabled': true,
        'max_requests': 100,
        'window_minutes': 15,
      },
      'validation': {
        'max_body_size': 1048576, // 1MB
        'json_only': true,
      },
      'logging': {
        'enabled': true,
        'level': 'info',
        'include_headers': false,
        'include_body': false,
      },
      'monitoring': {
        'health_check_enabled': true,
        'metrics_enabled': false,
        'request_metrics': true,
      },
      'features': {
        'swagger_ui': true,
        'api_docs': true,
        'health_endpoints': true,
      },
    };
  }

  /// Load configuration from environment variables
  Map<String, dynamic> _loadFromEnvironment() {
    final config = <String, dynamic>{};

    // Server configuration
    if (Platform.environment.containsKey('PORT')) {
      config['server'] = {
        ...config['server'] ?? {},
        'port': int.tryParse(Platform.environment['PORT']!) ?? 8080,
      };
    }

    if (Platform.environment.containsKey('HOST')) {
      config['server'] = {
        ...config['server'] ?? {},
        'host': Platform.environment['HOST']!,
      };
    }

    // Database configuration
    if (Platform.environment.containsKey('DATABASE_TYPE')) {
      config['database'] = {
        ...config['database'] ?? {},
        'type': Platform.environment['DATABASE_TYPE']!,
      };
    }

    // CORS configuration
    if (Platform.environment.containsKey('CORS_ENABLED')) {
      config['cors'] = {
        ...config['cors'] ?? {},
        'enabled': Platform.environment['CORS_ENABLED']!.toLowerCase() == 'true',
      };
    }

    // Rate limiting configuration
    if (Platform.environment.containsKey('RATE_LIMIT_ENABLED')) {
      config['rate_limiting'] = {
        ...config['rate_limiting'] ?? {},
        'enabled': Platform.environment['RATE_LIMIT_ENABLED']!.toLowerCase() == 'true',
      };
    }

    // Environment detection
    config['environment'] = Platform.environment['ENVIRONMENT'] ?? 'development';

    return config;
  }

  /// Load configuration from file
  Future<Map<String, dynamic>> _loadFromFile() async {
    final config = <String, dynamic>{};

    try {
      final configFile = File('config/production.yaml');
      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        config.addAll(jsonDecode(content));
      }
    } catch (e) {
      // Log warning but don't fail
      print('Warning: Could not load config file: $e');
    }

    return config;
  }

  /// Get current environment
  String get environment => get('environment', 'development');

  /// Check if running in production
  bool get isProduction => environment == 'production';

  /// Check if running in development
  bool get isDevelopment => environment == 'development';

  /// Get server configuration
  Map<String, dynamic> get server => get('server', {});

  /// Get database configuration
  Map<String, dynamic> get database => get('database', {});

  /// Get CORS configuration
  Map<String, dynamic> get cors => get('cors', {});

  /// Get rate limiting configuration
  Map<String, dynamic> get rateLimiting => get('rate_limiting', {});

  /// Get validation configuration
  Map<String, dynamic> get validation => get('validation', {});

  /// Get logging configuration
  Map<String, dynamic> get logging => get('logging', {});

  /// Get monitoring configuration
  Map<String, dynamic> get monitoring => get('monitoring', {});

  /// Get features configuration
  Map<String, dynamic> get features => get('features', {});
}
