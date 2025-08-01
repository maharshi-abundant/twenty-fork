# Use Node.js 22 Alpine as base image
FROM node:22-alpine

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

# Install dependencies with simple yarn install (no flags to avoid issues)
RUN yarn install

# Copy source code
COPY . .

# Build the application
RUN yarn nx run twenty-server:build
RUN yarn nx build twenty-front

# Expose port
EXPOSE 3000

# Start the application
CMD ["yarn", "start"] 