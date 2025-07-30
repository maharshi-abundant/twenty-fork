#!/bin/bash

echo "🧪 Testing Twenty build process locally..."

# Set Node.js path
export PATH="/opt/homebrew/opt/node@22/bin:$PATH"

echo "📦 Testing yarn install..."
yarn install --immutable

if [ $? -ne 0 ]; then
    echo "❌ Yarn install failed"
    exit 1
fi

echo "✅ Yarn install successful"

echo "🔨 Testing server build..."
yarn nx run twenty-server:build

if [ $? -ne 0 ]; then
    echo "❌ Server build failed"
    exit 1
fi

echo "✅ Server build successful"

echo "🎨 Testing frontend build..."
yarn nx build twenty-front

if [ $? -ne 0 ]; then
    echo "❌ Frontend build failed"
    exit 1
fi

echo "✅ Frontend build successful"

echo "🎉 All builds successful! Ready for deployment." 