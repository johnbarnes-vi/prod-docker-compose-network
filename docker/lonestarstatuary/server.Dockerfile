# ~/production/sites/lonestarstatuary/server/Dockerfile

FROM node:20.10.0

WORKDIR /app

# Copy shared module first
COPY shared/package*.json ./shared/
RUN cd shared && npm install

# Copy server package files
COPY server/package*.json ./server/
RUN cd server && npm install

# Copy source files
COPY shared/ ./shared/
COPY server/ ./server/

# Build shared module
RUN cd shared && npm run build

# Build server (will now be able to find @lonestar/shared)
RUN cd server && npm run build

EXPOSE 5000

# Run the compiled app
CMD ["node", "server/dist/server/src/index.js"]