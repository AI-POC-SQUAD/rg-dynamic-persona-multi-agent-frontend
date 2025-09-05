# Dynamic Persona Frontend

A production-grade Flutter web Single Page Application (SPA) designed to serve as the frontend for a dynamic persona chatbot system. The application is containerized with Docker and designed for deployment on Google Cloud Run with runtime configuration support.

## Architecture Overview

This frontend application is part of a secure, scalable architecture:

- **Frontend (Public)**: Flutter web SPA served from Cloud Run via NGINX
- **Backend (Secured)**: API services protected by Google Cloud IAP (Identity-Aware Proxy)
- **Runtime Configuration**: Environment-based configuration injection (no rebuild required for URL changes)
- **Security**: IAP handles authentication; frontend relies on session cookies

## Key Features

- 🚀 **Production-Ready**: Containerized Flutter web app with optimized build pipeline
- 🔒 **IAP Integration**: Seamless integration with Google Cloud Identity-Aware Proxy
- ⚙️ **Runtime Configuration**: Environment variables injected at container start
- 🌐 **SPA Routing**: Proper handling of deep links and browser navigation
- 📱 **Responsive Design**: Mobile-friendly interface with Material 3 design
- 🔧 **Development-Friendly**: Easy local development with Docker

## Prerequisites

- Docker (for containerized deployment)
- Flutter SDK 3.0+ (for local development)
- Google Cloud CLI (for deployment)

## Quick Start

### Local Development with Docker

1. **Clone and build the container:**
   ```bash
   docker build -t dynamic-persona-frontend .
   ```

2. **Run with environment configuration:**
   ```bash
   docker run -p 8080:8080 \
     -e BACKEND_BASE_URL=http://localhost:5001 \
     -e IAP_MODE=false \
     dynamic-persona-frontend
   ```

3. **Access the application:**
   Open http://localhost:8080 in your browser

### Using Environment File

1. **Copy the sample environment file:**
   ```bash
   cp .env.sample .env
   ```

2. **Edit `.env` with your configuration:**
   ```
   BACKEND_BASE_URL=http://localhost:5001
   IAP_MODE=false
   IAP_AUDIENCE=
   APP_PUBLIC_PATH=/
   ```

3. **Run with environment file:**
   ```bash
   docker run -p 8080:8080 --env-file .env dynamic-persona-frontend
   ```

## Runtime Configuration

The application uses runtime configuration injection to avoid rebuilding containers when changing environment settings. Configuration is injected via `/config/runtime-env.js` at container start.

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `APP_PUBLIC_PATH` | `/` | Base path if app isn't at domain root |
| `BACKEND_BASE_URL` | `/api` | Backend API URL (absolute or relative) |
| `IAP_MODE` | `false` | Enable IAP cookie-based authentication |
| `IAP_AUDIENCE` | `""` | IAP audience (usually not needed for browser) |

For detailed information about runtime configuration, see [docs/RUNTIME_CONFIG.md](docs/RUNTIME_CONFIG.md).

## Deployment Options

### Option 1: Cloud Run Direct Deploy (Recommended)

Deploy directly from GitHub repository:

```bash
gcloud run deploy dynamic-persona-frontend \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8080 \
  --set-env-vars BACKEND_BASE_URL=/api,IAP_MODE=true
```

## 🔐 Authentication Configuration

This frontend supports multiple authentication modes for connecting to backends:

### Cloud Run IAM Authentication (Recommended)

For connecting to Cloud Run services with IAM authentication:

1. **Generate an identity token:**
   ```bash
   gcloud auth print-identity-token --audiences=https://your-cloud-run-service-url
   ```

2. **Run with bearer authentication:**
   ```bash
   docker run -p 8080:8080 \
     -e AUTH_MODE=bearer \
     -e BACKEND_BASE_URL=https://your-cloud-run-service-url \
     -e BEARER_TOKEN=your-identity-token \
     rg-dynamic-persona-frontend
   ```

3. **Quick setup script (Windows):**
   ```powershell
   .\test-cloud-run-auth.ps1
   ```

   **Quick setup script (Linux/Mac):**
   ```bash
   ./test-cloud-run-auth.sh
   ```

### Authentication Modes

- **`AUTH_MODE=none`** - No authentication (default)
- **`AUTH_MODE=bearer`** - Bearer token authentication (for Cloud Run IAM)
- **`IAP_MODE=true`** - Google Cloud Identity-Aware Proxy

📖 **For detailed authentication setup, see [docs/AUTHENTICATION.md](docs/AUTHENTICATION.md)**

### Option 2: Cloud Build Pipeline

Use automated CI/CD with Cloud Build triggers. See [docs/CI_CD.md](docs/CI_CD.md) for setup instructions.

For complete deployment instructions, see [docs/DEPLOY_CLOUD_RUN.md](docs/DEPLOY_CLOUD_RUN.md).

## Project Structure

```
├── app/                          # Flutter application
│   ├── lib/
│   │   ├── main.dart            # Main application entry point
│   │   └── services/
│   │       └── api_client.dart  # Backend API integration
│   ├── web/
│   │   └── index.html           # HTML template with runtime config
│   └── pubspec.yaml             # Flutter dependencies
├── deploy/
│   ├── nginx.conf               # NGINX configuration for SPA
│   ├── entrypoint.sh           # Runtime config injection script
│   └── SECURITY_NOTES.md       # Security guidelines
├── docs/                        # Comprehensive documentation
├── Dockerfile                   # Multi-stage container build
├── cloudbuild.yaml             # Cloud Build configuration
├── .env.sample                 # Environment template
└── README.md                   # This file
```

## Security

This application is designed with security best practices:

- **No Secrets in Frontend**: All sensitive data stays on the backend
- **IAP Integration**: Relies on Google Cloud IAP for authentication
- **Runtime Configuration**: No build-time embedding of URLs or credentials
- **Security Headers**: NGINX configured with appropriate security headers

See [deploy/SECURITY_NOTES.md](deploy/SECURITY_NOTES.md) for detailed security information.

## Development

### Local Flutter Development

1. **Install dependencies:**
   ```bash
   cd app
   flutter pub get
   ```

2. **Run in development mode:**
   ```bash
   flutter run -d chrome
   ```

3. **Build for production:**
   ```bash
   flutter build web --release
   ```

### Testing Configuration

Test different configurations by modifying environment variables:

```bash
# Test with different backend URL
docker run -p 8080:8080 -e BACKEND_BASE_URL=https://api.example.com dynamic-persona-frontend

# Test with IAP enabled
docker run -p 8080:8080 -e IAP_MODE=true -e BACKEND_BASE_URL=/api dynamic-persona-frontend
```

## Monitoring and Logging

The application includes:

- **Health Check Endpoint**: `/health` for load balancer checks
- **Structured Logging**: Console logs for debugging configuration
- **Error Handling**: Graceful error handling with user feedback

For production monitoring setup, see the deployment documentation.

## Troubleshooting

### Common Issues

1. **Runtime config not loading**: Check `/config/runtime-env.js` endpoint
2. **CORS errors**: Ensure backend CORS is configured or use same-origin proxy
3. **Authentication issues**: Verify IAP setup and user permissions
4. **Deep links not working**: Check NGINX SPA fallback configuration

### Debug Information

Access runtime configuration info through the info button (ℹ️) in the app header.

## Documentation

- [Architecture Overview](docs/ARCHITECTURE.md)
- [Runtime Configuration](docs/RUNTIME_CONFIG.md)
- [Deployment Guide](docs/DEPLOY_CLOUD_RUN.md)
- [CI/CD Setup](docs/CI_CD.md)
- [IAP Configuration](docs/IAP_SETUP.md)

## Contributing

1. Follow the Flutter style guidelines
2. Update documentation for any configuration changes
3. Test with both IAP enabled and disabled modes
4. Ensure Docker builds succeed without errors

## License

[Add your license information here]

## Support

For questions or issues:
1. Check the troubleshooting section above
2. Review the documentation in the `docs/` directory
3. Check application logs via Cloud Run console
4. Verify environment variable configuration