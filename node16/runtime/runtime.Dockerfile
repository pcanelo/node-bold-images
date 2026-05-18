# ETAPA 1: BUILDER (Descarga y Preparación)
FROM debian@sha256:89400a8b54c93d61bb2f971f1ada1d907b344f2422afabf23699fdf1f162faa0 AS builder

ENV NODE_VERSION=16.20.2
ENV ARCH=x64

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl xz-utils

WORKDIR /tmp

RUN curl -fsSLO https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt && \
    curl -fsSLO https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${ARCH}.tar.xz && \
    grep " node-v${NODE_VERSION}-linux-${ARCH}.tar.xz\$" SHASUMS256.txt | sha256sum -c - && \
    mkdir -p /tmp/node && \
    tar -xJf "node-v${NODE_VERSION}-linux-${ARCH}.tar.xz" -C /tmp/node --strip-components=1

# ---------------------------------------------------------------------

# ETAPA 2: RUNTIME (Imagen Final Dorada)
FROM debian@sha256:89400a8b54c93d61bb2f971f1ada1d907b344f2422afabf23699fdf1f162faa0 AS runtime

LABEL maintainer="Equipo de Arquitectura y Seguridad <arquitectura@empresa.com>"
LABEL version="1.0.1"
LABEL description="Imagen base corporativa optimizada para Node.js 16 sobre Debian Slim"

ENV DEBIAN_FRONTEND=noninteractive
ENV WORKDIR=/usr/src/app

ENV NODE_ENV=production
ENV NPM_CONFIG_FUND=false
ENV NPM_CONFIG_AUDIT=false
ENV NPM_CONFIG_UPDATE_NOTIFIER=false
ENV NPM_CONFIG_LOGLEVEL=warn

# Creación de usuario arriba (Caché persistente) y shell /bin/bash corregida
RUN groupadd -g 10001 nodegroup && \
    useradd -u 10001 -g nodegroup -s /bin/bash -m nodeuser && \
    mkdir -p ${WORKDIR}

# Sistema operativo mínimo y limpieza inmediata de listas
RUN apt-get update && \
    apt-get install -y --no-install-recommends tini ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copia atómica de Node.js desde la etapa builder
COPY --from=builder /tmp/node /usr/local/

RUN ln -s /usr/local/bin/node /usr/local/bin/nodejs && \
    chown -R nodeuser:nodegroup ${WORKDIR}

WORKDIR ${WORKDIR}
USER nodeuser

# Verificación de integridad en el build
RUN node -v && npm -v

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node"]