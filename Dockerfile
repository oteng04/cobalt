FROM node:24-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

FROM base AS build
WORKDIR /app
COPY . /app

RUN corepack enable
RUN apk add --no-cache python3 alpine-sdk

RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --prod --frozen-lockfile

RUN pnpm deploy --filter=@imput/cobalt-api --prod /prod/api

FROM base AS api
WORKDIR /app

COPY --from=build --chown=node:node /prod/api /app

# Create a fake git repo so Cobalt doesn't crash on startup
RUN mkdir -p /app/.git/refs/heads /app/.git/logs/refs/heads && \
    echo "ref: refs/heads/main" > /app/.git/HEAD && \
    echo "0000000000000000000000000000000000000000 0000000000000000000000000000000000000000 nobody nobody@example.com 1700000000 +0000\tcommit (initial): fake" > /app/.git/logs/HEAD && \
    echo "0000000000000000000000000000000000000000 0000000000000000000000000000000000000000 nobody nobody@example.com 1700000000 +0000\tcommit (initial): fake" > /app/.git/logs/refs/heads/main && \
    echo "0000000000000000000000000000000000000000" > /app/.git/refs/heads/main && \
    chown -R node:node /app/.git

USER node

EXPOSE 9000
CMD [ "node", "src/cobalt" ]
