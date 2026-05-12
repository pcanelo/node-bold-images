# Guía de Contribución

Este documento describe los procedimientos y estándares para contribuir al repositorio de imágenes base Node.js.

## Cambios en Dockerfiles

Cualquier modificación a los Dockerfiles debe cumplir con los siguientes requisitos:

1. **Seguridad:** No se deben introducir vulnerabilidades conocidas. Verifica que los paquetes instalados sean seguros y necesarios.
2. **Tamaño:** Las imágenes deben ser lo más pequeñas posible. Utiliza multi-stage builds cuando sea necesario.
3. **Coherencia:** Los cambios deben aplicarse de forma consistente a todas las versiones de Node.js.
4. **Documentación:** Actualiza la documentación correspondiente si hay cambios significativos.

## Proceso de Revisión

1. Crea una rama con un nombre descriptivo (ej. `feature/add-security-patch`).
2. Realiza los cambios necesarios.
3. Prueba localmente que los Dockerfiles se construyen sin errores.
4. Envía un Merge Request con una descripción clara de los cambios.
5. Espera la aprobación del equipo de arquitectura.

## Versionado

Las imágenes utilizan versionado semántico (SemVer):

- **MAJOR:** Cambios incompatibles (ej. cambio de base Debian).
- **MINOR:** Nuevas características compatibles (ej. nuevo paquete en dev).
- **PATCH:** Correcciones de errores (ej. actualización de Node.js a versión de parche).

## Pruebas

Antes de enviar cambios, asegúrate de:

1. Validar la sintaxis del Dockerfile.
2. Construir la imagen localmente.
3. Verificar que Node.js y npm funcionan correctamente.
4. Comprobar que el usuario no-root está configurado.
5. Validar que las herramientas de compilación están presentes en `dev` y ausentes en `runtime`.

