# Stage 1: Build the Flutter Web app
FROM ghcr.io/cirruslabs/flutter:stable AS build-stage
WORKDIR /app

# Copy dependency files first to leverage Docker caching
COPY pubspec.* ./
RUN flutter pub get

# Copy the rest of the project and compile
COPY . .
RUN flutter build web --release

# Stage 2: Serve the app with Nginx
FROM nginx:alpine
# Copy the compiled output from the build stage
COPY --from=build-stage /app/build/web /usr/share/nginx/html
# Copy custom Nginx routing configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
