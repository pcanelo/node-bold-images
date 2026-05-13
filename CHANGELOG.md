# Changelog

Todas las modificaciones notables en este proyecto serán documentadas en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/), y este proyecto se adhiere a [Versionado Semántico](https://semver.org/lang/es/).

## [1.0.1] - 2026-05-11

### Modificado

- Bump de versión en imágenes Node.js 14 (dev y runtime) a 1.0.1 para reflejar ajustes de configuración.

## [1.0.0] - 2026-05-11

### Agregado

- Imágenes base corporativas para Node.js 14, 16, 18, 20, 22 y 24.
- Variantes `dev` y `runtime` para cada versión.
- Pipeline GitLab CI/CD para construcción y prueba automática.
- Documentación completa en Markdown.
- Prácticas de seguridad corporativas (usuario no-root, tini, multi-stage builds).
- Validación SHA256 de binarios de Node.js.
- Soporte para arquitectura x64.
- Políticas corporativas: política de imágenes base y política de rotación de digests.

### Notas de Seguridad

- Node.js 14 y 16 han alcanzado su EOL. Se recomienda migrar a versiones LTS activas (Node 22 o 24).
- Node.js 18 alcanzó EOL en Abril 2025.
- Todas las imágenes incluyen hardening de seguridad.

