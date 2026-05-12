# Changelog

Todas las modificaciones notables en este proyecto serán documentadas en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/), y este proyecto se adhiere a [Versionado Semántico](https://semver.org/lang/es/).

## [1.0.0] - 2024-05-11

### Agregado

- Imágenes base corporativas para Node.js 14, 16, 18, 20, 22 y 24.
- Variantes `dev` y `runtime` para cada versión.
- Pipeline GitLab CI/CD para construcción y prueba automática.
- Documentación completa en Markdown.
- Prácticas de seguridad corporativas (usuario no-root, tini, multi-stage builds).
- Validación SHA256 de binarios de Node.js.
- Soporte para arquitectura x64.

### Notas de Seguridad

- Node.js 14 ha alcanzado su EOL. Se recomienda migrar a versiones LTS activas.
- Todas las imágenes incluyen hardening de seguridad.

