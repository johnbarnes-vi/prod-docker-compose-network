# ~/production/sites/lonestarstatuary/server/Dockerfile

FROM node:20.10.0

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm install

# Copy source code
COPY . .

# Build TypeScript
RUN npm run build

EXPOSE 5000

# Run the compiled app
CMD ["npm", "start"]