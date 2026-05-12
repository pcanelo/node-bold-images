# ETAPA 1: BUILDER (Descarga y Preparación)
# FROM debian@sha256:67b30a61dc87758f0caf819646104f29ecbda97d920aaf5edc834128ac8493d3 AS builder
FROM debian:bookworm-slim
ENV NODE_VERSION=20.20.2
ENV ARCH=x64

# Instalamos herramientas necesarias SOLO para la descarga y extracción
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl xz-utils

WORKDIR /tmp

# Descarga del binario oficial y extracción
RUN curl -fsSLO https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt && \
    curl -fsSLO https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${ARCH}.tar.xz && \
    grep " node-v${NODE_VERSION}-linux-${ARCH}.tar.xz\$" SHASUMS256.txt | sha256sum -c - && \
    mkdir -p /tmp/node && \
    tar -xJf "node-v${NODE_VERSION}-linux-${ARCH}.tar.xz" -C /tmp/node --strip-components=1

# ---------------------------------------------------------------------

# ETAPA 2: RUNTIME (Imagen Final Dorada)
FROM debian@sha256:67b30a61dc87758f0caf819646104f29ecbda97d920aaf5edc834128ac8493d3 AS runtime

LABEL maintainer="Equipo de Arquitectura y Seguridad <arquitectura@empresa.com>"
LABEL version="1.0.0"
LABEL description="Imagen base corporativa optimizada para Node.js 20 sobre Debian Slim"

ENV DEBIAN_FRONTEND=noninteractive
ENV WORKDIR=/usr/src/app

ENV NODE_ENV=production
ENV NPM_CONFIG_FUND=false
ENV NPM_CONFIG_AUDIT=false
ENV NPM_CONFIG_UPDATE_NOTIFIER=false
ENV NPM_CONFIG_LOGLEVEL=warn

# 1. Instalamos tini (gestor de procesos para PID 1)
# 2. Creamos el usuario no-root (nodeuser)
# 3. Limpiamos cache de apt inmediatamente
RUN apt-get update && \
    apt-get install -y --no-install-recommends tini ca-certificates && \
    groupadd -g 10001 nodegroup && \
    useradd -u 10001 -g nodegroup -s /bin/false -m nodeuser && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p ${WORKDIR} && \
    chown -R nodeuser:nodegroup ${WORKDIR}

# COPIA ATÓMICA: Traemos Node.js desde la etapa builder
COPY --from=builder /tmp/node /usr/local/

# Enlace simbólico para compatibilidad
RUN ln -s /usr/local/bin/node /usr/local/bin/nodejs

WORKDIR ${WORKDIR}
USER nodeuser

# Verificación de integridad en el build
RUN node -v && npm -v

# ENTRYPOINT con tini asegura que Node reciba correctamente las señales SIGTERM/SIGINT
ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["node"]
