# Use Node.js 22 Alpine as base image
FROM node:22-alpine AS base

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apk add --no-cache curl jq postgresql-client

# Install corepack and enable yarn
RUN npm install -g corepack@0.24.1 && corepack enable

# Copy package files for dependency installation
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

# Install dependencies using the correct Yarn 4.9.2 flags
RUN yarn install --immutable

# Copy source code
COPY . .

# Build stage
FROM base AS builder

# Build the application
RUN yarn nx run twenty-server:build
RUN yarn nx build twenty-front

# Production stage
FROM node:22-alpine AS production

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apk add --no-cache curl jq postgresql-client

# Install corepack and enable yarn
RUN npm install -g corepack@0.24.1 && corepack enable

# Copy package files
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

# Install production dependencies
RUN yarn install --immutable --production

# Copy built application from builder stage
COPY --from=builder /app/packages/twenty-server/dist ./packages/twenty-server/dist
COPY --from=builder /app/packages/twenty-front/dist ./packages/twenty-front/dist

# Copy source code for runtime
COPY . .

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:3000/healthz || exit 1

# Start the application
CMD ["yarn", "start"] 