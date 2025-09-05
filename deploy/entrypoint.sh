#!/bin/bash

# entrypoint.sh - Generate runtime configuration and start nginx
set -e

# Default values for environment variables
APP_PUBLIC_PATH=${APP_PUBLIC_PATH:-"/"}
BACKEND_BASE_URL=${BACKEND_BASE_URL:-"/api"}
IAP_MODE=${IAP_MODE:-"false"}
IAP_AUDIENCE=${IAP_AUDIENCE:-""}
AUTH_MODE=${AUTH_MODE:-"none"}
BEARER_TOKEN=${BEARER_TOKEN:-""}

# Create runtime configuration file
cat > /usr/share/nginx/html/config/runtime-env.js << EOF
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
EOF

echo "Generated runtime configuration:"
cat /usr/share/nginx/html/config/runtime-env.js

# Start nginx in foreground
exec nginx -g 'daemon off;'
