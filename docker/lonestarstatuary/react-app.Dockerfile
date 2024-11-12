# ~/mfp/sites/lonestarstatuary/react-app/Dockerfile
FROM nginx:alpine
# Just serve a simple "coming soon" page
RUN echo "<h1>Lone Star Statuary - Coming Soon</h1>" > /usr/share/nginx/html/index.html
CMD ["nginx", "-g", "daemon off;"]