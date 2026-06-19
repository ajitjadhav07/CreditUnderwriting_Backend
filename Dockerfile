# ============================================================
# Axis Underwriting Agent — App Server (App EC2)
# API + Socket.io + OAuth handshake + all business logic
# ============================================================

# ---- deps stage: install only what's needed to run ----
FROM node:20-slim AS deps
WORKDIR /usr/src/app

COPY package.json ./
# No package-lock.json checked in yet — using `npm install`.
# Once you generate one (`npm install` locally, commit package-lock.json),
# switch this to `npm ci --omit=dev` for reproducible, faster builds.
RUN npm install --omit=dev && npm cache clean --force

# ---- runtime stage ----
FROM node:20-slim AS runtime
WORKDIR /usr/src/app

ENV NODE_ENV=production

# Non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

COPY --from=deps /usr/src/app/node_modules ./node_modules
COPY . .

RUN chown -R appuser:appuser /usr/src/app
USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:'+(process.env.PORT||3000)+'/health',(r)=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"

CMD ["node", "server.js"]
