ARG NODE_VERSION=22

FROM node:${NODE_VERSION}-alpine AS git_clone

RUN apk --no-cache add git
RUN git clone --depth 1 --branch v11.8.0 https://github.com/directus/directus.git

####################################################################################################
####################################################################################################
##
## Original Dockerfile
##
## From https://github.com/directus/directus/tree/v11.8.0
##
####################################################################################################
####################################################################################################

####################################################################################################
## Build Packages

FROM node:${NODE_VERSION}-alpine AS builder

# Remove again once corepack >= 0.31 made it into base image
# (see https://github.com/directus/directus/issues/24514)
RUN npm install --global corepack@latest

RUN apk --no-cache add python3 py3-setuptools build-base

WORKDIR /directus

COPY --from=git_clone /directus/package.json .
RUN corepack enable && corepack prepare

# Deploy as 'node' user to match pnpm setups in production image
# (see https://github.com/directus/directus/issues/23822)
RUN chown node:node .
USER node

ENV NODE_OPTIONS=--max-old-space-size=8192

COPY --from=git_clone /directus/pnpm-lock.yaml .
RUN pnpm fetch

COPY --from=git_clone --chown=node:node /directus/. .
RUN <<EOF
	set -ex
	pnpm install --recursive --offline --frozen-lockfile
	npm_config_workspace_concurrency=1 pnpm run build
	pnpm --filter directus deploy --prod dist
	cd dist
	# Regenerate package.json file with essential fields only
	# (see https://github.com/directus/directus/issues/20338)
	node -e '
		const f = "package.json", {name, version, type, exports, bin} = require(`./${f}`), {packageManager} = require(`../${f}`);
		fs.writeFileSync(f, JSON.stringify({name, version, type, exports, bin, packageManager}, null, 2));
	'
	mkdir -p database extensions uploads
EOF

####################################################################################################
## Create Production Image

FROM node:${NODE_VERSION}-alpine AS runtime

RUN npm install --global \
	pm2@5 \
	corepack@latest # Remove again once corepack >= 0.31 made it into base image

USER node

WORKDIR /directus

ENV \
	DB_CLIENT="sqlite3" \
	DB_FILENAME="/directus/database/database.sqlite" \
	NODE_ENV="production" \
	NPM_CONFIG_UPDATE_NOTIFIER="false"

COPY --from=builder --chown=node:node /directus/ecosystem.config.cjs .
COPY --from=builder --chown=node:node /directus/dist .

EXPOSE 8055

CMD : \
	&& node cli.js bootstrap \
	&& pm2-runtime start ecosystem.config.cjs \
	;

####################################################################################################
####################################################################################################
##
## End Original Dockerfile
##
####################################################################################################
####################################################################################################

# FROM directus/directus:11.8.0

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
