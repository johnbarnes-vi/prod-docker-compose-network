# ~/production/sites/myflashpal/server/Dockerfile

# Step 1: Use an official Node runtime as a parent image with specific version 20.10.0
FROM node:20.10.0

# Set the working directory in the container to /app
WORKDIR /app

# Copy the package.json and package-lock.json files
COPY package*.json ./

# Install any needed packages specified in package.json
RUN npm install

# Bundle the app source inside the Docker image
COPY . .

# Your app binds to port 5000 so you'll use the EXPOSE instruction to have it mapped by the docker daemon
EXPOSE 5000

# Define the command to run the app using CMD which defines your runtime
CMD ["node", "index.js"]
