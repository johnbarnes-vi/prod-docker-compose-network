FROM nginx:alpine
# Just serve a simple "coming soon" page
RUN echo "<h1>boilerplate.com - Coming Soon</h1>" > /usr/share/nginx/html/index.html
CMD ["nginx", "-g", "daemon off;"]
