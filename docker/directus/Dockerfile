FROM directus/directus:11.8.0

USER root
RUN corepack enable \
    && corepack prepare pnpm@8.1.1 --activate \
    # Currently required, we'll probably address this in the base image in future release
    && chown node:node /directus

USER node

EXPOSE 8055

HEALTHCHECK \
    --start-interval=1s \
    --start-period=30s \
    --interval=30s \
    --timeout=20s \
    --retries=5 \
    CMD [ $(wget -q -O - http://127.0.0.1:8055/server/ping) = 'pong' ]
