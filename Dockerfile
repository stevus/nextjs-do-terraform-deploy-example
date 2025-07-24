# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /src/app
COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Stage 2: Production image
FROM node:20-alpine

WORKDIR /src/app

# Only copy production dependencies
COPY --from=builder /src/app/package*.json ./
RUN npm ci --omit=dev

COPY --from=builder /src/app/.next .next
COPY --from=builder /src/app/public public
COPY --from=builder /src/app/next.config.ts ./
COPY --from=builder /src/app/node_modules node_modules

EXPOSE 3000
ENV NODE_ENV=production
CMD ["npm", "run", "start"]
