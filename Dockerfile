# ── Stage 1: Build Flutter Web Application ──
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Build-time argument for backend API URL (defaults to production API)
ARG API_URL=https://api.conexiate.co/api
ENV API_URL=${API_URL}

# Cache Flutter/Dart dependencies layer
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy application source code
COPY . .

# Compile Flutter Web in optimized release mode with configured API_URL
RUN flutter build web --release --dart-define=API_URL=${API_URL}

# ── Stage 2: Production Nginx Server ──
FROM nginx:alpine

# Clear default Nginx static files
RUN rm -rf /usr/share/nginx/html/*

# Copy compiled static assets from builder stage
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy custom Nginx configuration for Flutter SPA routing, gzip, and cache headers
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose HTTP port 80
EXPOSE 80

# Start Nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
