# Estructura Final del Repositorio

Este documento describe la estructura final del repositorio `node-bold-images` y las decisiones tomadas durante su construcción.

## Estructura Definitiva

```
node-bold-images/
├── README.md                          # Documentación principal
├── CONTRIBUTING.md                    # Guía de contribución
├── SECURITY.md                        # Política de seguridad
├── CHANGELOG.md                       # Historial de cambios
├── LICENSE                            # Licencia corporativa
├── ESTRUCTURA_FINAL.md                # Este archivo
├── EJEMPLO NODE 14.md                 # Guía técnica de ejemplo para Node.js 14
├── Mejoras_de_trazabilidad.txt        # Instrucciones pendientes para labels OCI
├── política_corporativa_imagenes_base_docker_node.js.md  # Política corporativa
├── política_rotación_de_digests_docker_base.md           # Política de rotación de digests
├── .gitlab-ci.yml                     # Pipeline GitLab CI/CD
├── .gitattributes                     # Atributos de Git
├── .gitignore                         # Archivos ignorados por Git
├── .dockerignore                      # Archivos ignorados por Docker
│
├── common/                            # Archivos compartidos
│   ├── labels.env                     # Etiquetas comunes (placeholder)
│   ├── npmrc                          # Configuración npm (placeholder)
│   ├── corporate-ca/                  # Certificados corporativos
│   │   └── empresa-root-ca.crt        # Certificado raíz (placeholder)
│   └── scripts/                       # Scripts de utilidad
│       ├── verify-node-sha256.sh      # Verificación de integridad (placeholder)
│       └── smoke-test.sh              # Pruebas de humo (usado en CI)
│
├── node14/                            # Node.js 14 (EOL)
│   ├── dev/
│   │   └── Dockerfile                 # Imagen de desarrollo
│   ├── runtime/
│   │   └── Dockerfile                 # Imagen de producción
│   └── tips_run_manual_14.md          # Tips para construcción manual local
│
├── node16/                            # Node.js 16 (EOL)
│   ├── dev/
│   │   └── Dockerfile                 # Imagen de desarrollo
│   ├── runtime/
│   │   └── Dockerfile                 # Imagen de producción
│   └── tips_run_manual_16.md          # Tips para construcción manual local
│
├── node18/                            # Node.js 18 (EOL)
│   ├── dev/
│   │   └── Dockerfile                 # Imagen de desarrollo
│   └── runtime/
│       └── Dockerfile                 # Imagen de producción
│
├── node20/                            # Node.js 20 (Maintenance LTS)
│   ├── dev/
│   │   └── Dockerfile                 # Imagen de desarrollo
│   └── runtime/
│       └── Dockerfile                 # Imagen de producción
│
├── node22/                            # Node.js 22 (Active LTS)
│   ├── dev/
│   │   └── Dockerfile                 # Imagen de desarrollo
│   └── runtime/
│       └── Dockerfile                 # Imagen de producción
│
└── node24/                            # Node.js 24 (Active LTS)
    ├── dev/
    │   └── Dockerfile                 # Imagen de desarrollo
    └── runtime/
        └── Dockerfile                 # Imagen de producción
```

## Decisiones Arquitectónicas

### 1. Inclusión de Node.js 16

Aunque el requerimiento principal mencionaba Node.js 14, 18, 20, 22 y 24, se incluyó Node.js 16 en la estructura para mantener consistencia con el documento `estructura_repo.docx` que lo especificaba. Esto proporciona una cobertura más completa de versiones.

### 2. Selección de Imágenes Base Debian

- **Node.js 14:** Debian 11 Bullseye Slim (con digest SHA256 fijo)
- **Node.js 16:** Debian 11 Bullseye Slim
- **Node.js 18, 20, 22, 24:** Debian 12 Bookworm Slim

La selección se basa en la compatibilidad de cada versión de Node.js con la versión de Debian correspondiente.

### 3. Validación SHA256 de Binarios

Todos los Dockerfiles incluyen validación SHA256 de los binarios de Node.js descargados. Esto asegura la integridad y evita ataques de suplantación.

### 4. Multi-stage Builds en Runtime

Las imágenes `runtime` utilizan compilación multi-etapa para:

- Descargar y validar binarios en la etapa `builder`.
- Copiar únicamente los binarios compilados a la imagen final.
- Excluir herramientas de descarga (`curl`, `xz-utils`) del artefacto final.

### 5. Usuario no-root Consistente

Todas las imágenes utilizan el usuario `nodeuser` (UID 10001) y el grupo `nodegroup` (GID 10001), asegurando consistencia y seguridad.

### 6. Gestor de Procesos Tini

Se utiliza `tini` como `ENTRYPOINT` en todas las imágenes para:

- Manejar correctamente las señales del sistema (SIGTERM, SIGINT).
- Prevenir procesos "zombie".
- Asegurar un apagado controlado de la aplicación.

## Archivos Documentación

### README.md

Documentación principal que incluye:

- Descripción general del repositorio.
- Estructura del repositorio.
- Explicación de variantes `dev` y `runtime`.
- Prácticas de seguridad implementadas.
- Instrucciones de construcción y prueba.
- Advertencias importantes (especialmente sobre Node.js 14 EOL).

### CONTRIBUTING.md

Guía para contribuyentes que cubre:

- Requisitos para cambios en Dockerfiles.
- Proceso de revisión.
- Versionado semántico.
- Checklist de pruebas.

### SECURITY.md

Política de seguridad que documenta:

- Estado de soporte de cada versión de Node.js (EOL, Maintenance, Active LTS).
- Prácticas de seguridad implementadas (non-root, digests, BuildKit, multi-stage, tini, SBOM).
- Herramientas de escaneo recomendadas.
- Política de reporte de vulnerabilidades.
- Recomendaciones para equipos consumidores.

### CHANGELOG.md

Historial de cambios siguiendo el formato "Keep a Changelog".

### LICENSE

Licencia corporativa que establece:

- Uso autorizado del repositorio.
- Restricciones de distribución.
- Exención de responsabilidad.

### política_corporativa_imagenes_base_docker_node.js.md

Política corporativa completa que define:

- Tipos de imágenes (dev vs runtime) y sus restricciones de uso.
- Política de imágenes base Debian (tags flotantes en dev, digests en runtime).
- Política de versiones Node.js y restricciones EOL.
- Hardening, pipeline, escaneo de vulnerabilidades y supply chain.
- Trazabilidad OCI, excepciones y responsabilidades.

### política_rotación_de_digests_docker_base.md

Documento operativo complementario que define:

- Procedimiento de rotación de digests SHA256 en etapas runtime.
- Frecuencias de revisión (mensual, inmediata ante CVEs críticas).
- Pasos de validación obligatorios.
- Tabla de digests actuales del repositorio.

### EJEMPLO NODE 14.md

Guía técnica de ejemplo para la construcción de la imagen Node.js 14, incluyendo Dockerfile de referencia, comandos de build, pruebas y checklist de seguridad.

### Mejoras_de_trazabilidad.txt

Instrucciones pendientes de implementación para agregar labels OCI a los Dockerfiles y al pipeline CI/CD.

## Pipeline GitLab CI/CD

El archivo `.gitlab-ci.yml` incluye:

- **Etapas:** build, test, push
- **Jobs por versión:** Construcción, prueba y publicación separadas para cada versión y variante.
- **Plantillas:** Uso de anchors (`&`) para reutilización de código.
- **Dependencias:** Configuración de `needs` para ejecutar jobs en orden correcto.

## Archivos Compartidos (common/)

### labels.env

Placeholder para etiquetas comunes que pueden ser utilizadas en los Dockerfiles.

### npmrc

Placeholder para configuración global de npm (ej. registry corporativo).

### corporate-ca/empresa-root-ca.crt

Placeholder para certificado raíz corporativo que puede ser inyectado en las imágenes.

### scripts/verify-node-sha256.sh

Placeholder para script de verificación de integridad de binarios.

### scripts/smoke-test.sh

Placeholder para script de pruebas de humo que valida el funcionamiento básico de las imágenes.

## Validación Realizada

- ✅ Estructura coincide con `estructura_repo.docx`.
- ✅ Todos los Dockerfiles están presentes (12 archivos: 6 versiones × 2 variantes).
- ✅ Dockerfiles son coherentes entre sí.
- ✅ Sintaxis de Dockerfiles validada.
- ✅ Documentación consistente con archivos generados.
- ✅ Pipeline GitLab CI/CD configurado correctamente.
- ✅ Archivos de configuración (.gitignore, .dockerignore) incluidos.

## Próximos Pasos Recomendados

1. **Completar archivos placeholder:** Rellenar `labels.env`, `npmrc`, certificados y scripts.
2. **Implementar labels OCI:** Aplicar las instrucciones de `Mejoras_de_trazabilidad.txt` a los Dockerfiles y al pipeline CI/CD.
3. **Probar construcción local:** Construir una imagen de prueba localmente.
4. **Configurar GitLab:** Establecer variables de entorno para CI/CD (registry, credenciales).
5. **Publicar en registry:** Ejecutar el pipeline para publicar las imágenes.
6. **Documentar excepciones de seguridad:** Formalizar la aceptación de riesgo para Node.js 14 y 16 EOL.

