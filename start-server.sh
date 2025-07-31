#!/bin/bash

echo "🚀 Starting Twenty Server with minimal memory usage..."

# Set memory limits
export NODE_OPTIONS="--max-old-space-size=1536"
export PATH="/opt/homebrew/opt/node@22/bin:$PATH"

# Kill any existing processes
pkill -f "yarn\|nx\|node" 2>/dev/null || true

# Wait a moment
sleep 2

echo "📦 Building server..."
cd packages/twenty-server

# Build the server
yarn build

if [ $? -ne 0 ]; then
    echo "❌ Server build failed"
    exit 1
fi

echo "✅ Server built successfully"

# Start the server
echo "🌐 Starting server on port 3000..."
node dist/main.js 