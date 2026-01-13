# Dockerfile for Flutter Web App on Fly.io

# Use a Flutter base image
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy the rest of the app
COPY . .

# Generate required files
RUN flutter pub run build_runner build --delete-conflicting-outputs

# Build the web app
RUN flutter build web --release --web-renderer html

# Use a lightweight web server for production
FROM nginx:alpine

# Copy built web app to nginx
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 8080 (Fly.io will map this)
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
