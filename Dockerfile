# syntax=docker/dockerfile:1

# Stage 1: Install dependencies and build Strapi
FROM node:24-alpine AS build

RUN apk add --no-cache \
    build-base \
    gcc \
    autoconf \
    automake \
    zlib-dev \
    libpng-dev \
    bash \
    vips-dev \
    git

WORKDIR /opt/

COPY package.json package-lock.json ./

RUN npm install -g node-gyp \
    && npm config set fetch-retry-maxtimeout 600000 -g \
    && npm ci

ENV PATH=/opt/node_modules/.bin:$PATH

WORKDIR /opt/app

COPY . .

ENV NODE_ENV=production

RUN npm run build


# Stage 2: Production runtime
FROM node:24-alpine AS production

RUN apk add --no-cache vips-dev

ENV NODE_ENV=production

WORKDIR /opt/

COPY --from=build /opt/package.json /opt/package-lock.json ./

RUN npm ci --omit=dev \
    && npm cache clean --force

ENV PATH=/opt/node_modules/.bin:$PATH

WORKDIR /opt/app

COPY --from=build --chown=node:node /opt/app ./

USER node

EXPOSE 1337

CMD ["npm", "run", "start"]

