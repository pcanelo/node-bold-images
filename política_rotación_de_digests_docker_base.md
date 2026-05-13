# Política de Rotación de Digests Docker Base

**Versión:** 2.0  
**Fecha de Publicación:** 13 de Mayo de 2026  
**Clasificación:** Interno  
**Responsable:** Equipo de Arquitectura y Seguridad  
**Documento padre:** [`política_corporativa_imagenes_base_docker_node.js.md`](política_corporativa_imagenes_base_docker_node.js.md)

---

## Objetivo

Este documento define el procedimiento operativo para la rotación de digests SHA256 en las imágenes base Debian utilizadas por las **etapas finales runtime** de los Dockerfiles de este repositorio.

La fijación de digests mediante hash criptográfico inmutable es una práctica de seguridad que previene la ejecución accidental de imágenes comprometidas o modificadas en producción. Los beneficios clave incluyen:

- **Reproducibilidad:** Builds idénticos en cualquier momento y lugar.
- **Trazabilidad:** Auditoría completa de qué versión exacta de la imagen base se utilizó.
- **Control de supply chain:** Prevención de cambios no autorizados en imágenes base.
- **Builds determinísticos:** Garantía de que el artefacto producido hoy será idéntico al producido mañana.

---

## Alcance

Esta política aplica **exclusivamente** a las instrucciones `FROM` de las etapas finales runtime de los Dockerfiles (`node*/runtime/Dockerfile`, etapa `AS runtime`).

### Lo que SÍ requiere digest fijado

```dockerfile
# ✓ Etapa final runtime: DEBE usar digest SHA256
FROM debian@sha256:67b30a61dc87758f0caf819646104f29ecbda97d920aaf5edc834128ac8493d3 AS runtime
```

### Lo que NO requiere digest fijado

```dockerfile
# Tags flotantes permitidos en estos contextos (ver política corporativa):
FROM debian:bookworm-slim              # Imágenes dev
FROM debian:bookworm-slim AS builder   # Etapa builder en runtime
```

> **Referencia:** La justificación de este enfoque diferenciado se encuentra en la sección "Política de Imágenes Base Debian" del documento [`política_corporativa_imagenes_base_docker_node.js.md`](política_corporativa_imagenes_base_docker_node.js.md).

---

## Riesgo de Seguridad: El Dilema de la Fijación

La fijación de digests introduce un dilema bien conocido: **seguridad de reproducibilidad versus seguridad de actualización**.

### Implicaciones de Usar Digests Fijados

- **Garantía de reproducibilidad:** La imagen exacta será utilizada siempre.
- **Costo de seguridad:** Las imágenes NO reciben automáticamente nuevos parches de seguridad.
- **Responsabilidad manual:** Nuevas correcciones publicadas por Debian, OpenSSL, glibc u otros componentes críticos NO serán consumidas hasta que se actualice manualmente el digest.
- **Riesgo de vulnerabilidades latentes:** Vulnerabilidades críticas podrían permanecer presentes si no existe un programa activo de rotación.

### Ejemplo de Escenario de Riesgo

Supongamos que se fija el digest de `debian:bookworm-slim` el 1 de enero de 2026. El 15 de enero, Debian publica un parche crítico para una vulnerabilidad en `glibc` (CVE-2026-XXXXX):

- Las imágenes runtime construidas con el digest del 1 de enero **seguirán conteniendo la versión vulnerable**.
- La vulnerabilidad permanecerá presente hasta que se actualice el digest y se reconstruyan las imágenes.

**Por esta razón, la rotación periódica de digests es obligatoria y no negociable.**

---

## Frecuencia de Revisión de Digests

| Situación | Frecuencia | Justificación |
|-----------|-----------|---------------|
| Revisión preventiva normal | Mensual | Capturar parches de seguridad regulares. |
| Ambientes críticos | Quincenal | Mayor exposición a riesgos; menor ventana de vulnerabilidad. |
| CVE crítica en Debian/OpenSSL/glibc/kernel userland | **Inmediata** | Vulnerabilidades que afectan directamente a la seguridad del runtime. |
| Incidente de supply chain o compromiso detectado | **Inmediata** | Situación de emergencia; requiere acción urgente. |
| Actualización menor de Node.js | Mensual | Alineada con revisión preventiva normal. |
| Actualización mayor de Node.js (cambio de Debian base) | Inmediata | Cambio de versión base (ej: Bullseye → Bookworm). |

---

## Procedimiento de Actualización de Digests

### Paso 1: Revisar Nueva Imagen Base Debian

Verificar que la nueva versión de la imagen base está disponible y es segura. Consultar:

- **Docker Hub Oficial Debian:** https://hub.docker.com/_/debian
- **Debian Security Tracker:** https://security-tracker.debian.org/tracker/
- **GitHub Official Images:** https://github.com/docker-library/official-images
- **Debian Release Notes:** https://www.debian.org/releases/

### Paso 2: Obtener Nuevo Digest

#### Método A: Usando Docker CLI

```bash
# Descargar la imagen
docker pull debian:bookworm-slim

# Obtener el digest
docker inspect --format='{{index .RepoDigests 0}}' debian:bookworm-slim

# Salida esperada:
# debian@sha256:67b30a61dc87758f0caf819646104f29ecbda97d920aaf5edc834128ac8493d3
```

#### Método B: Usando Docker Registry API (sin Docker local)

```bash
# Obtener token de autenticación
TOKEN=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/debian:pull" \
  | grep -o '"token":"[^"]*' | grep -o '[^"]*$')

# Obtener digest
curl -s -I \
  -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
  -H "Authorization: Bearer $TOKEN" \
  "https://registry-1.docker.io/v2/library/debian/manifests/bookworm-slim" \
  | grep -i docker-content-digest

# Salida esperada:
# docker-content-digest: sha256:67b30a61dc87758f0caf819646104f29ecbda97d920aaf5edc834128ac8493d3
```

### Paso 3: Actualizar Dockerfiles

Reemplazar el digest antiguo por el nuevo **únicamente en las etapas finales runtime** de todos los Dockerfiles afectados.

#### Archivos a modificar (ejemplo para Bookworm)

- `node18/runtime/Dockerfile` → etapa `AS runtime`
- `node20/runtime/Dockerfile` → etapa `AS runtime`
- `node22/runtime/Dockerfile` → etapa `AS runtime`
- `node24/runtime/Dockerfile` → etapa `AS runtime`

#### Antes

```dockerfile
FROM debian@sha256:89400a8b54c93d61bb2f971f1ada1d907b344f2422afabf23699fdf1f162faa0 AS runtime
```

#### Después

```dockerfile
FROM debian@sha256:67b30a61dc87758f0caf819646104f29ecbda97d920aaf5edc834128ac8493d3 AS runtime
```

**Nota:** Utilizar herramientas de búsqueda y reemplazo global (ej: `sed`, IDE) para garantizar consistencia. No realizar cambios manuales en archivos individuales.

```bash
# Ejemplo con sed para Bookworm (node18, 20, 22, 24)
OLD_DIGEST="sha256:89400a8b54c93d61bb2f971f1ada1d907b344f2422afabf23699fdf1f162faa0"
NEW_DIGEST="sha256:67b30a61dc87758f0caf819646104f29ecbda97d920aaf5edc834128ac8493d3"
sed -i "s|${OLD_DIGEST}|${NEW_DIGEST}|g" node{18,20,22,24}/runtime/Dockerfile
```

### Paso 4: Ejecutar Validaciones Completas

| Validación | Comando/Herramienta | Criterio de Éxito |
|-----------|-------------------|-------------------|
| **Build completo** | `docker build -f node*/runtime/Dockerfile .` | Todos los builds exitosos. |
| **Smoke tests** | `./common/scripts/smoke-test.sh` | Node.js y npm ejecutan correctamente. |
| **Escaneo de vulnerabilidades** | `trivy image <image>` o `grype <image>` | Sin CVEs críticas o altas no mitigadas. |
| **Funcionamiento Node.js/npm** | `docker run --rm <image> node -v && npm -v` | Versiones correctas. |
| **Usuario non-root** | `docker run --rm <image> id` | UID 10001 (nodeuser). |
| **Pipeline GitLab** | Ejecutar `.gitlab-ci.yml` | Todos los jobs exitosos. |

### Paso 5: Publicar Nuevas Imágenes

1. **Crear commit Git:**
   ```bash
   git add node*/runtime/Dockerfile
   git commit -m "chore: rotate digest SHA256 for debian:bookworm-slim (runtime)

   - Previous: sha256:89400a8b54c93d61bb2f971f1ada1d907b344f2422afabf23699fdf1f162faa0
   - New: sha256:67b30a61dc87758f0caf819646104f29ecbda97d920aaf5edc834128ac8493d3
   - Scope: runtime stages only (dev/builder use floating tags)
   - Reason: Security update for glibc CVE-2026-XXXXX
   - Date: 2026-05-13
   - Validated: Trivy scan, smoke tests, pipeline"
   ```

2. **Crear tag de versión:**
   ```bash
   git tag -a v1.0.2 -m "Digest rotation for Debian security updates (runtime)"
   git push origin main --tags
   ```

3. **Publicar imágenes en registry:**
   ```bash
   docker push registry.empresa.com/base/node22-runtime:latest
   docker push registry.empresa.com/base/node20-runtime:latest
   ```

4. **Registrar cambio en CHANGELOG.md:**
   ```markdown
   ## [1.0.2] - 2026-05-13

   ### Security
   - Rotated Debian digest in runtime stages to include security patches
   - Previous digest: sha256:89400a8b54c93d61bb2f971f1ada1d907b344f2422afabf23699fdf1f162faa0
   - New digest: sha256:67b30a61dc87758f0caf819646104f29ecbda97d920aaf5edc834128ac8493d3
   - CVEs mitigated: CVE-2026-XXXXX
   ```

5. **Notificar a equipos consumidores:**
   - Enviar comunicado a través de canales corporativos.
   - Incluir fecha de rotación, motivo y CVEs mitigadas.
   - Recomendar actualización de imágenes base en aplicaciones.

---

## Digests Actuales del Repositorio

### Debian 11 Bullseye Slim (Node 14, 16)

| Archivo | Digest Actual |
|---------|--------------|
| `node14/runtime/Dockerfile` (etapa runtime) | `sha256:89400a8b54c93d61bb2f971f1ada1d907b344f2422afabf23699fdf1f162faa0` |
| `node16/runtime/Dockerfile` (etapa runtime) | `sha256:89400a8b54c93d61bb2f971f1ada1d907b344f2422afabf23699fdf1f162faa0` |

### Debian 12 Bookworm Slim (Node 18, 20, 22, 24)

| Archivo | Digest Actual |
|---------|--------------|
| `node18/runtime/Dockerfile` (etapa runtime) | `sha256:67b30a61dc87758f0caf819646104f29ecbda97d920aaf5edc834128ac8493d3` |
| `node20/runtime/Dockerfile` (etapa runtime) | `sha256:67b30a61dc87758f0caf819646104f29ecbda97d920aaf5edc834128ac8493d3` |
| `node22/runtime/Dockerfile` (etapa runtime) | `sha256:67b30a61dc87758f0caf819646104f29ecbda97d920aaf5edc834128ac8493d3` |
| `node24/runtime/Dockerfile` (etapa runtime) | `sha256:67b30a61dc87758f0caf819646104f29ecbda97d920aaf5edc834128ac8493d3` |

> **Nota:** Las imágenes dev y las etapas builder usan tags flotantes (`debian:bullseye-slim`, `debian:bookworm-slim`) y no requieren rotación de digests.

---

## Recomendaciones Operativas

1. **Rotación consistente:** Al actualizar un digest de Bookworm, actualizar TODOS los Dockerfiles runtime que lo usen (node18, 20, 22, 24). Lo mismo para Bullseye (node14, 16).

2. **Nunca actualizar digests directamente en producción:** Cualquier cambio debe ser validado completamente en ambientes de desarrollo y staging antes de ser publicado.

3. **Mantener trazabilidad mediante Git:** Todos los cambios de digest deben ser registrados en Git con mensajes de commit descriptivos.

4. **Ejecutar escaneo de vulnerabilidades después de cada rotación:** Herramientas como Trivy, Grype o Snyk deben ejecutarse automáticamente.

5. **Documentar excepciones:** Si se decide no actualizar un digest en una rotación regular, documentar explícitamente la razón.

6. **Monitorear CVEs de forma proactiva:** Suscribirse a alertas de seguridad de Debian y OpenSSL.

7. **Automatizar rotaciones cuando sea posible:** Considerar herramientas como Dependabot o Renovate para automatizar la detección y propuesta de actualizaciones de digests en las etapas runtime.

---

## Excepciones y Procedimiento de Escalación

En situaciones de emergencia, puede autorizarse una rotación extraordinaria fuera del calendario normal.

### Criterios para Rotación Extraordinaria

Una rotación extraordinaria requiere cumplir **al menos uno** de los siguientes criterios:

- **CVE crítica (CVSS ≥ 9.0)** que afecte directamente a Debian, OpenSSL, glibc o kernel userland.
- **Incidente de supply chain confirmado** (ej: imagen base comprometida).
- **Fallo operativo crítico** que requiera actualización inmediata de imagen base.
- **Vulnerabilidad de día cero (0-day)** con explotación activa.

### Procedimiento de Escalación

1. **Notificar al equipo de seguridad** inmediatamente.
2. **Evaluar impacto** de la vulnerabilidad en el entorno corporativo.
3. **Obtener aprobación** del responsable de infraestructura y seguridad.
4. **Ejecutar rotación acelerada** con validaciones mínimas (smoke tests + escaneo Trivy).
5. **Comunicar a todos los equipos** consumidores de las imágenes.
6. **Documentar la excepción** en el repositorio con justificación completa.

---

## Responsabilidades y Roles

| Rol | Responsabilidad |
|-----|-----------------|
| **Equipo de Arquitectura** | Definir y mantener esta política; revisar y aprobar cambios de digests. |
| **Equipo de Seguridad** | Monitorear CVEs; alertar sobre vulnerabilidades críticas; validar rotaciones. |
| **Equipo de DevOps/Infraestructura** | Ejecutar rotaciones; mantener pipeline CI/CD; publicar imágenes. |
| **Equipos de Aplicación** | Actualizar imágenes base en sus aplicaciones; reportar problemas. |

---

## Auditoría y Cumplimiento

Todas las rotaciones de digests deben ser auditables. Se mantiene un registro de:

- **Fecha de rotación:** Cuándo se realizó el cambio.
- **Digest anterior:** Hash SHA256 que se reemplazó.
- **Digest nuevo:** Hash SHA256 nuevo.
- **Motivo:** Razón de la rotación (seguridad, actualización, etc.).
- **CVEs mitigadas:** Identificadores de CVEs corregidas.
- **Validaciones ejecutadas:** Qué pruebas se ejecutaron.
- **Responsable:** Quién realizó la rotación.
- **Aprobador:** Quién aprobó el cambio.

Este registro debe ser mantenido en:

1. **Git commits:** Mensajes descriptivos en cada commit.
2. **CHANGELOG.md:** Entrada en el historial de cambios.
3. **Tags de versión:** Anotaciones con detalles de la rotación.
4. **Sistema de tickets:** Ticket de seguimiento (ej: GitLab Issues, Jira).

---

## Herramientas Recomendadas

| Herramienta | Propósito | Enlace |
|------------|----------|--------|
| **Trivy** | Escaneo de vulnerabilidades en imágenes Docker | https://github.com/aquasecurity/trivy |
| **Grype** | Análisis de vulnerabilidades basado en SBOM | https://github.com/anchore/grype |
| **Snyk** | Monitoreo continuo de vulnerabilidades | https://snyk.io/ |
| **Dependabot** | Automatización de actualizaciones de dependencias | https://dependabot.com/ |
| **Renovate** | Automatización de rotación de digests | https://www.whitesourcesoftware.com/free-developer-tools/renovate/ |
| **Syft** | Generación de SBOM (Software Bill of Materials) | https://github.com/anchore/syft |

---

## Preguntas Frecuentes (FAQ)

**P: ¿Por qué solo se fijan digests en las etapas runtime y no en dev/builder?**  
R: Las imágenes dev no se despliegan en producción, por lo que recibir parches automáticos (tag flotante) es más beneficioso que la reproducibilidad estricta. Las etapas builder son descartables: solo se copian binarios de Node.js a la etapa final. La etapa runtime es la que se despliega en producción y requiere control total.

**P: ¿Qué sucede si no actualizo digests regularmente?**  
R: Las imágenes runtime acumularán vulnerabilidades no parcheadas. Esto es especialmente crítico para vulnerabilidades en glibc, OpenSSL u otros componentes de bajo nivel.

**P: ¿Puedo actualizar digests sin ejecutar validaciones?**  
R: No. Las validaciones (smoke tests, escaneo de vulnerabilidades) son obligatorias antes de publicar cualquier cambio de digest.

**P: ¿Cuál es la diferencia entre un digest y un tag?**  
R: Un **tag** es una etiqueta mutable (ej: `bookworm-slim` puede apuntar a diferentes imágenes en el tiempo). Un **digest** es un hash SHA256 inmutable que identifica exactamente una versión de imagen.

**P: ¿Qué hago si descubro una vulnerabilidad después de publicar un digest?**  
R: Escalar inmediatamente al equipo de seguridad. Si la vulnerabilidad es crítica, ejecutar una rotación extraordinaria fuera del calendario normal.

**P: ¿Debo actualizar también los digests comentados en los Dockerfiles dev?**  
R: Los comentarios con digests en los Dockerfiles dev son solo referencia informativa. No es obligatorio actualizarlos, pero se recomienda mantenerlos sincronizados para documentación.

---

## Historial de Cambios de Esta Política

| Versión | Fecha | Cambios |
|---------|-------|---------|
| 1.0 | 2026-05-11 | Versión inicial de la política. |
| 2.0 | 2026-05-13 | Alineación con política corporativa v3.0. Clarificación de alcance: digests obligatorios solo en etapas runtime. Adición de tabla de digests actuales. |

---

## Contacto y Soporte

Para preguntas, reportar problemas o solicitar excepciones a esta política, contactar a:

- **Equipo de Arquitectura:** arquitectura@empresa.com
- **Equipo de Seguridad:** security@empresa.com
- **Equipo de DevOps:** devops@empresa.com
- **Equipo de Plataforma:** platform@empresa.com

---

**Documento versión 2.0 | Última actualización: 13 de Mayo de 2026 | Clasificación: Interno**

**Aprobado por:** Equipo de Arquitectura y Seguridad  
**Próxima revisión:** 13 de Agosto de 2026
