FROM directus/directus:11.8.0

USER root
RUN corepack enable \
  && corepack prepare pnpm@8.1.1 --activate \
  # Currently required, we'll probably address this in the base image in future release
  && chown node:node /directus

USER node
