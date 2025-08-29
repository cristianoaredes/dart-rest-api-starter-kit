# Mock Server - Production Ready with Multi-Database Support

A production-ready mock server built with Dart/Shelf featuring multi-database support, comprehensive monitoring, and enterprise-grade architecture.

## 🚀 Quick Start

### Local Development (SQLite - Default)
```bash
cd mock_server
dart pub get
dart run
```

### Production with Supabase
```bash
export DATABASE_PROVIDER=supabase
export SUPABASE_URL=https://your-project.supabase.co
export SUPABASE_ANON_KEY=your-anon-key
export SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
export ENVIRONMENT=production

dart run
```

### Production with Firebase
```bash
export DATABASE_PROVIDER=firebase
export FIREBASE_PROJECT_ID=your-project-id
export FIREBASE_API_KEY=your-api-key
export FIREBASE_SERVICE_ACCOUNT_PATH=/path/to/service-account.json
export ENVIRONMENT=production

dart run
```

## 🗄️ Database Providers

### SQLite (Local Development)
- **Best for**: Development, testing, prototyping
- **Configuration**: Automatic (no setup required)
- **Features**: ACID transactions, fast queries, file-based

### Supabase (PostgreSQL Cloud)
- **Best for**: Production, real-time features, managed database
- **Features**: Real-time subscriptions, built-in authentication, managed PostgreSQL
- **Requirements**: Supabase project and API keys

### Firebase (Realtime Database)
- **Best for**: Mobile-first apps, real-time features, Google ecosystem
- **Features**: Real-time synchronization, offline support, Google services integration
- **Requirements**: Firebase project and service account

## 🔧 Environment Configuration

Create a `.env` file in the project root:

```env
# Server Configuration
PORT=8080
ENVIRONMENT=production
HOST=0.0.0.0

# Database Configuration
DATABASE_PROVIDER=sqlite
DATABASE_FILE=mock_server.db

# Supabase Configuration (if using Supabase)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Firebase Configuration (if using Firebase)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-api-key
FIREBASE_SERVICE_ACCOUNT_PATH=/path/to/service-account.json

# Logging & Monitoring
LOG_LEVEL=info
LOG_FORMAT=json
ENABLE_METRICS=true
METRICS_PORT=9090

# Security
CORS_ORIGINS=*
ENABLE_RATE_LIMITING=true
RATE_LIMIT_REQUESTS_PER_MINUTE=60

# AI Features
ENABLE_AI_FEATURES=true
EMBEDDING_MODEL_VERSION=demo-v1.0
RECOMMENDATION_ALGORITHM=cosine_similarity
```

## 📊 API Endpoints

### Authentication (`/v1/auth`)
```
POST /auth/login              # User login with JWT tokens
POST /auth/register           # User registration
POST /auth/logout             # Secure logout
POST /auth/refresh            # Token refresh
POST /auth/forgot-password    # Password reset request
POST /auth/reset-password     # Password reset
POST /auth/verify-email       # Email verification
```

### User Management (`/v1/user`)
```
GET  /user/profile            # Get user profile
PUT  /user/profile            # Update user profile
PUT  /user/change-password    # Change password
```

### AI Features (`/v1/ai`)
```
POST /ai/search/semantic      # Semantic search with embeddings
POST /ai/recommendations      # Personalized recommendations
POST /ai/embeddings/generate  # Generate content embeddings
POST /ai/interactions/track   # Track user interactions
POST /ai/analytics           # AI performance analytics
```

### Health & Monitoring (`/v1/health`)
```
GET  /health                  # Comprehensive health check
GET  /version                 # Version information
GET  /metrics                 # Prometheus metrics
GET  /health/database         # Database health check
```

## 🏗️ Architecture

### Feature-First Architecture
```
/lib/
├── core/
│   ├── database/             # Database layer with provider abstraction
│   │   ├── repositories/     # Data access layer
│   │   └── config/          # Database configuration
│   └── utils/               # Shared utilities
├── features/                 # Feature modules
│   ├── auth/                # Authentication feature
│   │   ├── handlers/        # HTTP handlers
│   │   ├── services/        # Business logic
│   │   ├── models/          # Feature models
│   │   └── routes/          # Feature routes
│   ├── user/                # User management
│   ├── ai/                  # AI features
│   └── health/              # Health checks
└── server.dart              # Main server configuration
```

### Service Layer Pattern
- **Handlers**: HTTP request/response handling
- **Services**: Business logic and validation
- **Repositories**: Data access abstraction
- **Database Providers**: Pluggable database implementations

## 🐳 Docker Deployment

### Dockerfile
```dockerfile
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/main.dart -o bin/server

FROM debian:stable-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=build /app/bin/server /app/bin/
COPY --from=build /app/data/ /app/data/
COPY --from=build /app/.env* /app/

WORKDIR /app
EXPOSE 8080
CMD ["/app/bin/server"]
```

### Docker Compose (Production)
```yaml
version: '3.8'
services:
  mock-server:
    build: .
    ports:
      - "8080:8080"
      - "9090:9090"  # Metrics port
    environment:
      - ENVIRONMENT=production
      - DATABASE_PROVIDER=supabase
      - SUPABASE_URL=${SUPABASE_URL}
      - SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
      - ENABLE_METRICS=true
    env_file:
      - .env
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/v1/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## 🚀 Production Deployment Options

### 1. Systemd Service
```ini
[Unit]
Description=Mock Server
After=network.target

[Service]
Type=simple
User=mock-server
WorkingDirectory=/opt/mock-server
ExecStart=/usr/local/bin/dart /opt/mock-server/bin/main.dart
EnvironmentFile=/opt/mock-server/.env
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### 2. PM2 (Node.js Process Manager)
```bash
npm install -g pm2
pm2 start ecosystem.config.js
```

### 3. Kubernetes Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mock-server
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mock-server
  template:
    metadata:
      labels:
        app: mock-server
    spec:
      containers:
      - name: mock-server
        image: your-registry/mock-server:latest
        ports:
        - containerPort: 8080
        envFrom:
        - configMapRef:
            name: mock-server-config
        - secretRef:
            name: mock-server-secrets
        livenessProbe:
          httpGet:
            path: /v1/health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /v1/health
            port: 8080
```

## 📈 Monitoring & Observability

### Health Checks
```bash
# Overall health
curl http://localhost:8080/v1/health

# Database health
curl http://localhost:8080/v1/health/database

# Version info
curl http://localhost:8080/v1/version
```

### Metrics (Prometheus)
When `ENABLE_METRICS=true`:
- **Endpoint**: `http://localhost:9090/metrics`
- **Metrics**: Request count, latency, error rates, database connections
- **Integration**: Ready for Prometheus scraping

### Logging
- **Structured JSON logging** for production
- **Configurable log levels** (debug, info, warn, error)
- **Request/response logging** with correlation IDs
- **Error tracking** with stack traces

## 🔒 Security Features

### Authentication & Authorization
- JWT token-based authentication
- Refresh token rotation
- Secure password hashing
- Role-based access control (RBAC)

### API Security
- CORS configuration
- Rate limiting per IP/client
- Input validation and sanitization
- SQL injection prevention
- XSS protection

### Infrastructure Security
- Non-root user execution
- Minimal Docker images
- Environment-based secrets
- Network segmentation
- Regular security updates

## 🔄 Database Switching Guide

### Step 1: Choose Your Database Provider

**For Development:**
```bash
export DATABASE_PROVIDER=sqlite
# No additional configuration needed
```

**For Production (Supabase):**
```bash
export DATABASE_PROVIDER=supabase
export SUPABASE_URL=https://your-project.supabase.co
export SUPABASE_ANON_KEY=your-anon-key
export SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

**For Production (Firebase):**
```bash
export DATABASE_PROVIDER=firebase
export FIREBASE_PROJECT_ID=your-project-id
export FIREBASE_API_KEY=your-api-key
export FIREBASE_SERVICE_ACCOUNT_PATH=/path/to/service-account.json
```

### Step 2: Update Environment
```bash
# Edit your .env file or set environment variables
cp .env.example .env
# Edit .env with your database configuration
```

### Step 3: Migrate Data (if needed)
```bash
# Export from current database
dart run bin/export_data.dart

# Switch database provider
export DATABASE_PROVIDER=new_provider
# ... configure new provider

# Import to new database
dart run bin/import_data.dart
```

### Step 4: Test Connection
```bash
# Test database connection
curl http://localhost:8080/v1/health/database

# Test full application
curl http://localhost:8080/v1/health
```

## 🧪 Testing

### Unit Tests
```bash
dart test
```

### Integration Tests
```bash
# With SQLite (fast)
export DATABASE_PROVIDER=sqlite
dart test --tags=integration

# With Supabase (requires network)
export DATABASE_PROVIDER=supabase
dart test --tags=integration
```

### Load Testing
```bash
# Install hey (Go) or siege
hey -n 1000 -c 10 http://localhost:8080/v1/health

# Or use artillery
npm install -g artillery
artillery quick --count 10 --num 50 http://localhost:8080/v1/health
```

## 📊 Performance Optimization

### Database Optimization
- **Connection Pooling**: Efficient connection management
- **Query Optimization**: Indexed queries and prepared statements
- **Caching**: Redis integration for frequently accessed data
- **Read Replicas**: Database read/write splitting

### Server Optimization
- **Async/Await**: Non-blocking I/O operations
- **Middleware Pipeline**: Efficient request processing
- **Memory Management**: Garbage collection optimization
- **Concurrent Processing**: Multi-threaded request handling

### Caching Strategies
- **API Response Caching**: Cache frequently requested data
- **Database Query Caching**: Cache expensive queries
- **CDN Integration**: Static asset caching

## 🚨 Troubleshooting

### Database Connection Issues
```bash
# Check database configuration
echo $DATABASE_PROVIDER
echo $SUPABASE_URL

# Test database connectivity
dart run bin/test_db_connection.dart

# Check database logs
tail -f logs/database.log
```

### Memory Issues
```bash
# Monitor memory usage
ps aux | grep dart

# Adjust Dart VM options
export DART_VM_OPTIONS="--old_gen_heap_size=1g --max_old_space_size=2g"
```

### Performance Issues
```bash
# Enable metrics
export ENABLE_METRICS=true

# Check metrics endpoint
curl http://localhost:9090/metrics

# Profile application
dart run --observe bin/main.dart
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup
```bash
# Clone repository
git clone https://github.com/your-org/mock-server.git
cd mock-server

# Install dependencies
dart pub get

# Setup development database
export DATABASE_PROVIDER=sqlite
export ENVIRONMENT=development

# Run tests
dart test

# Start development server
dart run
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: See [docs/](docs/) directory
- **Issues**: [GitHub Issues](https://github.com/your-org/mock-server/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-org/mock-server/discussions)

---

**🎉 Your mock server is now production-ready with multi-database support!**
