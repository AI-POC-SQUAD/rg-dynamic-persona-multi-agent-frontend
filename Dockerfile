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

# Copy entrypoint script
COPY deploy/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

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
CMD ["/entrypoint.sh"]
