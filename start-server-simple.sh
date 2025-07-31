#!/bin/bash

echo "🚀 Starting Twenty Server with all environment variables..."

# Set memory limits
export NODE_OPTIONS="--max-old-space-size=1024"
export PATH="/opt/homebrew/opt/node@22/bin:$PATH"

# Set all required environment variables
export TAG=latest
export PG_DATABASE_USER=postgres
export PG_DATABASE_PASSWORD=postgres
export PG_DATABASE_HOST=localhost
export PG_DATABASE_PORT=5432
export REDIS_URL=redis://localhost:6379
export SERVER_URL=http://localhost:3000
export APP_SECRET=5lByeDhNznD0lM4vQh4FcAMAgU5flzZzQ0IiC4XfBMk=
export STORAGE_TYPE=local

# Kill any existing processes
pkill -f "yarn\|nx\|node" 2>/dev/null || true

# Wait a moment
sleep 2

echo "📦 Building server..."
cd packages/twenty-server

# Build the server
yarn nx run twenty-server:build

if [ $? -ne 0 ]; then
    echo "❌ Server build failed"
    exit 1
fi

echo "✅ Server built successfully"

# Start the server
echo "🌐 Starting server on port 3000..."
node dist/src/main.js 