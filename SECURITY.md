# Política de Seguridad

## Advertencias Críticas de Versiones y Ciclo de Vida (EOL)

Es fundamental comprender el estado de soporte de cada versión de Node.js para tomar decisiones seguras:

### Node.js 14 y 16 (End-of-Life / EOL)
- **Estado:** Fin de vida oficial (Node 14 finalizó en abril 2023, Node 16 en septiembre 2023).
- **Riesgo:** **CRÍTICO**. Ya no reciben actualizaciones de seguridad ni correcciones de errores.
- **Uso:** Estrictamente para mantener *workloads legacy* que no pueden ser migrados a corto plazo. **No usar para proyectos nuevos.**

### Node.js 18 y 20 (Maintenance LTS)
- **Estado:** Mantenimiento a largo plazo (LTS).
- **Riesgo:** BAJO. Reciben parches de seguridad críticos, pero no nuevas funcionalidades.
- **Uso:** Adecuado para aplicaciones existentes en producción. Se recomienda planificar la migración a versiones Active LTS.

### Node.js 22 (Active LTS)
- **Estado:** LTS Activo.
- **Riesgo:** MÍNIMO. Es la versión recomendada corporativamente.
- **Uso:** **Obligatorio para todos los nuevos proyectos** y migraciones de sistemas *legacy*.

### Node.js 24 (Current)
- **Estado:** Versión actual (Current).
- **Riesgo:** MEDIO. Contiene las últimas características pero puede tener inestabilidades. Aún no es LTS.
- **Uso:** Exclusivamente para pruebas de concepto, evaluación de nuevas características o preparación para futuras migraciones. No recomendado para producción crítica.

## Prácticas de Seguridad Implementadas

### 1. Usuario no-root

Todas las imágenes se ejecutan bajo el usuario `nodeuser` (UID 10001) en lugar de `root`. Esto previene que una vulnerabilidad en la aplicación comprometa el host.

### 2. Gestión de Procesos

Se utiliza `tini` como *entrypoint* para asegurar que Node.js maneje correctamente las señales del sistema (como `SIGTERM`) y evitar procesos "zombie".

### 3. Minimización de Superficie de Ataque

Las imágenes `runtime` utilizan compilación multi-etapa (*multi-stage build*) para excluir herramientas de descarga (`curl`, `xz-utils`) del artefacto final. Esto reduce significativamente la superficie de ataque.

### 4. Validación de Integridad

Se valida el hash SHA256 de los binarios de Node.js descargados para asegurar que no han sido modificados.

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

