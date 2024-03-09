ARG NODE_VERSION=21
FROM node:${NODE_VERSION}-slim AS base

# Set up working directory and base config
ARG APP_DIR="/opt/app"
ENV APP_DIR="${APP_DIR}"
ENV PNPM_HOME="/opt/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN mkdir -p "${APP_DIR}" "${PNPM_HOME}" &&\
  chown -R 1000:1000 "${APP_DIR}" &&\
  chown -R 1000:1000 "${PNPM_HOME}";
WORKDIR ${APP_DIR}

# Install dependent software
RUN apt-get update -qq &&\
  apt-get install -y --no-install-recommends \
  apt-transport-https \
  ca-certificates &&\
  # Clean up after aptitude
  apt-get autoremove -y && apt-get clean -y &&\
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* &&\
  # Enable corepack
  corepack enable;



###
# Development Stage
#  - Use the `DEV_PACKAGES` argument to install additional
#    desired 'personal preference' packages within development.
#  - As an example, `zsh` to make the container terminal more like the
#    host terminal.
###
FROM base AS develop
ARG DEV_PACKAGES
RUN apt-get update -qq &&\
  apt-get install -y --no-install-recommends \
  curl \
  git \
  ssh \
  sudo \
  ${DEV_PACKAGES} &&\
  # Clean up after aptitude
  apt-get autoremove -y && apt-get clean -y &&\
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*;

# Allow user to sudo without password (since it's not known)
RUN usermod -a -G sudo node &&\
  sed -i /etc/sudoers -re 's/^%sudo.*/%sudo   ALL=(ALL:ALL) NOPASSWD: ALL/g'
USER 1000

# Since this is a development container, the command should just run the
# container without starting any "real" processes, as those will be run
# as part of the development itself.
CMD ["/bin/sh", "-c", "while true; do sleep 60; done"]


###
# Production Stage
###
FROM base AS prod
USER 1000
COPY package.json ./
RUN pnpm install
COPY . .
CMD node index.js
