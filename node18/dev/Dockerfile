# Imagen base corporativa DEV para Node.js 18
# Utilizamos Debian 12 Bookworm Slim para versiones recientes de Node.js
# FROM debian@sha256:67b30a61dc87758f0caf819646104f29ecbda97d920aaf5edc834128ac8493d3
FROM debian:bookworm-slim
LABEL maintainer="Equipo de Arquitectura y Seguridad <arquitectura@empresa.com>"
LABEL version="1.0.0"
LABEL description="Imagen base corporativa DEV para Node.js 18 sobre Debian Slim"

ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_VERSION=18.20.8
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
