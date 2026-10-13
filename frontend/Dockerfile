# syntax=docker/dockerfile:1
# EventFlow frontend — Next.js production image (`next build` + `next start`).
#
# NOT a static export: the app has dynamic routes, so it needs a Node server.
# Multi-stage: dev dependencies stay in the build stage; the runtime image
# carries production node_modules + .next only, running as the non-root
# `node` user. NEXT_PUBLIC_API_URL is a build ARG — .env* files are never
# copied into the image (see .dockerignore), so the inlined API origin comes
# exclusively from the build argument.

FROM node:20-alpine AS deps

WORKDIR /app
COPY package.json package-lock.json ./
# Full install here (devDependencies: typescript, tailwind tooling … are
# needed by `next build`).
RUN npm ci


FROM node:20-alpine AS build

WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build-time API origin. next.config.mjs fails the build when this is
# missing (or points at localhost) during `next build`.
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}
RUN npm run build


FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production \
    PORT=3000 \
    HOSTNAME=0.0.0.0

# Production dependencies only.
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY --from=build --chown=node:node /app/.next ./.next
COPY --from=build --chown=node:node /app/next.config.mjs ./next.config.mjs
# public/ ships empty today but must stay in git (public/.gitkeep): a COPY
# source that is absent from the build context fails the whole image build.
COPY --chown=node:node public ./public

# The `node` user (uid 1000) ships with the base image — never run as root.
USER node

EXPOSE 3000

# Invoked exactly like the legacy systemd unit: node directly, not npm.
CMD ["node", "node_modules/next/dist/bin/next", "start"]
