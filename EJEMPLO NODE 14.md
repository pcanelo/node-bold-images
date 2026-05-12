# Ejemplo de Guía Técnica: Imagen Base Corporativa para Node.js 14 sobre Debian

## 1. Objetivo de la guía

El propósito de esta guía es establecer un estándar corporativo para la creación de imágenes base de contenedor orientadas a aplicaciones Node.js 14 utilizando Debian como sistema operativo subyacente. Esta imagen base está diseñada para ser utilizada por los equipos de desarrollo en proyectos legacy que aún dependen de esta versión específica del runtime.

**Advertencia Crítica de Seguridad:** Node.js 14 alcanzó su estado de Fin de Vida (End-of-Life, EOL) el 30 de abril de 2023. Esto significa que ya no recibe actualizaciones de seguridad, correcciones de errores ni parches para vulnerabilidades críticas. El uso de esta versión en entornos de producción representa un riesgo significativo para la seguridad de la cadena de suministro de software (software supply chain). Esta guía se proporciona estrictamente para cumplir con un requerimiento corporativo transitorio, pero se recomienda encarecidamente priorizar la migración a versiones LTS activas (como Node.js 18 o 20) lo antes posible.

## 2. Consideraciones de seguridad

Para mitigar los riesgos inherentes al uso de un runtime obsoleto y asegurar la cadena de suministro, se han implementado las siguientes prácticas de *hardening*:

*   **Uso de imágenes oficiales y digest pinning:** Se utiliza la imagen oficial de Debian (variante *slim*) anclada mediante su hash criptográfico (digest) en lugar de *tags* mutables como `latest` o `bullseye-slim`. Esto garantiza que la imagen base sea inmutable y reproducible, evitando ataques de suplantación de imágenes.
*   **Minimización de paquetes (Zero-footprint):** Se parte de la variante slim de Debian y se emplea una construcción por etapas. Las herramientas de descarga como `curl` y `xz-utils` se utilizan únicamente en la etapa de construcción y son descartadas en la etapa final. Esto asegura que la imagen de runtime no posea herramientas para descargar o ejecutar scripts maliciosos.

*   **Gestión de procesos y señales (PID 1):** Se integra `tini` como proceso de inicio ligero. Node.js no está diseñado para manejar correctamente señales del sistema (como SIGTERM) cuando corre como PID 1. tini actúa como un proxy que asegura que la aplicación se detenga de forma limpia y que no queden procesos `"zombie"` en el host.

*   **Ejecución con usuario no-root:** Por defecto, los contenedores se ejecutan como el usuario `root`. Para cumplir con el principio de menor privilegio, se crea y configura un usuario dedicado (`nodeuser`) sin permisos de superusuario, previniendo que una posible vulnerabilidad en la aplicación comprometa el host.
*   **Eliminación de cachés y artefactos temporales:** Durante la construcción de la imagen, se limpian las cachés del gestor de paquetes (`apt-get clean` y `rm -rf /var/lib/apt/lists/*`) en la misma capa (layer) donde se instalan las dependencias. Esto reduce significativamente el tamaño final de la imagen.
*   **Escaneo de vulnerabilidades y SBOM:** Se establecen directrices para el escaneo continuo de la imagen y la generación de una Lista de Materiales de Software (SBOM), permitiendo identificar y rastrear componentes vulnerables.

## 3. Estructura recomendada del proyecto

Para mantener la consistencia en los repositorios corporativos, se sugiere la siguiente estructura de directorios:

```text
proyecto-base-node14/
├── Dockerfile
├── .dockerignore
├── package.json
├── package-lock.json
├── src/
│   └── index.js
└── README.md
...
...
...
...
```

## 4. Dockerfile completo

A continuación, se presenta el Dockerfile optimizado utilizando un enfoque de Multi-stage build (construcción en múltiples etapas). Este método es fundamental para nuestra estrategia de seguridad, ya que nos permite separar el entorno de preparación (donde se descargan y extraen herramientas) del entorno de ejecución final. De este modo, garantizamos que la imagen de producción sea lo más pequeña posible y no contenga utilitarios que puedan ser explotados por un atacante.

Para obtener el digest SHA256 que garantiza la inmutabilidad debe usar 

```
docker pull debian:bullseye-slim
docker inspect --format='{{index .RepoDigests 0}}' debian:bullseye-slim
```

```dockerfile
# ETAPA 1: BUILDER (Descarga y Preparación)
# Usamos el digest que proporcionaste para Debian 11 Bullseye Slim
FROM debian@sha256:89400a8b54c93d61bb2f971f1ada1d907b344f2422afabf23699fdf1f162faa0 AS builder

ENV NODE_VERSION=14.21.3
ENV ARCH=x64

# Instalamos herramientas necesarias SOLO para la descarga y extracción
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl xz-utils

WORKDIR /tmp
# Descarga del binario oficial y extracción
RUN curl -fsSLO https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${ARCH}.tar.xz && \
    mkdir -p /tmp/node && \
    tar -xJf "node-v${NODE_VERSION}-linux-${ARCH}.tar.xz" -C /tmp/node --strip-components=1

# ---------------------------------------------------------------------

# ETAPA 2: RUNTIME (Imagen Final Dorada)
FROM debian@sha256:89400a8b54c93d61bb2f971f1ada1d907b344f2422afabf23699fdf1f162faa0 AS runtime

LABEL maintainer="Equipo de Arquitectura y Seguridad <arquitectura@empresa.com>"
LABEL version="1.0.1"
LABEL description="Imagen base corporativa optimizada para Node.js 14 (EOL) sobre Debian Slim"

ENV DEBIAN_FRONTEND=noninteractive
ENV WORKDIR=/usr/src/app

# 1. Instalamos tini (gestor de procesos para PID 1)
# 2. Creamos el usuario no-root (nodeuser)
# 3. Limpiamos cache de apt inmediatamente
RUN apt-get update && \
    apt-get install -y --no-install-recommends tini && \
    groupadd -g 10001 nodegroup && \
    useradd -u 10001 -g nodegroup -s /bin/false -m nodeuser && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p ${WORKDIR} && \

# COPIA ATÓMICA: Traemos Node.js desde la etapa builder
# Esto deja fuera a curl, xz-utils y archivos temporales
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
```

*Nota: El digest `sha256:123456...` en el `FROM` es un ejemplo. Debes obtener el digest real ejecutando `docker pull debian:bullseye-slim` y luego `docker inspect --format='{{index .RepoDigests 0}}' debian:bullseye-slim`.*

## 5. Archivo `.dockerignore`

El archivo `.dockerignore` es fundamental para evitar que archivos sensibles o innecesarios del contexto de construcción (build context) se copien a la imagen, reduciendo el tamaño y previniendo fugas de información.

```text
# Control de versiones
.git
.gitignore

# Dependencias locales
node_modules/
npm-debug.log
yarn-error.log

# Entornos y secretos
.env
.env.*
*.pem
*.key
*.cert

# Archivos de sistema operativo y editores
.DS_Store
Thumbs.db
.vscode/
.idea/

# Documentación y scripts locales
README.md
docker-compose.yml
```

## 6. Comandos de build

Para construir la imagen base de forma local y etiquetarla adecuadamente, utiliza el siguiente comando. Se recomienda usar BuildKit para optimizar el proceso.

```bash
# Habilitar BuildKit (opcional pero recomendado)
export DOCKER_BUILDKIT=1

# Construir la imagen
docker build -t registry.empresa.com/base/node14-debian:1.0.0 .
```

## 7. Comandos de prueba

Una vez construida la imagen, es imperativo validar que cumple con los requisitos de seguridad y funcionamiento.

**Validar la versión de Node.js:**
```bash
docker run --rm registry.empresa.com/base/node14-debian:1.0.0 node -v
# Salida esperada: v14.x.x
```
**Validar la ausencia de herramientas de red (Higiene de imagen):**

```
docker run --rm registry.empresa.com/base/node14-debian:1.0.1 which curl
# Salida esperada: (Vacío o error), confirmando que curl no existe en el runtime.
```

**Validar que corre como usuario no-root:**
```bash
docker run --rm registry.empresa.com/base/node14-debian:1.0.0 id
# Salida esperada: uid=10001(nodeuser) gid=10001(nodegroup) groups=10001(nodegroup)
```

**Validar el tamaño de la imagen:**
```bash
docker images registry.empresa.com/base/node14-debian:1.0.0
# Debería mostrar un tamaño reducido, típicamente < 150MB.
```

**Verificar las capas (layers) de la imagen:**
```bash
docker history registry.empresa.com/base/node14-debian:1.0.0
```

## 8. Escaneo de seguridad

La imagen debe ser sometida a análisis de vulnerabilidades y generación de SBOM antes de ser aprobada.

**Generación de SBOM con Syft:**
Syft extrae la lista de componentes de la imagen.

```bash
syft registry.empresa.com/base/node14-debian:1.0.0 -o spdx-json > sbom-node14.json
```

**Escaneo de vulnerabilidades con Trivy:**
Trivy analiza la imagen en busca de CVEs conocidos. Dada la naturaleza EOL de Node.js 14, se esperan múltiples hallazgos críticos.

```bash
trivy image registry.empresa.com/base/node14-debian:1.0.0
```

**Escaneo con Grype (usando el SBOM):**
```bash
grype sbom:sbom-node14.json
```

*Interpretación de resultados:* Los equipos de seguridad deben revisar el reporte de Trivy/Grype. Para esta imagen específica (Node 14), se debe documentar una excepción de seguridad (risk acceptance) formalizada, ya que las vulnerabilidades inherentes al runtime no podrán ser parcheadas.

## 9. Recomendaciones corporativas

Para integrar esta imagen en el ecosistema empresarial, se deben seguir estas directrices:

*   **Versionado Semántico (SemVer):** Utilizar etiquetas claras como `1.0.0`, `1.0.1`. Evitar el uso de la etiqueta `latest` en entornos de producción.
*   **Registry Privado:** Publicar la imagen únicamente en el *container registry* corporativo (ej. Harbor, Artifactory, AWS ECR) tras superar los controles de seguridad.
*   **Firma de Imágenes:** Implementar herramientas como Cosign para firmar criptográficamente la imagen. Los clústeres de Kubernetes deben configurarse para admitir únicamente imágenes firmadas.
*   **Tags Inmutables:** Configurar el registry para evitar la sobreescritura de *tags* existentes. Si hay un cambio, se debe generar una nueva versión.
*   **Validación en CI/CD:** El pipeline de integración continua debe bloquear la publicación de la imagen si se detectan vulnerabilidades críticas en paquetes del sistema operativo (excluyendo las excepciones documentadas de Node.js 14).
*   **Política de Deprecación:** Establecer una fecha límite estricta (hard deadline) a nivel organizacional para el retiro definitivo de esta imagen y la migración obligatoria a Node.js 18/20.

## 10. Errores comunes

*   **Dejar el usuario root por defecto:** Olvidar la instrucción `USER nodeuser` permite que el contenedor se ejecute con privilegios elevados, violando las políticas de seguridad.
*   **Instalar herramientas innecesarias:** Añadir paquetes como `vim`, `ping` o compiladores (`build-essential`) en la imagen final de runtime aumenta el tamaño y el riesgo.
*   **No limpiar la caché de apt:** Omitir `apt-get clean` y `rm -rf /var/lib/apt/lists/*` en el mismo comando `RUN` donde se instalan paquetes genera capas intermedias pesadas que no pueden ser eliminadas posteriormente.
*   **Ignorar el EOL de Node.js:** Tratar esta imagen como una solución a largo plazo. Es un parche temporal y riesgoso.

*   **Omitir el manejo de señales en el código:** Aunque la imagen base incluye `tini`, los desarrolladores deben asegurarse de que su código Node.js escuche el evento `process.on('SIGTERM')` para cerrar conexiones de base de datos o liberar memoria antes de que el contenedor se detenga.

## 11. Checklist final

Antes de promover esta imagen al registry corporativo, asegúrate de cumplir con los siguientes puntos:

- [ ] ¿El `Dockerfile` utiliza un *digest* específico para la imagen base de Debian?
- [ ] ¿Se ha creado y configurado un usuario no-root (`nodeuser`)?
- [ ] ¿Se han eliminado las cachés de los gestores de paquetes en la misma capa de instalación?
- [ ] ¿El archivo `.dockerignore` excluye directorios sensibles y de desarrollo?
- [ ] ¿Se ha generado y almacenado el SBOM correspondiente?
- [ ] ¿Se han ejecutado los escaneos de vulnerabilidades (Trivy/Grype)?
- [ ] ¿Se ha documentado formalmente la aceptación del riesgo por el uso de Node.js 14 EOL?
- [ ] ¿La imagen ha sido firmada criptográficamente antes de su publicación?
- [ ] ¿Se utiliza tini como ENTRYPOINT para la gestión correcta de señales?

- [ ] ¿Se ha verificado mediante docker history que las herramientas de construcción no persisten en la capa final?

