# Docker Build Fix

## Issue Fixed

The Docker build was failing with:
```
error: process "/bin/sh -c flutter build web --release --web-renderer html" did not complete successfully: exit code 64
```

## Solution

The `--web-renderer html` flag was deprecated in newer Flutter versions. Removed it from the Dockerfile.

## Updated Dockerfile

The build command is now:
```dockerfile
RUN flutter build web --release
```

## Test Locally

Before deploying, you can test the Docker build locally:

```bash
# Build the Docker image
docker build -t reseller-copilot .

# Run it locally
docker run -p 8080:8080 reseller-copilot

# Test it
curl http://localhost:8080
```

## Deploy Again

Now try deploying to Fly.io:

```bash
flyctl deploy
```

The build should succeed now!

## If Build Still Fails

### Check Flutter Version

The Docker image uses `ghcr.io/cirruslabs/flutter:stable`. If you need a specific version:

```dockerfile
FROM ghcr.io/cirruslabs/flutter:3.24.0 AS build
```

### Check Dependencies

Make sure all dependencies are compatible:
```bash
flutter pub get
flutter pub outdated
```

### Build Locally First

Always test the build locally before deploying:
```bash
flutter build web --release
```

If this works, the Docker build should work too.
