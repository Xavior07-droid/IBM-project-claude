# ==============================================================================
# This is a two-service application (React frontend + Express backend), each
# with its own optimized Dockerfile:
#   - ./server/Dockerfile   (Node.js API)
#   - ./client/Dockerfile   (React build served via nginx)
#
# Building them together is handled by docker-compose.yml at the project root:
#
#   docker compose up --build
#
# This root-level Dockerfile builds ONLY the backend API server, for platforms
# that expect a single Dockerfile at the repo root (e.g. some AWS App Runner
# or single-container PaaS setups). For the full stack (frontend + backend),
# use docker-compose instead.
# ==============================================================================

FROM node:22-alpine AS base
WORKDIR /app

COPY server/package*.json ./
RUN npm install --omit=dev

COPY server/ .

RUN mkdir -p /app/data

ENV NODE_ENV=production
EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:5000/api/health', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

CMD ["node", "src/server.js"]
