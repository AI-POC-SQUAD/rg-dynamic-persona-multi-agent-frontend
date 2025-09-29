# Multi-stage Dockerfile for Flutter web SPA
# Stage 1: Build Flutter web application
FROM ghcr.io/cirruslabs/flutter:3.35.4 AS build

# Set working directory
WORKDIR /app

# Copy Flutter project files
COPY app/pubspec.yaml ./
RUN flutter pub get

# Copy source code
COPY app/ ./

# Create a placeholder .env file if it doesn't exist (for build-time)
RUN touch .env

# Build Flutter web for production
RUN flutter build web --release

# Stage 2: Serve with nginx
FROM nginx:alpine

# Install bash for entrypoint script
RUN apk add --no-cache bash

# Copy nginx configuration
COPY deploy/nginx.conf /etc/nginx/nginx.conf

# Copy entrypoint script and ensure Unix line endings
COPY deploy/entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

# Copy Flutter build artifacts
COPY --from=build /app/build/web /usr/share/nginx/html

# Create config directory for runtime environment
RUN mkdir -p /usr/share/nginx/html/config

# Environment variables with sensible defaults
ENV APP_PUBLIC_PATH="/"
ENV BACKEND_BASE_URL="/api"
ENV IAP_MODE="true"
ENV IAP_AUDIENCE=""
ENV USE_CORS_PROXY="false"

# Expose port 8080 (Cloud Run default)
EXPOSE 8080

# Use entrypoint script to generate runtime config and start nginx
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
