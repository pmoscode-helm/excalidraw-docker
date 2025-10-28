FROM node:24 AS build

WORKDIR /opt/node_app

COPY ./excalidraw .

# do not ignore optional dependencies:
# Error: Cannot find module @rollup/rollup-linux-x64-gnu
RUN yarn --network-timeout 600000

ARG NODE_ENV=production

RUN yarn build:app:docker

FROM nginx:1.29-alpine

ENV APP_WS_OLD_SERVER_URL="https://oss-collab.excalidraw.com"
ENV APP_WS_NEW_SERVER_URL="http://localhost:3002"

COPY --from=build /opt/node_app/excalidraw-app/build /usr/share/nginx/html

COPY nginx-init-scripts/hack_it.sh /docker-entrypoint.d/99_hack_it.sh
RUN chmod +x /docker-entrypoint.d/99_hack_it.sh

HEALTHCHECK CMD wget -q -O /dev/null http://localhost || exit 1
