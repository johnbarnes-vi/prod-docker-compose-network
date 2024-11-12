# Multi-Site Docker Production Setup

This repository contains the infrastructure setup for hosting multiple websites on a single Docker host. It provides a scalable way to add new sites while maintaining separation of concerns and allowing independent development of each site.

## Repository Structure

```
~/production/
├── docker/                     # Docker configurations
│   ├── myflashpal/
│   │   ├── react-app.Dockerfile
│   │   └── server.Dockerfile
│   ├── .../
│   └── lonestarstatuary/
│       ├── react-app.Dockerfile
│       └── server.Dockerfile
├── docker-compose.yml         # Main docker compose file
├── nginx-proxy/              # Nginx reverse proxy configs
│   └── conf.d/
│       ├── default.conf
│       └── sites/
│           ├── myflashpal.conf
│           ├── ...
│           └── lonestarstatuary.conf
└── sites/                    # Individual site repositories
    └── [not tracked in git]  # Clone actual site repos here using service names
```

## Adding a New Site

1. Use the provided script to create boilerplate configuration:
```bash
./add-site.sh example.com
```

This will:
- Create nginx configuration in `nginx-proxy/conf.d/sites/`
- Create Docker configurations in `docker/`
- Set up directory structure in `sites/` (using domain name without .com)
- Add services to docker-compose.yml

2. Set up the actual website:
```bash
cd ~/production/sites/
# Note: we use the domain name WITHOUT .com
git clone your-website-repo example
```

## Website Development

Each website in the `sites/` directory can be its own independent git repository. The `sites/` directory is ignored in the main infrastructure repository to allow for this separation.

### Example Site Structure
```
sites/example/              # Note: no .com in directory name
├── react-app/             # Frontend code
│   ├── src/
│   ├── public/
│   └── package.json
└── server/               # Backend code
    ├── src/
    └── package.json
```

## SSL Certificate Configuration

All sites use a multi-domain SSL certificate from Let's Encrypt. When adding a new site, you need to:

1. Stop nginx to free port 80:
```bash
docker-compose stop nginx-proxy
```

2. Update the certificate to include the new domain:
```bash
certbot certonly --standalone \
    -d myflashpal.com \
    -d www.myflashpal.com \
    -d lonestarstatuary.com \
    -d www.lonestarstatuary.com \
    -d ... (insert all domain names to this list) \
    -d example.com \
    -d www.example.com
```

3. Restart nginx:
```bash
docker-compose start nginx-proxy
```

The certificate path in the nginx configuration will always point to `/etc/letsencrypt/live/myflashpal.com/` regardless of the domain, as this is the primary domain name in the certificate.

## Updating from Boilerplate to Production

When you're ready to deploy actual website content, you'll need to update the Dockerfiles from the boilerplate versions to handle your actual application files.

### Example Frontend Dockerfile Evolution

From boilerplate:
```dockerfile
FROM nginx:alpine
RUN echo "<h1>Coming Soon</h1>" > /usr/share/nginx/html/index.html
CMD ["nginx", "-g", "daemon off;"]
```

To production version:
```dockerfile
# Build stage
FROM node:20.10.0 as build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Serve stage
FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
CMD ["nginx", "-g", "daemon off;"]
```

### Example Backend Dockerfile Evolution

From boilerplate:
```dockerfile
FROM node:20.10.0
WORKDIR /app
RUN echo '{"name":"site-backend","version":"1.0.0"}' > package.json && \
    echo 'require("http").createServer((req,res)=>{res.end("API Coming Soon")}).listen(5000)' > index.js
CMD ["node", "index.js"]
```

To production version:
```dockerfile
FROM node:20.10.0
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 5000
CMD ["node", "index.js"]
```

## Deployment

After making changes:
```bash
cd ~/production
docker-compose down
docker-compose up -d --build
```

This will:
- Rebuild all modified containers
- Update the nginx configuration
- Restart the necessary services

## Notes

- The `sites/` directory is gitignored in this repo because each site should be its own git repository
- The nginx-proxy configurations in `nginx-proxy/conf.d/sites/` ARE tracked in this repo
- All Docker configurations in `docker/` are tracked in this repo
- Remember to update `docker-compose.yml` dependencies when adding new sites