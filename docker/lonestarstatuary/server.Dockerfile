# ~/mfp/sites/lonestarstatuary/server/Dockerfile
FROM node:20.10.0
WORKDIR /app
# Create minimal express server
RUN echo '{"name":"lonestarstatuary-backend","version":"1.0.0"}' > package.json && \
    echo 'require("http").createServer((req,res)=>{res.end("API Coming Soon")}).listen(5000)' > index.js
CMD ["node", "index.js"]