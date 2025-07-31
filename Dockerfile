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

# Install dependencies
RUN yarn install --frozen-lockfile

# Build stage
FROM base AS builder

# Copy source code
COPY . .

# Build the application
RUN yarn nx run twenty-server:build
RUN yarn nx build twenty-front

# Production stage
FROM node:22-alpine AS production

WORKDIR /app

# Install only production dependencies
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn/releases ./.yarn/releases
COPY .yarn/patches ./.yarn/patches
COPY packages/twenty-emails/package.json ./packages/twenty-emails/
COPY packages/twenty-server/package.json ./packages/twenty-server/
COPY packages/twenty-server/patches ./packages/twenty-server/patches
COPY packages/twenty-ui/package.json ./packages/twenty-ui/
COPY packages/twenty-shared/package.json ./packages/twenty-shared/
COPY packages/twenty-front/package.json ./packages/twenty-front/

RUN npm install -g corepack@0.24.1 && corepack enable
RUN yarn install --frozen-lockfile --production

# Copy built application
COPY --from=builder /app/packages/twenty-server/dist ./packages/twenty-server/dist
COPY --from=builder /app/packages/twenty-front/dist ./packages/twenty-front/dist
COPY --from=builder /app/packages/twenty-shared/dist ./packages/twenty-shared/dist
COPY --from=builder /app/packages/twenty-ui/dist ./packages/twenty-ui/dist
COPY --from=builder /app/packages/twenty-emails/dist ./packages/twenty-emails/dist

# Copy necessary files
COPY packages/twenty-server/src ./packages/twenty-server/src
COPY packages/twenty-server/tsconfig*.json ./packages/twenty-server/
COPY packages/twenty-server/nest-cli.json ./packages/twenty-server/

# Expose port
EXPOSE 3000

# Start the application
CMD ["yarn", "start"] 