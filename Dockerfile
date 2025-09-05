# Multi-stage Dockerfile for Flutter web SPA
# Stage 1: Build Flutter web application
FROM cirrusci/flutter:stable AS build

# Set working directory
WORKDIR /app

# Copy Flutter project files
COPY app/pubspec.yaml ./
RUN flutter pub get

# Copy source code
COPY app/ ./

# Build Flutter web for production
RUN flutter build web --release

# Stage 2: Serve with nginx
FROM nginx:alpine

# Install bash for entrypoint script
RUN apk add --no-cache bash

# Copy nginx configuration
COPY deploy/nginx.conf /etc/nginx/nginx.conf

# Create entrypoint script directly in Dockerfile to avoid line ending issues
RUN cat > /entrypoint.sh << 'EOF' && chmod +x /entrypoint.sh
#!/bin/bash
set -e

# Default values for environment variables
APP_PUBLIC_PATH=${APP_PUBLIC_PATH:-"/"}
BACKEND_BASE_URL=${BACKEND_BASE_URL:-"/api"}
IAP_MODE=${IAP_MODE:-"false"}
IAP_AUDIENCE=${IAP_AUDIENCE:-""}
AUTH_MODE=${AUTH_MODE:-"none"}
BEARER_TOKEN=${BEARER_TOKEN:-""}

# Create runtime configuration file
cat > /usr/share/nginx/html/config/runtime-env.js << JSEOF
// Runtime configuration injected at container start
window.__RUNTIME_CONFIG__ = {
  APP_PUBLIC_PATH: "${APP_PUBLIC_PATH}",
  BACKEND_BASE_URL: "${BACKEND_BASE_URL}",
  IAP_MODE: ${IAP_MODE},
  IAP_AUDIENCE: "${IAP_AUDIENCE}",
  AUTH_MODE: "${AUTH_MODE}",
  BEARER_TOKEN: "${BEARER_TOKEN}"
};

// Console log for debugging (remove in production if needed)
console.log('Runtime config loaded:', window.__RUNTIME_CONFIG__);
JSEOF

echo "Generated runtime configuration:"
cat /usr/share/nginx/html/config/runtime-env.js

# Start nginx in foreground
exec nginx -g 'daemon off;'
EOF

# Copy Flutter build artifacts
COPY --from=build /app/build/web /usr/share/nginx/html

# Create config directory for runtime environment
RUN mkdir -p /usr/share/nginx/html/config

# Environment variables with sensible defaults
ENV APP_PUBLIC_PATH="/"
ENV BACKEND_BASE_URL="/api"
ENV IAP_MODE="false"
ENV IAP_AUDIENCE=""

# Expose port 8080 (Cloud Run default)
EXPOSE 8080

# Use entrypoint script to generate runtime config and start nginx
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
