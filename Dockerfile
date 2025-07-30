# Use Node.js 22 Alpine as base image
FROM node:22-alpine

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apk add --no-cache curl jq postgresql-client

# Install corepack and enable yarn
RUN npm install -g corepack@0.24.1 && corepack enable

# Copy package files first for better caching
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn/releases ./.yarn/releases
COPY .yarn/patches ./.yarn/patches

# Copy workspace package.json files
COPY packages/twenty-emails/package.json ./packages/twenty-emails/
COPY packages/twenty-server/package.json ./packages/twenty-server/
COPY packages/twenty-server/patches ./packages/twenty-server/patches
COPY packages/twenty-ui/package.json ./packages/twenty-ui/
COPY packages/twenty-shared/package.json ./packages/twenty-shared/
COPY packages/twenty-front/package.json ./packages/twenty-front/

# Install dependencies (using immutable flag for better Docker compatibility)
RUN yarn install --immutable

# Copy source code
COPY . .

# Build the application with error handling
RUN yarn nx run twenty-server:build || (echo "Server build failed" && exit 1)
RUN yarn nx build twenty-front || (echo "Frontend build failed" && exit 1)

# Create production build
RUN yarn workspaces focus --production twenty-emails twenty-shared twenty-server

# Create storage directories
RUN mkdir -p /app/.local-storage /app/packages/twenty-server/.local-storage

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/healthz || exit 1

# Start the application
CMD ["yarn", "start"] 