FROM node:22-alpine
WORKDIR /app
COPY package.json engine.mjs intelligence.mjs server.mjs ./
RUN mkdir -p /data && chown node:node /data
USER node
ENV HOST=0.0.0.0 PORT=4179 NODE_ENV=production CRESUS_DB_PATH=/data/onboarding.sqlite
EXPOSE 4179
CMD ["node","server.mjs"]
