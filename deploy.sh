#!/bin/bash

echo "🚀 Building and deploying FFMQ Mindfulness App..."

# Build the Docker image
echo "📦 Building Docker image..."
docker build -t ffmq-app .

# Stop and remove existing container if running
echo "🛑 Stopping existing container..."
docker stop ffmq-app 2>/dev/null || true
docker rm ffmq-app 2>/dev/null || true

# Run the new container
echo "▶️  Starting new container..."
docker run -d \
  --name ffmq-app \
  --restart unless-stopped \
  -p 8080:80 \
  ffmq-app

echo "✅ FFMQ App deployed successfully!"
echo "🌐 Access your app at: http://localhost:8080"
echo "🔧 To view logs: docker logs ffmq-app"
echo "🛑 To stop: docker stop ffmq-app"
