# FFMQ Mindfulness App - Docker Deployment

## Quick Start

### Option 1: Using Docker Compose (Recommended)
```bash
# Build and start the app
docker-compose up -d

# Access at: http://localhost:8080
```

### Option 2: Using the Deploy Script
```bash
# Make script executable (first time only)
chmod +x deploy.sh

# Deploy the app
./deploy.sh
```

### Option 3: Manual Docker Commands
```bash
# Build the image
docker build -t ffmq-app .

# Run the container
docker run -d \
  --name ffmq-app \
  --restart unless-stopped \
  -p 8080:80 \
  ffmq-app
```

## Configuration

### Change Port
Edit `docker-compose.yml` or the deploy command:
```yaml
ports:
  - "YOUR_PORT:80"  # Change 8080 to your preferred port
```

### Environment Variables
The app is configured for your local network. To change the webhook URL:
1. Edit `src/App.svelte`
2. Update `WEBHOOK_URL` constant
3. Rebuild the Docker image

## Management

### View Logs
```bash
docker logs ffmq-app
```

### Stop the App
```bash
docker stop ffmq-app
```

### Remove the Container
```bash
docker rm ffmq-app
```

### Update the App
```bash
# Pull latest code, then rebuild
git pull
docker-compose up -d --build
```

## Features

- ✅ **Self-contained**: Everything needed in one container
- ✅ **Lightweight**: Uses nginx-alpine for minimal size
- ✅ **Production-ready**: Optimized builds with gzip compression
- ✅ **Health checks**: Built-in container health monitoring
- ✅ **Easy deployment**: Simple scripts and compose files

## Network Access

The app will be available at `http://YOUR_SERVER_IP:8080` on your homelab network.
