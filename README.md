# 🚀 Dart REST API Starter Kit

[![Dart](https://img.shields.io/badge/Dart-2.19+-blue.svg)](https://dart.dev/)
[![Shelf](https://img.shields.io/badge/Shelf-1.4+-green.svg)](https://pub.dev/packages/shelf)
[![SQLite](https://img.shields.io/badge/SQLite-3.9+-blue.svg)](https://sqlite.org/)
[![OpenAPI](https://img.shields.io/badge/OpenAPI-3.0.3-orange.svg)](https://swagger.io/specification/)
[![JWT](https://img.shields.io/badge/JWT-Authentication-red.svg)](https://jwt.io/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Production-Ready REST API Template** - Complete starter kit with authentication, security, monitoring, and enterprise-grade architecture for building scalable APIs with Dart/Shelf.

## 📋 Table of Contents

- [✨ Features](#-features)
- [🏗️ Architecture](#️-architecture)
- [🚀 Quick Start](#-quick-start)
- [📚 API Documentation](#-api-documentation)
- [🔐 Authentication](#-authentication)
- [🛡️ Security](#️-security)
- [⚙️ Configuration](#️-configuration)
- [🚀 Deployment](#-deployment)
- [🛠️ Development](#️-development)
- [📊 Monitoring](#-monitoring)
- [🤝 Contributing](#-contributing)
- [👤 Author](#-author)
- [📄 License](#-license)

---

## ✨ Features

### 🔐 **Authentication & Security**
- ✅ **JWT Authentication** with refresh tokens
- ✅ **Rate Limiting** (100 req/15min per IP)
- ✅ **Input Sanitization** (XSS/SQL injection prevention)
- ✅ **Security Headers** (HSTS, CSP, XSS protection)
- ✅ **CSRF Protection** for state-changing operations
- ✅ **OWASP Top 10 Compliant**

### 🌐 **API Features**
- ✅ **RESTful Endpoints** with proper HTTP methods
- ✅ **OpenAPI 3.0.3** specification (400+ lines)
- ✅ **Swagger UI** interactive documentation
- ✅ **Structured Error Responses**
- ✅ **Request/Response Validation**
- ✅ **CORS Support**

### 💾 **Database & Storage**
- ✅ **SQLite Database** with Repository pattern
- ✅ **Type-Safe Queries** with prepared statements
- ✅ **Migration Support** ready
- ✅ **Connection Pooling**
- ✅ **Data Validation**

### 📊 **Monitoring & Observability**
- ✅ **Health Checks** (/v1/health)
- ✅ **Request Logging** with timestamps
- ✅ **Error Tracking** with stack traces
- ✅ **Rate Limiting Metrics**
- ✅ **Performance Monitoring**

---

## 🏗️ Architecture

```
dart_rest_api_starter_kit/
├── 📁 lib/
│   ├── 🏗️ core/                    # Shared components
│   │   ├── ⚙️ config/              # Configuration management
│   │   ├── 💾 database/            # Data layer
│   │   │   ├── 🏗️ repositories/    # Repository pattern
│   │   │   └── ⚙️ config/          # DB configuration
│   │   ├── 🛡️ middleware/          # Security middlewares
│   │   ├── 📋 models/             # Data models
│   │   └── 🛠️ utils/              # Utilities
│   └── 📁 features/                # Feature modules
│       ├── 🔐 auth/                # Authentication
│       ├── 👤 user/                # User management
│       ├── 🤖 ai/                  # AI features
│       └── 💊 health/              # Health checks
├── 📁 bin/                         # Executables
├── 📁 swagger-ui/                  # API documentation
├── 📄 openapi.yaml                 # API specification
├── 📄 pubspec.yaml                 # Dependencies
└── 📄 README.md                    # Documentation
```

---

## 🚀 Quick Start

### 📦 Prerequisites

- **Dart SDK**: `>=3.0.0 <4.0.0`
- **SQLite3**: For database operations

### 🛠️ Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd dart_rest_api_starter_kit
   ```

2. **Install dependencies:**
   ```bash
   dart pub get
   ```

3. **Start the server:**
   ```bash
   dart run bin/main.dart
   ```

### 🎯 First API Call

```bash
# Health check
curl http://localhost:8080/v1/health

# Response
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "version": "1.0.0"
}
```

---

## 📚 API Documentation

### 🌐 Interactive Documentation

Access the **Swagger UI** at: `http://localhost:8080/`

### 📋 API Endpoints Overview

| Category | Endpoint | Method | Protected | Description |
|----------|----------|--------|-----------|-------------|
| **Health** | `/v1/health` | GET | ❌ | Basic health check |
| | `/v1/health/database` | GET | ❌ | Database connectivity |
| **Auth** | `/v1/auth/login` | POST | ❌ | User authentication |
| | `/v1/auth/register` | POST | ❌ | User registration |
| | `/v1/auth/logout` | POST | ❌ | Secure logout |
| | `/v1/auth/refresh` | POST | ❌ | Refresh access token |
| | `/v1/auth/forgot-password` | POST | ❌ | Password recovery |
| | `/v1/auth/reset-password` | POST | ❌ | Password reset |
| | `/v1/auth/send-email-verification` | POST | ❌ | Send verification email |
| | `/v1/auth/verify-email/{token}` | POST | ❌ | Verify email |
| **User** | `/v1/user/profile` | GET | ✅ | Get user profile |
| | `/v1/user/profile` | PUT | ✅ | Update profile |
| | `/v1/user/change-password` | PUT | ✅ | Change password |
| **AI** | `/v1/ai/search/semantic` | POST | ✅ | Semantic search |
| | `/v1/ai/recommendations` | POST | ✅ | Get recommendations |
| | `/v1/ai/embeddings/generate` | POST | ✅ | Generate embeddings |
| | `/v1/ai/interactions/track` | POST | ✅ | Track interactions |
| | `/v1/ai/analytics` | POST | ✅ | AI analytics |

### 📖 OpenAPI Specification

The complete API specification is available at: `http://localhost:8080/openapi.yaml`

---

## 🔐 Authentication

### JWT Token Flow

1. **Register/Login** to get access token
2. **Include token** in Authorization header
3. **Access protected endpoints**
4. **Refresh token** when expired

### 🔑 Authentication Examples

#### **Register New User**
```bash
curl -X POST http://localhost:8080/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "securepassword123",
    "firstName": "John",
    "lastName": "Doe"
  }'
```

#### **Login**
```bash
curl -X POST http://localhost:8080/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "securepassword123"
  }'
```

**Response:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "user_123",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe"
  }
}
```

#### **Access Protected Endpoint**
```bash
curl -X GET http://localhost:8080/v1/user/profile \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## 🛡️ Security

### 🔒 Security Features

#### **Rate Limiting**
- **Limit**: 100 requests per 15 minutes per IP
- **Headers**: `X-RateLimit-*` for monitoring
- **Protection**: DoS attack prevention

#### **Input Validation & Sanitization**
- **XSS Prevention**: HTML tag removal
- **SQL Injection**: Pattern detection
- **Request Size**: 1MB maximum payload
- **JSON Validation**: Required format enforcement

#### **Security Headers**
```http
X-Frame-Options: DENY
Content-Security-Policy: default-src 'self'; ...
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000; ...
```

#### **CSRF Protection**
- **Token-based**: Automatic token generation
- **State-changing**: POST/PUT/PATCH/DELETE protection
- **API Bypass**: JWT endpoints exempt

### 🔍 Security Audit

#### **OWASP Top 10 Compliance**
- ✅ **Injection**: Input sanitization
- ✅ **Broken Authentication**: JWT validation
- ✅ **Sensitive Data Exposure**: Security headers
- ✅ **XML External Entities**: JSON-only
- ✅ **Broken Access Control**: Route protection
- ✅ **Security Misconfiguration**: Config validation
- ✅ **Cross-Site Scripting**: XSS protection
- ✅ **Insecure Deserialization**: Input validation
- ✅ **Vulnerable Components**: Controlled dependencies
- ✅ **Insufficient Logging**: Request logging

---

## ⚙️ Configuration

### 🌍 Environment Variables

```bash
# Server Configuration
PORT=8080                          # Server port (default: 8080)
HOST=0.0.0.0                       # Server host (default: 0.0.0.0)
ENVIRONMENT=production             # Environment (development/production)

# Database Configuration
DATABASE_TYPE=sqlite               # Database type
DATABASE_PATH=data/prod.db         # SQLite file path

# Security Configuration
JWT_SECRET=your-super-secret-key   # JWT signing secret
CORS_ENABLED=true                  # Enable CORS
RATE_LIMIT_ENABLED=true            # Enable rate limiting
MAX_BODY_SIZE=1048576              # Max request body size (1MB)

# Feature Flags
SWAGGER_UI_ENABLED=true           # Enable Swagger UI
API_DOCS_ENABLED=true             # Enable API docs
HEALTH_ENDPOINTS_ENABLED=true     # Enable health checks
```

### 📄 Configuration File

Create `config/production.yaml`:

```yaml
server:
  port: 8080
  host: "0.0.0.0"
  timeout: 30

database:
  type: "sqlite"
  path: "data/production.db"
  max_connections: 10

security:
  jwt_secret: "your-production-secret"
  rate_limiting:
    enabled: true
    max_requests: 100
    window_minutes: 15
  cors:
    enabled: true
    origins: ["https://yourdomain.com"]
  input_validation:
    enabled: true
    max_body_size: 1048576

features:
  swagger_ui: true
  api_docs: true
  health_endpoints: true
```

---

## 🚀 Deployment

### 🐳 Docker Deployment

#### **Dockerfile**
```dockerfile
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/main.dart -o bin/server

FROM scratch
COPY --from=build /app/bin/server /server
COPY --from=build /runtime/ /
EXPOSE 8080

CMD ["/server"]
```

#### **Docker Compose**
```yaml
version: '3.8'
services:
  dart-rest-api-starter-kit:
    build: .
    ports:
      - "8080:8080"
    environment:
      - ENVIRONMENT=production
      - JWT_SECRET=your-production-secret
      - DATABASE_PATH=/data/production.db
    volumes:
      - ./data:/data
    restart: unless-stopped
```

#### **Deploy Commands**
```bash
# Build and run
docker-compose up --build -d

# View logs
docker-compose logs -f dart-rest-api-starter-kit

# Scale the service
docker-compose up -d --scale dart-rest-api-starter-kit=3
```

### ☁️ Cloud Deployment

#### **Google Cloud Run**
```bash
# Build container
gcloud builds submit --tag gcr.io/PROJECT-ID/dart-rest-api-starter-kit

# Deploy to Cloud Run
gcloud run deploy dart-rest-api-starter-kit \
  --image gcr.io/PROJECT-ID/dart-rest-api-starter-kit \
  --platform managed \
  --port 8080 \
  --allow-unauthenticated \
  --set-env-vars="ENVIRONMENT=production,JWT_SECRET=your-secret"
```

#### **AWS Fargate**
```bash
# Using AWS CLI
aws ecs create-service \
  --cluster dart-rest-api-starter-kit-cluster \
  --service-name dart-rest-api-starter-kit \
  --task-definition dart-rest-api-starter-kit-task \
  --desired-count 2 \
  --launch-type FARGATE
```

#### **Heroku**
```bash
# Create Procfile
echo "web: dart run bin/main.dart" > Procfile

# Deploy
git push heroku main
```

### 🔧 Production Checklist

- ✅ **Environment Variables** configured
- ✅ **Database** initialized and migrated
- ✅ **SSL/TLS** certificates configured
- ✅ **Firewall** rules updated
- ✅ **Monitoring** alerts configured
- ✅ **Backup** strategy implemented
- ✅ **Load Balancing** configured
- ✅ **Health Checks** enabled

---

## 🛠️ Development

### 🚀 Development Setup

1. **Clone and setup:**
   ```bash
   git clone <repository-url>
   cd mock_server
   dart pub get
   ```

2. **Development configuration:**
   ```bash
   export ENVIRONMENT=development
   export DATABASE_PATH=data/dev.db
   ```

3. **Run with hot reload:**
   ```bash
   dart run bin/main.dart
   ```

### 🧪 Testing

#### **Run Tests**
```bash
# Run all tests
dart test

# Run with coverage
dart test --coverage=coverage
dart pub global run coverage:format_coverage \
  --lcov --in=coverage --out=coverage/lcov.info
```

#### **API Testing with cURL**
```bash
# Health check
curl http://localhost:8080/v1/health

# Authentication flow
curl -X POST http://localhost:8080/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'

# Protected endpoint
curl -X GET http://localhost:8080/v1/user/profile \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 🔧 Code Quality

#### **Linting**
```bash
# Run linter
dart analyze

# Fix formatting
dart format .
```

#### **Pre-commit Hooks**
```bash
# Install pre-commit hooks
dart pub global activate pre_commit
pre_commit install

# Run hooks
pre_commit run --all-files
```

### 📁 Project Structure

```
lib/
├── core/
│   ├── config/
│   │   └── app_config.dart          # Configuration management
│   ├── database/
│   │   ├── config/
│   │   │   └── database_config.dart # Database setup
│   │   └── repositories/
│   │       ├── base_repository.dart # Base repository
│   │       ├── user_repository.dart # User data
│   │       └── ...                  # Other repositories
│   ├── middleware/
│   │   ├── auth_middleware.dart     # JWT authentication
│   │   ├── rate_limiting_middleware.dart # Rate limiting
│   │   ├── input_sanitization_middleware.dart # XSS protection
│   │   ├── security_headers_middleware.dart # Security headers
│   │   └── ...                      # Other middlewares
│   └── models/
│       └── api_response.dart        # Response models
├── features/
│   ├── auth/
│   │   ├── routes/
│   │   │   └── auth_routes.dart     # Auth endpoints
│   │   ├── handlers/
│   │   │   └── auth_handler.dart    # Auth handlers
│   │   ├── services/
│   │   │   └── auth_service.dart    # Auth business logic
│   │   └── models/
│   │       └── auth_models.dart     # Auth models
│   ├── user/
│   │   └── ...                      # User management
│   ├── ai/
│   │   └── ...                      # AI features
│   └── health/
│       └── ...                      # Health checks
└── server.dart                      # Main server file
```

---

## 📊 Monitoring

### 💊 Health Checks

#### **Endpoints**
```bash
# Basic health
GET /v1/health

# Database health
GET /v1/health/database

# Detailed health
GET /v1/health/detailed
```

#### **Health Response**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "version": "1.0.0",
  "database": {
    "status": "connected",
    "response_time_ms": 12
  },
  "system": {
    "memory_usage": "45%",
    "cpu_usage": "23%",
    "uptime": "2h 30m"
  }
}
```

### 📈 Metrics

#### **Rate Limiting Stats**
```bash
# Get rate limiting statistics
GET /v1/health/rate-limit-stats

# Response
{
  "total_clients": 15,
  "max_requests": 100,
  "window_seconds": 900,
  "clients": [
    {
      "client_id": "192.168.1.100",
      "requests": 23,
      "remaining_requests": 77,
      "reset_time": "2024-01-01T00:15:00.000Z"
    }
  ]
}
```

### 📝 Logging

#### **Log Levels**
- **DEBUG**: Detailed development information
- **INFO**: General operational messages
- **WARN**: Warning conditions
- **ERROR**: Error conditions
- **FATAL**: Critical errors

#### **Log Format**
```
2024-01-01T00:00:00.000Z INFO  [RequestHandler] GET /v1/health 200 12ms
2024-01-01T00:01:15.000Z WARN  [RateLimiter] Rate limit exceeded for 192.168.1.100
2024-01-01T00:02:30.000Z ERROR [AuthHandler] Invalid JWT token provided
```

---

## 🤝 Contributing

### 🚀 How to Contribute

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Make your changes**
4. **Add tests for new features**
5. **Ensure all tests pass**
   ```bash
   dart test
   dart analyze
   ```
6. **Update documentation**
7. **Commit your changes**
   ```bash
   git commit -m "✨ Add amazing feature"
   ```
8. **Push to the branch**
   ```bash
   git push origin feature/amazing-feature
   ```
9. **Create a Pull Request**

### 📋 Development Guidelines

#### **Code Style**
- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add documentation comments for public APIs
- Keep functions small and focused

#### **Testing**
- Write unit tests for new features
- Write integration tests for API endpoints
- Maintain >80% code coverage
- Test both success and error scenarios

#### **Security**
- Never commit secrets or credentials
- Use environment variables for sensitive data
- Follow OWASP security guidelines
- Validate all inputs

#### **Git Workflow**
- Use descriptive commit messages
- Keep commits focused and atomic
- Use feature branches for development
- Rebase before merging to main

### 🐛 Reporting Issues

1. **Check existing issues** before creating new ones
2. **Use issue templates** when available
3. **Provide detailed information**:
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details
   - Error logs

---

## 👤 Author

**Cristiano Aredes**

[![Website](https://img.shields.io/badge/Website-aredes.me-blue)](https://aredes.me/)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-orange.svg)](https://buymeacoffee.com/cristianoaredes)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-cristianoaredes-blue)](https://linkedin.com/in/cristianoaredes)
[![Twitter](https://img.shields.io/badge/Twitter-@cristianoaredes-blue)](https://twitter.com/cristianoaredes)

Full-stack developer passionate about Dart, Flutter, and building scalable backend systems. Creator of production-ready templates and tools for modern development.

### 🎯 Other Projects by the Same Author

#### **MCP Mobile Server** 
[![NPM](https://img.shields.io/npm/v/@cristianoaredes/mcp-mobile-server.svg)](https://www.npmjs.com/package/@cristianoaredes/mcp-mobile-server)
[![Downloads](https://img.shields.io/npm/dm/@cristianoaredes/mcp-mobile-server.svg)](https://www.npmjs.com/package/@cristianoaredes/mcp-mobile-server)

> **Mobile Development Server with MCP (Model Context Protocol)** - Complete development server for mobile apps with hot reload, device management, and debugging tools.

```bash
npm install -g @cristianoaredes/mcp-mobile-server
```

**Key Features:**
- 🔧 **Hot Reload** for Flutter/React Native apps
- 📱 **Device Management** (iOS/Android simulators)
- 🐛 **Debug Tools** with real-time logging
- 📊 **Performance Monitoring** for mobile apps
- 🚀 **Production Builds** with optimization

[📖 View on NPM](https://www.npmjs.com/package/@cristianoaredes/mcp-mobile-server) • 
[📚 Documentation](https://github.com/cristianoaredes/mcp-mobile-server)

### 💼 Professional Services

Available for consulting, custom development, and training:

- **Backend Architecture** - Design and implementation
- **API Development** - REST, GraphQL, WebSocket
- **Mobile Development** - Flutter, React Native
- **DevOps & Deployment** - Cloud platforms, CI/CD
- **Code Review & Mentoring** - Best practices, architecture

[📧 Contact](mailto:contact@cristianoaredes.dev) • 
[💼 LinkedIn](https://linkedin.com/in/cristianoaredes)

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2024 Cristiano Aredes

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 Acknowledgments

- **Shelf Framework**: For the excellent HTTP server foundation
- **Dart Team**: For the amazing Dart language and ecosystem
- **OpenAPI Initiative**: For the API specification standards
- **OWASP**: For security best practices and guidelines
- **Community**: For contributions, feedback, and support

---

<div align="center">

**🚀 Dart REST API Starter Kit**

*Built with ❤️ using Dart and Shelf*

[![Star on GitHub](https://img.shields.io/github/stars/your-org/dart-rest-api-starter-kit?style=social)](https://github.com/your-org/dart-rest-api-starter-kit)
[![Follow on Twitter](https://img.shields.io/twitter/follow/cristianoaredes?style=social)](https://twitter.com/cristianoaredes)

</div>
