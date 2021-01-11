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
    ca-certificates \
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

RUN echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/${MONGO_MAJOR} multiverse" | tee /etc/apt/sources.list.d/mongodb-org-${MONGO_MAJOR}.list

# Install mongodb server along with mongos, shell and other tools
RUN set -x \
  && ln -s /bin/true /usr/local/bin/systemctl \
  && export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get install -y \
    mongodb-org=${MONGO_VERSION} \
    mongodb-org-server=${MONGO_VERSION} \
    mongodb-org-shell=${MONGO_VERSION} \
    mongodb-org-mongos=${MONGO_VERSION} \
    mongodb-org-tools=${MONGO_VERSION} \
  && rm -rf /var/lib/apt/lists/* \
  && rm -f /usr/local/bin/systemctl \
  && rm -rf /var/lib/mongodb \
  && mv /etc/mongod.conf /etc/mongod.conf.orig

# Create the data db and config folders
RUN mkdir -p /data/db /config/mongo \
  && chown -R mongodb:mongodb /data/db /config/mongo

VOLUME ["/data/db", "/config/mongo"]

# Copy the default config file
COPY config/mongod.conf /config/mongod.conf

# Set the container's entry point
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x usr/local/bin/docker-entrypoint.sh \
  && ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 27017
CMD ["mongod"]