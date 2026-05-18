# Imagen base corporativa DEV para Node.js 14
FROM debian@sha256:89400a8b54c93d61bb2f971f1ada1d907b344f2422afabf23699fdf1f162faa0

LABEL maintainer="Equipo de Arquitectura y Seguridad <arquitectura@empresa.com>"
LABEL version="1.0.2"
LABEL description="Imagen base corporativa DEV para Node.js 14 sobre Debian Slim"

ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_VERSION=14.21.3
ENV ARCH=x64
ENV WORKDIR=/usr/src/app

ENV NPM_CONFIG_FUND=false
ENV NPM_CONFIG_AUDIT=false
ENV NPM_CONFIG_UPDATE_NOTIFIER=false
ENV NPM_CONFIG_LOGLEVEL=warn

# 1. OPTIMIZACIÓN: Creación de usuario antes de descargar Node (Caché persistente)
RUN groupadd -g 10001 nodegroup && \
    useradd -u 10001 -g nodegroup -s /bin/bash -m nodeuser && \
    mkdir -p ${WORKDIR}

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
    rm -rf /tmp/* \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs

# 2. SUGERENCIA: Instalación de gestores de paquetes y limpieza de caché (como root)
RUN npm install -g yarn@1.22.19 pnpm@7 && npm cache clean --force

# 3. OPTIMIZACIÓN: Cambio de permisos del WORKDIR agrupado al final
RUN chown -R nodeuser:nodegroup ${WORKDIR}

WORKDIR ${WORKDIR}

USER nodeuser

RUN node -v && npm -v && yarn -v && pnpm -v && git --version

ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["bash"]