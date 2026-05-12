# Imagen base corporativa DEV para Node.js 14
# FROM debian@sha256:89400a8b54c93d61bb2f971f1ada1d907b344f2422afabf23699fdf1f162faa0
FROM debian:bullseye-slim
LABEL maintainer="Equipo de Arquitectura y Seguridad <arquitectura@empresa.com>"
LABEL version="1.0.1"
LABEL description="Imagen base corporativa DEV para Node.js 14 sobre Debian Slim"

ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_VERSION=14.21.3
ENV ARCH=x64
ENV WORKDIR=/usr/src/app

ENV NPM_CONFIG_FUND=false
ENV NPM_CONFIG_AUDIT=false
ENV NPM_CONFIG_UPDATE_NOTIFIER=false
ENV NPM_CONFIG_LOGLEVEL=warn

# Herramientas permitidas en DEV
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      xz-utils \
      git \
      tini \
      bash \
      make \
      g++ \
      python3 \
      procps \
      iputils-ping \
      netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

# Descarga y validación SHA256 de Node.js
RUN curl -fsSLO https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt && \
    curl -fsSLO https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${ARCH}.tar.xz && \
    grep " node-v${NODE_VERSION}-linux-${ARCH}.tar.xz\$" SHASUMS256.txt | sha256sum -c - && \
    mkdir -p /tmp/node && \
    tar -xJf "node-v${NODE_VERSION}-linux-${ARCH}.tar.xz" -C /usr/local --strip-components=1 && \
    rm -rf /tmp/*

# Usuario no-root igual que PROD
RUN groupadd -g 10001 nodegroup && \
    useradd -u 10001 -g nodegroup -s /bin/bash -m nodeuser && \
    mkdir -p ${WORKDIR} && \
    chown -R nodeuser:nodegroup ${WORKDIR}

RUN ln -s /usr/local/bin/node /usr/local/bin/nodejs

WORKDIR ${WORKDIR}

USER nodeuser

RUN node -v && npm -v && git --version

ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["bash"]
