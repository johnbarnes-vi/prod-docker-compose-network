# ~/production/sites/lonestarstatuary/react-app/Dockerfile

# Build stage
FROM node:20.10.0 as build

WORKDIR /app

# Copy shared module first
COPY shared/package*.json ./shared/
RUN cd shared && npm install

# Copy React app package files
COPY react-app/package*.json ./react-app/
RUN cd react-app && npm install

# Copy source files
COPY shared/ ./shared/
COPY react-app/ ./react-app/

# Build shared module
RUN cd shared && npm run build

# Build the app (will now be able to find @lonestar/shared)
RUN cd react-app && npm run build

# Serve stage
FROM nginx:alpine

# Copy built assets from build stage
COPY --from=build /app/react-app/build /usr/share/nginx/html

CMD ["nginx", "-g", "daemon off;"]