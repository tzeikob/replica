# Pull the base image
FROM ubuntu:18.04

# Create mongodb user group and user
RUN groupadd -r mongodb && useradd -r -g mongodb mongodb

# Install various third-party dependencies
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    nano \
    gnupg \
    gosu \
  && rm -rf /var/lib/apt/lists/*

# Add mongodb public repository
RUN set -ex; \
  key='20691EEC35216C63CAF66CE1656408E390CFB1F5'; \
  export GNUPGHOME="$(mktemp -d)"; \
  ( \
    gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" \
    || gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" \
    || gpg --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" \
    || gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" \
  ); \
  gpg --batch --export "$key" > /etc/apt/trusted.gpg.d/mongodb.gpg; \
  gpgconf --kill all; \
  rm -rf "$GNUPGHOME"; \
  apt-key list > /dev/null

ENV MONGO_MAJOR=4.4
ENV MONGO_VERSION=4.4.3

RUN echo "deb http://repo.mongodb.org/apt/ubuntu bionic/mongodb-org%-unstable/4.4 multiverse" | tee "/etc/apt/sources.list.d/mongodb-org%-unstable.list"