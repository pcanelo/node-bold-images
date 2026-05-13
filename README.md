# Repositorio Corporativo de Imágenes Base Node.js

Este repositorio contiene las imágenes base Docker corporativas para aplicaciones Node.js. El objetivo es estandarizar y asegurar los entornos de desarrollo y producción para todas las aplicaciones Node.js de la empresa.

## Estructura del Repositorio

El repositorio está organizado por versión de Node.js. Cada versión contiene dos variantes de imágenes: `dev` (desarrollo) y `runtime` (producción).

```text
node-bold-images/
├── README.md
├── .gitlab-ci.yml
├── common/
│   ├── labels.env
│   ├── npmrc
│   ├── corporate-ca/
│   │   └── empresa-root-ca.crt
│   └── scripts/
│       ├── verify-node-sha256.sh
│       └── smoke-test.sh
├── node14/
│   ├── dev/
│   │   └── Dockerfile
│   └── runtime/
│       └── Dockerfile
├── node16/
│   ├── dev/
│   │   └── Dockerfile
│   └── runtime/
│       └── Dockerfile
├── node18/
│   ├── dev/
│   │   └── Dockerfile
│   └── runtime/
│       └── Dockerfile
├── node20/
│   ├── dev/
│   │   └── Dockerfile
│   └── runtime/
│       └── Dockerfile
├── node22/
│   ├── dev/
│   │   └── Dockerfile
│   └── runtime/
│       └── Dockerfile
└── node24/
    ├── dev/
    │   └── Dockerfile
    └── runtime/
        └── Dockerfile
```

*Nota: La versión Node.js 16 se ha incluido en la estructura para mantener la consistencia con el diseño original (`estructura_repo.docx`), aunque los requerimientos principales se centran en las versiones 14, 18, 20, 22 y 24.*

## Variantes de Imágenes

### Imagen de Desarrollo (`dev`)

Diseñada para la construcción (*build*) y depuración (*debug*).

*   **Propósito:** Desarrollo local, compilación de dependencias nativas, *debugging* interactivo y ejecución de pipelines CI/CD (`npm install`, `npm test`).
*   **Características:** Incluye herramientas de compilación (`make`, `g++`, `python3`), utilidades de red y control de versiones (`git`). El acceso por consola (`/bin/bash`) está habilitado.
*   **Uso:** Debe ser utilizada exclusivamente en entornos de desarrollo y fases de construcción.

### Imagen de Producción (`runtime`)

Diseñada bajo el principio de mínimo privilegio para entornos críticos.

*   **Propósito:** Ejecución segura en clústeres de producción (ej. Kubernetes).
*   **Características:** Altamente optimizada y reducida. No incluye herramientas de compilación ni utilidades innecesarias. El acceso por consola está deshabilitado (`/bin/false`).
*   **Uso:** Obligatoria para despliegues en producción. La aplicación debe inyectarse mediante la instrucción `COPY` durante la construcción de la imagen final del servicio.

## Prácticas de Seguridad (Hardening)

Todas las imágenes implementan las siguientes medidas de seguridad corporativas:

1.  **Usuario no-root:** Las aplicaciones se ejecutan bajo el usuario `nodeuser` (UID 10001), previniendo la escalada de privilegios.
2.  **Gestión de procesos:** Se utiliza `tini` como *entrypoint* para asegurar que Node.js maneje correctamente las señales del sistema (como `SIGTERM`) y evitar procesos "zombie".
3.  **Minimización de superficie de ataque:** Las imágenes `runtime` utilizan compilación multi-etapa (*multi-stage build*) para excluir herramientas de descarga (`curl`, `xz-utils`) del artefacto final.
4.  **Higiene de paquetes:** Se eliminan las cachés de `apt` en la misma capa de instalación para reducir el tamaño y la retención de datos innecesarios.

## Construcción y Uso

### Construcción Local

Para construir una imagen localmente, navega al directorio correspondiente y ejecuta:

```bash
# Ejemplo para Node.js 20 Runtime
cd node20/runtime
docker build -t registry.empresa.com/base/node20-runtime:latest .
```

### Prueba de Imágenes

Puedes verificar el correcto funcionamiento de las imágenes con los siguientes comandos:

```bash
# Verificar versión de Node.js
docker run --rm registry.empresa.com/base/node20-runtime:latest node -v

# Verificar usuario de ejecución
docker run --rm registry.empresa.com/base/node20-runtime:latest id
# Salida esperada: uid=10001(nodeuser) ...
```

## Uso en GitLab CI/CD

El repositorio incluye un archivo `.gitlab-ci.yml` configurado para construir, probar y publicar automáticamente las imágenes en el *Container Registry* de GitLab.

*   **Variables requeridas:** Asegúrate de que las variables de entorno de GitLab CI/CD (`CI_REGISTRY_USER`, `CI_REGISTRY_PASSWORD`, `CI_REGISTRY`) estén configuradas correctamente en el proyecto.
*   **Pipelines por versión:** El pipeline está estructurado para procesar cada versión y variante de forma independiente, facilitando la identificación de errores.

## Advertencias Importantes

*   **Node.js 14, 16 y 18 EOL (CRÍTICO):** Las versiones 14, 16 y 18 han alcanzado su Fin de Vida (EOL). Su uso representa un riesgo de seguridad crítico ya que no reciben parches. Deben utilizarse **únicamente** para soportar aplicaciones *legacy* existentes que no puedan ser migradas de inmediato. **Prohibido su uso en proyectos nuevos.**
*   **Node.js 20 (Maintenance LTS):** Versión en mantenimiento (EOL Abril 2026). Segura para producción pero se recomienda planificar migración a Node 22 o 24.
*   **Node.js 22 y 24 (Active LTS):** Versiones recomendadas corporativamente para todos los nuevos proyectos y migraciones.
*   **Inmutabilidad:** Las imágenes `runtime` están diseñadas para ser inmutables. No intentes modificar el contenedor en tiempo de ejecución. Cualquier cambio debe realizarse actualizando el código fuente y generando una nueva imagen.
*   **Manejo de Señales:** Aunque las imágenes incluyen `tini`, es responsabilidad del equipo de desarrollo asegurar que la aplicación Node.js procese correctamente las señales de apagado (`SIGTERM`) para un cierre controlado.
