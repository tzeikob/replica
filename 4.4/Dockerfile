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