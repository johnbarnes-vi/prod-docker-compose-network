#!/bin/bash

# Check if domain name is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 domain_name"
    echo "Example: $0 example.com"
    exit 1
fi

DOMAIN=$1
# Convert domain to lowercase and remove .com for service names
SERVICE_NAME=$(echo "$DOMAIN" | sed 's/\.com$//' | tr '[:upper:]' '[:lower:]')

# Base directory
BASE_DIR=~/production

# Create nginx config
create_nginx_config() {
    local config_file="$BASE_DIR/nginx-proxy/conf.d/sites/${SERVICE_NAME}.conf"
    cat > "$config_file" << EOF
# Multi-domain SSL certificate configuration
# Although this site is ${DOMAIN}, we use the certificate at
# /etc/letsencrypt/live/myflashpal.com/ because it's a multi-domain certificate valid for:
# - myflashpal.com
# - www.myflashpal.com
# - ...
# - ${DOMAIN}
# - www.${DOMAIN}
# The directory name 'myflashpal.com' is just organizational and doesn't affect certificate validity

server {
    listen       443 ssl;
    http2        on;
    server_name  ${DOMAIN} www.${DOMAIN};
    
    ssl_certificate /etc/letsencrypt/live/myflashpal.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/myflashpal.com/privkey.pem;

    location / {
        proxy_pass http://${SERVICE_NAME}-frontend;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /api/ {
        proxy_pass http://${SERVICE_NAME}-backend:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Block WordPress scanning attempts
    location ~* ^/(?:wp-admin|wp-login|wordpress|wp-content|wp-includes)/ {
        deny all;
        return 403;  # Return Forbidden instead of 404
        
        # Optional: Add security headers
        add_header X-Robots-Tag "noindex, nofollow" always;
        add_header X-Content-Type-Options "nosniff" always;
    }
}
EOF
}

# Create Dockerfiles
create_dockerfiles() {
    # Create directories if they don't exist
    mkdir -p "$BASE_DIR/docker/$SERVICE_NAME"
    
    # Create react-app Dockerfile
    cat > "$BASE_DIR/docker/$SERVICE_NAME/react-app.Dockerfile" << EOF
FROM nginx:alpine
# Just serve a simple "coming soon" page
RUN echo "<h1>${DOMAIN} - Coming Soon</h1>" > /usr/share/nginx/html/index.html
CMD ["nginx", "-g", "daemon off;"]
EOF

    # Create server Dockerfile
    cat > "$BASE_DIR/docker/$SERVICE_NAME/server.Dockerfile" << EOF
FROM node:20.10.0
WORKDIR /app
# Create minimal express server
RUN echo '{"name":"${SERVICE_NAME}-backend","version":"1.0.0"}' > package.json && \\
    echo 'require("http").createServer((req,res)=>{res.end("API Coming Soon")}).listen(5000)' > index.js
CMD ["node", "index.js"]
EOF
}

# Create site directories
create_site_directories() {
    mkdir -p "$BASE_DIR/sites/$SERVICE_NAME/react-app"
    mkdir -p "$BASE_DIR/sites/$SERVICE_NAME/server"
}

# Update docker-compose.yml
update_docker_compose() {
    local compose_file="$BASE_DIR/docker-compose.yml"
    # Add new services to docker-compose.yml
    cat >> "$compose_file" << EOF



  ${SERVICE_NAME}-frontend:
    build:
      context: ./sites/${SERVICE_NAME}/react-app
      dockerfile: ../../../docker/${SERVICE_NAME}/react-app.Dockerfile
    depends_on:
      - ${SERVICE_NAME}-backend

  ${SERVICE_NAME}-backend:
    build:
      context: ./sites/${SERVICE_NAME}/server
      dockerfile: ../../../docker/${SERVICE_NAME}/server.Dockerfile
    environment:
      - DOCKER_ENV=true
    # env_file commented out until needed
    # env_file:
    #   - ./sites/${SERVICE_NAME}/server/.env
EOF

    echo "Remember to add ${SERVICE_NAME}-frontend to nginx-proxy depends_on in docker-compose.yml"
}

# Main execution
echo "Setting up new site for $DOMAIN..."
create_nginx_config
create_dockerfiles
create_site_directories
update_docker_compose

echo "Setup complete! Next steps:"
echo "1. Add the domain to your Let's Encrypt certificate"
echo "2. Add ${SERVICE_NAME}-frontend to nginx-proxy depends_on in docker-compose.yml"
echo "3. Run 'docker-compose up -d --build' to apply changes"