# Política Corporativa de Imágenes Base Docker Node.js

**Versión:** 3.0  
**Fecha de Publicación:** 13 de Mayo de 2026  
**Clasificación:** Interno - Corporativo  
**Responsable:** Equipo de Arquitectura y Seguridad  

---

## Tabla de Contenidos

1. [Objetivo](#objetivo)
2. [Alcance](#alcance)
3. [Tipos de Imágenes](#tipos-de-imágenes)
4. [Política de Uso de Imágenes Dev](#política-de-uso-de-imágenes-dev)
5. [Política de Uso de Imágenes Runtime](#política-de-uso-de-imágenes-runtime)
6. [Política de Usuario Non-Root](#política-de-usuario-non-root)
7. [Política de Imágenes Base Debian](#política-de-imágenes-base-debian)
8. [Política de Versiones Node.js](#política-de-versiones-nodejs)
9. [Restricciones de Versiones EOL](#restricciones-de-versiones-eol)
10. [Hardening Avanzado de Contenedores](#hardening-avanzado-de-contenedores)
11. [Pipeline y CI/CD](#pipeline-y-cicd)
12. [Escaneo de Vulnerabilidades](#escaneo-de-vulnerabilidades)
13. [Supply Chain Security](#supply-chain-security)
14. [Trazabilidad OCI](#trazabilidad-oci)
15. [Excepciones](#excepciones)
16. [Responsabilidades](#responsabilidades)
17. [Auditoría y Cumplimiento](#auditoría-y-cumplimiento)
18. [Herramientas Recomendadas](#herramientas-recomendadas)
19. [Preguntas Frecuentes](#preguntas-frecuentes)
20. [Contacto y Soporte](#contacto-y-soporte)

---

## Objetivo

Esta política corporativa define las normas, restricciones y buenas prácticas para el uso de las imágenes base Docker Node.js mantenidas en el repositorio oficial. El objetivo principal es garantizar:

- **Consistencia técnica:** Imágenes estandarizadas en toda la organización.
- **Reducción de superficie de ataque:** Minimización de vulnerabilidades mediante hardening.
- **Trazabilidad:** Auditoría completa de qué imágenes se utilizan y cuándo.
- **Cumplimiento de estándares corporativos:** Adherencia a políticas de seguridad y gobernanza.
- **Reproducibilidad:** Builds determinísticos en imágenes de producción.
- **Control de supply chain:** Prevención de cambios no autorizados en imágenes base.
- **Uso seguro de contenedores:** Prácticas seguras en desarrollo, testing y producción.

---

## Alcance

Esta política es **obligatoria** para:

- Todos los equipos de desarrollo que utilicen Node.js.
- Equipos DevOps responsables de CI/CD y despliegue.
- Equipos de plataforma que mantengan infraestructura containerizada.
- Equipos de seguridad que validen hardening y cumplimiento.
- Integraciones CI/CD en cualquier plataforma.
- Workloads desplegados sobre:
  - Kubernetes (EKS, GKE, AKS, on-premises)
  - Docker (standalone, Swarm, Compose)
  - Amazon ECS / EKS
  - OpenShift
  - Entornos híbridos
  - Plataformas cloud (AWS, Azure, GCP)

**Excepciones:** Solo pueden ser autorizadas formalmente por el equipo de Arquitectura o Seguridad.

---

## Tipos de Imágenes

El repositorio mantiene dos categorías principales de imágenes Docker, cada una con propósito, contenido y restricciones específicas:

| Tipo | Propósito Principal | Ambiente de Uso | Tamaño Típico |
|------|-------------------|-----------------|---------------|
| **`dev`** | Desarrollo, compilación, testing y debugging | Desarrollo local, CI/CD build | ~1.5 GB |
| **`runtime`** | Ejecución productiva de aplicaciones | Producción, staging, testing | ~200-300 MB |

---

## Política de Uso de Imágenes Dev

### Uso Permitido

Las imágenes `dev` están diseñadas exclusivamente para:

- **Build de aplicaciones:** Compilación de código fuente, instalación de dependencias.
- **Instalación de dependencias:** `npm install`, `npm ci` con compilación nativa.
- **Debugging:** Ejecución interactiva, inspección de código, troubleshooting.
- **Compilación nativa:** Compilación de módulos nativos de Node.js.
- **Ejecución de herramientas de desarrollo:** Linters, formatters, test runners.
- **Testing local o CI/CD:** Ejecución de suite de tests, validaciones.

### Contenido de Imágenes Dev

Las imágenes `dev` incluyen deliberadamente herramientas que NO están presentes en `runtime`:

- `git` - Control de versiones
- `curl` - Descarga de archivos
- `g++` - Compilador C++
- `make` - Automatización de build
- `python3` - Dependencias de build
- `procps` - Utilidades de diagnóstico de procesos
- `iputils-ping` - Diagnóstico de red
- `netcat-openbsd` - Diagnóstico de conectividad
- Shell interactivo (`/bin/bash`)

### Ejemplo de Uso Dev

```dockerfile
# Dockerfile de aplicación usando imagen dev para build
FROM registry.empresa.com/base/node22-dev:latest AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
RUN npm run test

# Luego copiar a runtime para producción (ver sección runtime)
```

---

## Política de Uso de Imágenes Runtime

### Uso Permitido

Las imágenes `runtime` están diseñadas **exclusivamente** para:

- **Ejecución productiva:** Despliegue de aplicaciones en producción.
- **Despliegue de aplicaciones:** Contenedores finales listos para ejecutar.
- **Workloads runtime:** Microservicios, APIs, workers, procesos backend.
- **Ambientes críticos:** Staging, pre-producción, producción.

### Características de Imágenes Runtime

Las imágenes `runtime` están optimizadas para:

- **Tamaño reducido:** Menor huella de disco y transferencia de red.
- **Menor superficie de ataque:** Exclusión de herramientas innecesarias.
- **Ejecución non-root:** Usuario `nodeuser` (UID 10001), nunca `root`.
- **Reproducibilidad:** Builds determinísticos con digest SHA256 fijado y versiones pinned de Node.js.
- **Hardening básico corporativo:** Prácticas de seguridad aplicadas.

### Ejemplo de Uso Runtime

```dockerfile
# Dockerfile de aplicación usando multi-stage build
FROM registry.empresa.com/base/node22-dev:latest AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Etapa final: usar runtime
FROM registry.empresa.com/base/node22-runtime:latest

WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./

EXPOSE 3000
CMD ["node", "dist/index.js"]
```

---

## Restricción Crítica: Prohibición de Dev en Producción

**Las imágenes `dev` NO deben utilizarse en producción bajo ninguna circunstancia.**

### Razones Técnicas

1. **Mayor superficie de ataque:** Incluyen compiladores, herramientas de debug y utilidades que incrementan vulnerabilidades.
2. **Herramientas potencialmente peligrosas:** `curl`, `git` permiten descargas y modificaciones no autorizadas.
3. **Paquetes no necesarios en runtime:** Bloat innecesario que no contribuye a la funcionalidad.
4. **Mayor tamaño:** 5-10x más grandes que imágenes `runtime`, afectando velocidad de despliegue.
5. **Mayor exposición a CVEs:** Más dependencias = más vulnerabilidades potenciales.
6. **Presencia de toolchains de compilación:** g++, make permiten ejecución de código arbitrario.

### Consecuencias de Violación

- **Rechazo automático en CI/CD:** El pipeline debe rechazar imágenes `dev` en producción.
- **Alerta de seguridad:** Notificación inmediata al equipo de seguridad.
- **Investigación de incidente:** Análisis de cómo se desplegó imagen no autorizada.
- **Remediación forzada:** Rollback inmediato a imagen `runtime` válida.

### Validación Automática

```yaml
# Ejemplo de validación en GitLab CI/CD
validate_image_type:
  script:
    - |
      if [[ "$CI_COMMIT_TAG" == *"prod"* ]] && [[ "$IMAGE_NAME" == *"-dev"* ]]; then
        echo "ERROR: Cannot deploy dev image to production"
        exit 1
      fi
```

---

## Política de Usuario Non-Root

### Requisito Obligatorio

**Todas las imágenes runtime deben ejecutarse como usuario non-root.**

Esto es un requisito de seguridad corporativo no negociable.

### Especificación

| Atributo | Imagen Dev | Imagen Runtime |
|----------|-----------|----------------|
| **Usuario** | `nodeuser` | `nodeuser` |
| **UID** | `10001` | `10001` |
| **GID** | `10001` | `10001` |
| **Shell** | `/bin/bash` (interactivo) | `/bin/false` (sin acceso interactivo) |

### Lo Que NO Está Permitido

```dockerfile
# ❌ NO PERMITIDO: Ejecutar como root
USER root

# ❌ NO PERMITIDO: Sin especificar usuario
# (por defecto sería root)

# ❌ NO PERMITIDO: Usuario con shell interactivo en runtime
useradd -s /bin/bash nodeuser  # Solo permitido en dev
```

### Lo Que Está Permitido

```dockerfile
# ✓ PERMITIDO en runtime: Usuario non-root sin shell interactivo
RUN groupadd -g 10001 nodegroup && \
    useradd -u 10001 -g nodegroup -s /bin/false -m nodeuser
USER nodeuser

# ✓ PERMITIDO en dev: Usuario non-root con shell interactivo
RUN groupadd -g 10001 nodegroup && \
    useradd -u 10001 -g nodegroup -s /bin/bash -m nodeuser
USER nodeuser
```

### Validación en Pipeline

```bash
# Verificar que el contenedor se ejecuta con UID 10001
docker run --rm <image> id
# Salida esperada: uid=10001(nodeuser) gid=10001(nodegroup) groups=10001(nodegroup)
```

### Excepciones Documentadas

Cualquier excepción (ej: necesidad de ejecutar como root) requiere:

1. Justificación técnica documentada.
2. Aprobación explícita del equipo de seguridad.
3. Evaluación de riesgo formal.
4. Implementación de mitigaciones compensatorias.

---

## Política de Imágenes Base Debian

### Principio Rector: Seguridad por Contexto

Esta política establece un enfoque diferenciado para la referencia de imágenes base Debian, equilibrando la **seguridad de actualización** (parches automáticos) con la **seguridad de reproducibilidad** (builds determinísticos). El criterio rector es el contexto de uso:

| Contexto | Estrategia | Justificación |
|----------|-----------|---------------|
| **Imágenes `dev`** | Tag flotante permitido | Prioriza recepción automática de parches; no se despliega en producción. |
| **Etapa `builder` en runtime** | Tag flotante permitido | Es una etapa intermedia descartable; solo se copian binarios de Node.js. |
| **Etapa final `runtime`** | **Digest SHA256 obligatorio** | Prioriza reproducibilidad y trazabilidad en producción. |

> **Nota:** La política de rotación periódica de digests (documento complementario: `política_rotación_de_digests_docker_base.md`) aplica exclusivamente a los digests de las etapas finales runtime.

### Formato Permitido por Tipo de Imagen

#### Imágenes Dev y Etapas Builder

```dockerfile
# ✓ PERMITIDO: Tag flotante en imágenes dev
FROM debian:bullseye-slim
FROM debian:bookworm-slim

# ✓ PERMITIDO: Tag flotante en etapa builder de runtime
FROM debian:bookworm-slim AS builder
```

**Justificación:** Las imágenes dev no se despliegan en producción. Las etapas builder son descartables (solo se copian binarios compilados a la etapa final). En ambos casos, recibir parches automáticos de Debian es más beneficioso que la reproducibilidad estricta.

#### Etapa Final Runtime (Producción)

```dockerfile
# ✓ OBLIGATORIO: Digest SHA256 en etapa final runtime
FROM debian@sha256:67b30a61dc87758f0caf819646104f29ecbda97d920aaf5edc834128ac8493d3 AS runtime
```

**Justificación:** Las imágenes runtime se despliegan en producción. La fijación por digest garantiza:
- Builds idénticos en cualquier momento.
- Trazabilidad completa de qué imagen base exacta se utilizó.
- Control de supply chain: prevención de cambios no autorizados.
- Auditoría verificable.

### Formato NO Permitido (en ningún contexto)

```dockerfile
# ❌ NO PERMITIDO: Versión numérica sin tag slim
FROM debian:11
FROM debian:12

# ❌ NO PERMITIDO: Tag latest
FROM debian:latest

# ❌ NO PERMITIDO: Tag flotante en etapa final runtime
FROM debian:bookworm-slim AS runtime
```

### Selección de Versión Debian por Versión de Node.js

| Versión Node.js | Debian Base | Justificación |
|----------------|-------------|---------------|
| Node 14, 16 | Debian 11 Bullseye Slim | Compatibilidad con versiones legacy |
| Node 18, 20, 22, 24 | Debian 12 Bookworm Slim | Versión estable actual |

### Rotación de Digests

Los digests SHA256 de las etapas runtime **deben rotarse periódicamente** para incorporar parches de seguridad de Debian. El procedimiento detallado se encuentra en el documento complementario: [`política_rotación_de_digests_docker_base.md`](política_rotación_de_digests_docker_base.md).

Resumen de frecuencias:
- **Revisión preventiva:** Mensual.
- **CVE crítica (CVSS ≥ 9.0):** Inmediata.
- **Incidente de supply chain:** Inmediata.

---

## Política de Versiones Node.js

### Clasificación de Versiones (Actualizado Mayo 2026)

| Estado | Descripción | Ejemplo | Recomendación |
|--------|------------|---------|---------------|
| **Active LTS** | Versión estable con soporte activo y parches | Node 22, 24 | ✓ **Recomendado** |
| **Maintenance LTS** | Versión en fase final de soporte | Node 20 | ⚠ Planificar migración |
| **EOL** | Fin de vida, sin parches de seguridad | Node 14, 16, 18 | ✗ **Prohibido para nuevos proyectos** |

### Matriz de Decisión

| Versión | Estado | Nuevos Proyectos | Producción | Notas |
|---------|--------|-----------------|-----------|-------|
| Node 14 | EOL | ❌ No | ⚠ Solo legacy con excepción | EOL Abril 2023 |
| Node 16 | EOL | ❌ No | ⚠ Solo legacy con excepción | EOL Septiembre 2023 |
| Node 18 | EOL | ❌ No | ⚠ Solo transición | EOL Abril 2025 |
| Node 20 | Maintenance | ❌ No | ✓ Sí | EOL Abril 2026 |
| Node 22 | **Active LTS** | ✓ Sí | ✓ **Sí** | **Estándar corporativo** |
| Node 24 | **Active LTS** | ✓ Sí | ✓ **Sí** | **Estándar corporativo** |

---

## Restricciones de Versiones EOL

### Prohibiciones Explícitas

Las versiones EOL (End-of-Life) tienen restricciones severas:

- **NO deben utilizarse para nuevos proyectos:** Cualquier proyecto nuevo debe usar Node 22 o 24 (Active LTS).
- **NO deben desplegarse sin aceptación explícita de riesgo:** Requiere firma de documento de aceptación.
- **Deben tener plan de migración documentado:** Roadmap explícito hacia versión LTS activa.
- **Deben monitorearse con mayor rigurosidad:** Escaneos de vulnerabilidades más frecuentes.

### Proceso de Autorización para EOL

Para utilizar Node 14, 16 o 18 en producción:

1. **Justificación técnica:** Explicar por qué no se puede migrar.
2. **Evaluación de riesgo:** Documento formal de riesgos identificados.
3. **Plan de migración:** Roadmap con fechas específicas.
4. **Aprobación formal:** Firma de responsable de arquitectura y seguridad.
5. **Monitoreo intensivo:** Escaneos semanales de vulnerabilidades.

---

## Hardening Avanzado de Contenedores

### Gestión de Secretos en el Build

- **Prohibición de Secretos en Capas:** Queda estrictamente prohibido pasar tokens de npm, llaves SSH o credenciales mediante instrucciones `ARG` o `ENV`.
- **Uso de Docker Secrets:** Para la instalación de dependencias privadas, se debe utilizar el montaje de secretos de BuildKit:
  ```dockerfile
  RUN --mount=type=secret,id=npmrc,target=/root/.npmrc npm ci
  ```

### Reducción de Capas y Ruido

- **Uso de `.dockerignore`:** Todo proyecto debe incluir un archivo `.dockerignore` que excluya explícitamente:
  - Directorios de control de versiones (`.git`).
  - Archivos de entorno (`.env`).
  - Documentación local y logs.
  - El directorio `node_modules` local.

### Privilegios del Sistema (Capabilities)

- En la medida de lo posible, los contenedores deben ejecutarse sin capacidades de kernel de Linux. En orquestadores como Kubernetes, se debe configurar el `securityContext` para realizar un `drop: ["ALL"]`, permitiendo únicamente las necesarias para la operación del proceso Node.js.

### Gestor de Procesos (Tini)

- Todas las imágenes utilizan `tini` como `ENTRYPOINT` para:
  - Manejar correctamente las señales del sistema (SIGTERM, SIGINT).
  - Prevenir procesos "zombie".
  - Asegurar un apagado controlado de la aplicación.

---

## Pipeline y CI/CD

### Requisitos Obligatorios

Toda imagen generada en el pipeline debe:

1. **Pasar smoke tests:** Validar que Node.js/npm funcionan.
2. **Validar ejecución non-root:** Verificar UID 10001.
3. **Validar funcionamiento Node.js/npm:** Ejecutar comandos básicos.
4. **Validar restricciones runtime:** Verificar ausencia de herramientas dev.
5. **Generar artifacts reproducibles:** Builds determinísticos para runtime.

### Configuración de Pipeline

```yaml
# .gitlab-ci.yml - Ejemplo de validaciones
stages:
  - build
  - test
  - push

build:node22:runtime:
  stage: build
  script:
    - docker build -t $IMAGE:$CI_COMMIT_SHORT_SHA -f node22/runtime/Dockerfile .
    - docker save $IMAGE:$CI_COMMIT_SHORT_SHA > node22-runtime.tar
  artifacts:
    paths:
      - node22-runtime.tar
    expire_in: 1 hour

test:node22:runtime:
  stage: test
  script:
    - docker load < node22-runtime.tar
    - docker run --rm $IMAGE:$CI_COMMIT_SHORT_SHA node -v
    - docker run --rm $IMAGE:$CI_COMMIT_SHORT_SHA npm -v
    - |
      UID=$(docker run --rm $IMAGE:$CI_COMMIT_SHORT_SHA id -u)
      if [ "$UID" != "10001" ]; then
        echo "ERROR: Container not running as UID 10001"
        exit 1
      fi
```

---

## Escaneo de Vulnerabilidades

### Requisito Obligatorio

Las imágenes deben ser sometidas a escaneo de vulnerabilidades:

- **Después de cada build:** Validación automática en pipeline.
- **Revisión periódica:** Escaneo mensual de imágenes en producción.
- **Actualización de dependencias base:** Cuando se detecten CVEs.
- **Monitoreo de CVEs críticas:** Alertas inmediatas para vulnerabilidades críticas.

### Herramientas Recomendadas

| Herramienta | Propósito | Comando |
|------------|----------|---------|
| **Trivy** | Escaneo rápido de vulnerabilidades | `trivy image <image>` |
| **Grype** | Análisis basado en SBOM | `grype <image>` |
| **Snyk** | Monitoreo continuo | `snyk container test <image>` |
| **Syft** | Generación de SBOM | `syft <image>` |

### Criterios de Aceptación

- ❌ **Rechazar:** CVEs críticas (CVSS ≥ 9.0) sin mitigación.
- ⚠ **Evaluar:** CVEs altas (CVSS 7.0-8.9) con plan de remediación.
- ✓ **Aceptar:** CVEs medias y bajas documentadas.

---

## Supply Chain Security

### Prohibiciones Explícitas

No está permitido:

- **Descargar dependencias desde fuentes no autorizadas:** Solo registries corporativos.
- **Modificar imágenes runtime manualmente:** Cambios solo a través de Dockerfile.
- **Instalar paquetes arbitrarios en producción:** Toda instalación debe estar en Dockerfile.
- **Usar imágenes externas sin validación corporativa:** Solo imágenes del repositorio oficial.

### Validación de Integridad de Binarios Node.js

Todos los Dockerfiles validan la integridad de los binarios de Node.js descargados mediante verificación SHA256 contra el archivo oficial `SHASUMS256.txt` de nodejs.org:

```dockerfile
RUN curl -fsSLO https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt && \
    curl -fsSLO https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${ARCH}.tar.xz && \
    grep " node-v${NODE_VERSION}-linux-${ARCH}.tar.xz\$" SHASUMS256.txt | sha256sum -c -
```

### Trazabilidad de Cambios

Todos los cambios deben ser trazables:

- ✓ Commits en Git con mensajes descriptivos.
- ✓ Merge Requests con revisión de código.
- ✓ Tags de versión anotados.
- ✓ CHANGELOG.md actualizado.
- ✓ Tickets de seguimiento (GitLab Issues, Jira).

---

## Trazabilidad OCI

### Metadata Obligatoria

Todas las imágenes deben incluir metadata OCI estándar:

```dockerfile
LABEL org.opencontainers.image.source="https://gitlab.empresa.com/platform/node-bold-images"
LABEL org.opencontainers.image.revision="$CI_COMMIT_SHA"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.created="$CI_JOB_TIMESTAMP"
LABEL org.opencontainers.image.licenses="Proprietary"
LABEL org.opencontainers.image.vendor="Empresa Corp"
LABEL org.opencontainers.image.title="Node.js 22 Runtime Base Image"
LABEL org.opencontainers.image.description="Corporate base image for Node.js 22 runtime"
```

### Verificación de Metadata

```bash
docker inspect <image> | grep -A 50 "Labels"
```

---

## Excepciones

### Criterios para Excepción

Cualquier excepción a esta política requiere cumplir **al menos uno** de los siguientes criterios:

- **Justificación técnica documentada:** Explicación clara de por qué la política no aplica.
- **Evaluación de riesgo formal:** Documento de riesgos identificados y mitigaciones.
- **Aprobación explícita:** Firma de responsable de arquitectura o seguridad.
- **Período limitado:** Excepciones temporales con fecha de expiración.

### Proceso de Solicitud

1. **Documentar la excepción:** Crear ticket con justificación.
2. **Evaluar riesgos:** Análisis de impacto de seguridad.
3. **Proponer mitigaciones:** Controles compensatorios.
4. **Obtener aprobación:** Firma de autoridades competentes.
5. **Registrar en CHANGELOG:** Documentar la excepción.
6. **Revisar periódicamente:** Evaluar si la excepción sigue siendo necesaria.

### Ejemplo de Excepción

```markdown
## Excepción: Uso de Node 16 en Aplicación Legacy

**Solicitante:** Equipo de Pagos  
**Fecha:** 2026-05-11  
**Justificación:** Aplicación legacy que requiere módulos nativos incompatibles con Node 18+  
**Riesgo:** Vulnerabilidades no parcheadas en Node 16 EOL  
**Mitigación:** Escaneo semanal de vulnerabilidades, plan de migración a Node 22 para Q3 2026  
**Aprobación:** Arquitectura (Juan Pérez), Seguridad (María García)  
**Expiración:** 2026-09-30
```

---

## Responsabilidades

| Rol | Responsabilidad |
|-----|-----------------|
| **Equipo de Plataforma** | Mantención de imágenes, actualización de versiones Node.js, publicación en registry, rotación de digests. |
| **Equipo de Seguridad** | Validación de hardening, escaneo de vulnerabilidades, aprobación de excepciones. |
| **Equipos de Desarrollo** | Uso correcto de imágenes, reporte de problemas, adopción de nuevas versiones. |
| **Equipos DevOps** | Integración CI/CD, validación de pipeline, despliegue de imágenes. |
| **Equipo de Arquitectura** | Definición de política, revisión de excepciones, lineamientos técnicos. |

---

## Auditoría y Cumplimiento

### Registro Obligatorio

Todos los cambios deben ser auditables:

| Elemento | Dónde Registrar | Responsable |
|----------|-----------------|-------------|
| Cambios de versión Node.js | Git commits + CHANGELOG.md | Plataforma |
| Rotación de digests | Git commits + CHANGELOG.md | Plataforma |
| Nuevas versiones | Tags de versión + CHANGELOG.md | Plataforma |
| Excepciones | Tickets + CHANGELOG.md | Arquitectura |
| Vulnerabilidades | Tickets de seguridad | Seguridad |
| Validaciones | Pipeline logs | CI/CD |

### Auditoría de Cumplimiento

Se realizarán auditorías trimestrales para verificar:

- ✓ No hay imágenes `dev` desplegadas en producción.
- ✓ Todas las imágenes se ejecutan como non-root (UID 10001).
- ✓ No hay versiones EOL sin plan de migración.
- ✓ Escaneos de vulnerabilidades se ejecutan regularmente.
- ✓ Digests de imágenes runtime se rotan según la política de rotación.
- ✓ Imágenes base Debian están actualizadas.

---

## Herramientas Recomendadas

| Herramienta | Propósito | Enlace |
|------------|----------|--------|
| **Trivy** | Escaneo de vulnerabilidades en imágenes | https://github.com/aquasecurity/trivy |
| **Grype** | Análisis de vulnerabilidades basado en SBOM | https://github.com/anchore/grype |
| **Syft** | Generación de SBOM (Software Bill of Materials) | https://github.com/anchore/syft |
| **Snyk** | Monitoreo continuo de vulnerabilidades | https://snyk.io/ |
| **Dependabot** | Automatización de actualizaciones de dependencias | https://dependabot.com/ |
| **Renovate** | Automatización de rotación de digests | https://www.whitesourcesoftware.com/free-developer-tools/renovate/ |
| **Docker Scout** | Análisis de vulnerabilidades integrado en Docker | https://docs.docker.com/scout/ |

---

## Preguntas Frecuentes

### P: ¿Por qué se usan tags flotantes en dev pero digests en runtime?

**R:** Es un equilibrio deliberado entre dos necesidades de seguridad:
- **Dev/Builder:** No se despliegan en producción. Recibir parches automáticos de Debian reduce la ventana de vulnerabilidades durante el desarrollo sin riesgo operativo.
- **Runtime:** Se despliegan en producción. La fijación por digest garantiza reproducibilidad, trazabilidad y control de supply chain. Los parches se incorporan mediante rotación controlada de digests (ver política de rotación).

### P: ¿Qué sucede si Debian publica un parche de seguridad?

**R:** Depende del tipo de imagen:
- **Dev:** La próxima reconstrucción incorporará el parche automáticamente (tag flotante).
- **Runtime:** Se debe ejecutar una rotación de digest según la política de rotación (mensual o inmediata si es CVE crítica).

### P: ¿Cómo garantizo reproducibilidad en runtime?

**R:** La reproducibilidad se logra a través de:
- Digest SHA256 fijado en la etapa final runtime.
- Versiones pinned de Node.js en los Dockerfiles.
- Versiones pinned de dependencias npm (package-lock.json).
- Pipeline CI/CD que registra qué versión de imagen base se utilizó.
- Metadata OCI que documenta la versión y fecha de construcción.

### P: ¿Puedo usar Node 14 en un nuevo proyecto?

**R:** No. Node 14 está en EOL desde abril 2023 y no recibe parches de seguridad. Todos los nuevos proyectos deben usar Node 22 o 24 (Active LTS).

### P: ¿Qué hago si descubro una vulnerabilidad crítica?

**R:** Escalar inmediatamente al equipo de seguridad. Si es crítica (CVSS ≥ 9.0), ejecutar rotación inmediata de digests y reconstruir todas las imágenes afectadas.

### P: ¿Puedo ejecutar una imagen `dev` en producción si la modifico?

**R:** No. Las imágenes `dev` están diseñadas para desarrollo y no deben ser modificadas para uso en producción. Siempre usar imágenes `runtime` en producción.

### P: ¿Qué pasa si mi aplicación necesita ejecutarse como root?

**R:** Esto requiere excepción formal. Contactar al equipo de seguridad con justificación técnica. Generalmente, hay formas de lograr el objetivo sin ejecutar como root.

### P: ¿Con qué frecuencia se rotan los digests de las imágenes runtime?

**R:** Mensualmente de forma preventiva, o inmediatamente ante CVEs críticas. Ver documento complementario: `política_rotación_de_digests_docker_base.md`.

### P: ¿Cómo verifico que mi imagen cumple con esta política?

**R:** Ejecutar los siguientes comandos:
```bash
# Verificar usuario non-root
docker run --rm <image> id

# Verificar Node.js/npm
docker run --rm <image> node -v && npm -v

# Escanear vulnerabilidades
trivy image <image>
```

---

## Documentos Complementarios

| Documento | Propósito |
|-----------|----------|
| [`política_rotación_de_digests_docker_base.md`](política_rotación_de_digests_docker_base.md) | Procedimiento detallado de rotación de digests SHA256 para imágenes runtime. |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Guía de contribución al repositorio. |
| [`SECURITY.md`](SECURITY.md) | Política de reporte de vulnerabilidades. |
| [`CHANGELOG.md`](CHANGELOG.md) | Historial de cambios del repositorio. |

---

## Consideraciones Finales

Estas imágenes constituyen la **base corporativa oficial** para todos los workloads Node.js en la organización. Su uso incorrecto puede:

- Aumentar la superficie de ataque.
- Introducir vulnerabilidades no parcheadas.
- Romper trazabilidad y auditoría.
- Afectar cumplimiento normativo.
- Comprometer la cadena de suministro de software.

**Por esta razón, todas las modificaciones, excepciones y desviaciones deben seguir procesos formales de revisión y validación.**

---

## Contacto y Soporte

Para preguntas, reportar problemas o solicitar excepciones a esta política:

| Equipo | Contacto | Propósito |
|--------|----------|----------|
| **Arquitectura** | arquitectura@empresa.com | Lineamientos, excepciones, decisiones técnicas |
| **Seguridad** | security@empresa.com | Validación de hardening, CVEs, aprobación de excepciones |
| **DevOps** | devops@empresa.com | Pipeline, despliegue, integración CI/CD |
| **Plataforma** | platform@empresa.com | Mantenimiento de imágenes, actualizaciones, rotación de digests |

---

**Documento versión 3.0 | Última actualización: 13 de Mayo de 2026 | Clasificación: Interno - Corporativo**

**Aprobado por:** Equipo de Arquitectura y Seguridad  
**Próxima revisión:** 13 de Agosto de 2026
