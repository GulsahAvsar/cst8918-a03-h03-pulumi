# Base Node image
FROM node:lts-alpine AS base

# Update the OpenSSL package to address security patches
# @see CVE-2023-6129
RUN apk add --no-cache openssl

# Set environment variable for base and inheriting layers
ENV NODE_ENV=production

# Install all node_modules, including dev dependencies
FROM base AS deps

WORKDIR /usr/src/app

# Add package.json and install dependencies
COPY package.json ./
RUN npm install --include=dev

# Prepare production-only node_modules
FROM base AS production-deps

WORKDIR /usr/src/app

COPY --from=deps /usr/src/app/node_modules /usr/src/app/node_modules
COPY package.json ./
RUN npm prune --omit=dev

# Build the application
FROM base AS build

WORKDIR /usr/src/app

COPY --from=deps /usr/src/app/node_modules /usr/src/app/node_modules
COPY . .  # Copy all files required for building/
RUN npm run build

# Create the final production image with minimal footprint
FROM base

WORKDIR /usr/src/app

COPY --from=production-deps /usr/src/app/node_modules /usr/src/app/node_modules
COPY --from=build /usr/src/app/build /usr/src/app/build
COPY --from=build /usr/src/app/public /usr/src/app/public
COPY --from=build /usr/src/app/package.json /usr/src/app/package.json

# Set the command to start the application
CMD ["./node_modules/.bin/remix-serve", "./build/index.js"]

