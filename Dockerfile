# syntax = docker/dockerfile:1

ARG NODE_VERSION=18.18.0
FROM node:$NODE_VERSION-slim as base

LABEL fly_launch_runtime="NodeJS"

# NodeJS app lives here
WORKDIR /app

# Set production environment
ENV NODE_ENV=production

# Throw-away build stage to reduce size of final image
FROM base as build

# Install packages needed to build node modules
RUN apt-get update -qq && \
  apt-get install -y python-is-python3 pkg-config build-essential 

COPY <<-"EOF" /app/package.json
{
  "name": "nodejs-finance",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "type": "module",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1",
    "dev": "nodemon index.js",
    "start": "node index.js"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "body-parser": "^1.20.2",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "express": "^4.18.2",
    "helmet": "^7.1.0",
    "mongoose": "^7.0.0",
    "mongoose-currency": "^0.2.0",
    "morgan": "^1.10.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  },
  "engines": {
    "node": "18.18.0"
  }
}
EOF

RUN npm install --legacy-peer-deps

# Copy application code
COPY --link . .

# Remove development dependencies
RUN npm prune --production --legacy-peer-deps

# Final stage for app image
FROM base

# Copy built application
COPY --from=build /app /app

# Start the server by default, this can be overwritten at runtime
CMD [ "npm", "run", "start" ]