# Política de Seguridad

## Advertencias Críticas de Versiones y Ciclo de Vida (EOL)

Es fundamental comprender el estado de soporte de cada versión de Node.js para tomar decisiones seguras:

### ⚠️ ESTADO DE SOPORTE (Actualizado: 11 Mayo 2026)

| Versión | Estado Real | Nivel de Riesgo | Acción Requerida |
| :--- | :--- | :--- | :--- |
| **Node 14, 16, 18, 20** | **End-of-Life (EOL)** | 🚨 **CRÍTICO** | Migración inmediata. No reciben parches de seguridad. |
| **Node 22** | **Active LTS** | ✅ **MÍNIMO** | Versión estándar recomendada. |
| **Node 24** | **Active LTS** | ✅ **MÍNIMO** | Versión estándar recomendada (desde Oct 2025). |
| **Node 26** | **Current** | ⚠ **MEDIO** | Solo para evaluación (LTS previsto para Oct 2026). |

## Prácticas de Seguridad Implementadas

### 1. Ejecución Non-Root Obligatoria
Todas las imágenes runtime están configuradas para ejecutarse bajo el usuario `nodeuser` con UID/GID 10001. Este usuario carece de privilegios administrativos y tiene asignado `/usr/sbin/nologin` como shell, lo que impide accesos interactivos no autorizados y mitiga el impacto en caso de una ejecución de código arbitrario.

### 2. Validación de Integridad Mediante Digests
Para garantizar builds determinísticos y prevenir ataques de sustitución de imágenes, el uso de tags flotantes (ej. `:latest`) se limita a entornos de desarrollo. En producción, es obligatorio referenciar las imágenes base mediante su Digest SHA256 inmutable. Adicionalmente, se valida el hash de los binarios de Node.js durante la construcción de la imagen base para asegurar que no han sido alterados.

### 3. Gestión de Secretos con BuildKit
Queda estrictamente prohibido el uso de instrucciones `ARG` o `ENV` para manejar credenciales (como tokens de npm o llaves de API) en los Dockerfiles. En su lugar, se deben utilizar montajes de secretos de BuildKit (`--mount=type=secret`), lo que garantiza que los datos sensibles solo estén disponibles en tiempo de construcción y nunca persistan en las capas finales de la imagen.

### 4. Minimización de la Superficie de Ataque
Se emplea la técnica de compilación multi-etapa (multi-stage build) para segregar el entorno de construcción del de ejecución.

- **Imágenes dev:** Contienen compiladores (`gcc`, `make`) y herramientas de depuración necesarias únicamente para el build.
- **Imágenes runtime:** Se excluyen deliberadamente todas las herramientas de desarrollo, utilidades de descarga (`curl`, `wget`) y gestores de paquetes innecesarios, reduciendo drásticamente los vectores de ataque.

### 5. Control de Procesos y Señales
Se integra `tini` como proceso de inicio (init process). Esto asegura que Node.js no se ejecute como PID 1, permitiendo una recolección correcta de procesos "zombie" y garantizando que las señales del sistema (como `SIGTERM`) se propaguen adecuadamente para permitir cierres controlados de la aplicación.

### 6. Trazabilidad y SBOM (Software Bill of Materials)
Cada imagen generada debe incluir metadatos OCI estándar para identificar su origen, revisión de Git y fecha de creación. Como parte obligatoria del pipeline de CI/CD, se debe generar un SBOM utilizando herramientas como Syft, proporcionando un inventario completo de todos los componentes instalados para auditorías de seguridad y cumplimiento.


### 5. Higiene de Paquetes

Se eliminan las cachés de `apt` en la misma capa de instalación para reducir el tamaño y la retención de datos innecesarios.




## Escaneo de Vulnerabilidades

Se recomienda escanear regularmente las imágenes con herramientas como:

- **Trivy:** Para análisis de vulnerabilidades en imágenes Docker.
- **Syft:** Para generar un SBOM (Software Bill of Materials).
- **Grype:** Para análisis de vulnerabilidades basado en SBOM.

Ejemplo:

```bash
trivy image registry.empresa.com/base/node20-runtime:latest
```

## Reporte de Vulnerabilidades

Si descubres una vulnerabilidad en estas imágenes, por favor reporta a través del canal de seguridad corporativo. No publiques vulnerabilidades en repositorios públicos.

## Política de Actualizaciones

Las imágenes se actualizan regularmente para incluir:

1. Nuevas versiones menores de Node.js (parches de seguridad).
2. Actualizaciones de paquetes del sistema operativo.
3. Mejoras en las prácticas de seguridad.

Las actualizaciones se comunican a través de cambios de versión en los tags de las imágenes.

## Recomendaciones para Equipos Consumidores

1. **Utiliza versiones LTS:** Prefiere Node.js 18, 20 o 22 en lugar de 14.
2. **Escanea tus imágenes:** Realiza escaneos de seguridad en las imágenes finales de tu aplicación.
3. **Mantén actualizado:** Actualiza regularmente a las versiones más recientes de las imágenes base.
4. **Manejo de Señales:** Asegúrate de que tu aplicación Node.js procese correctamente `SIGTERM` para un cierre controlado.

