# Política de Rotación de Digests Docker Base

## Objetivo

Este repositorio corporativo utiliza imágenes Docker fijadas mediante digest SHA256 para garantizar la integridad, reproducibilidad y control de la cadena de suministro de software. La fijación de digests mediante hash criptográfico inmutable es una práctica de seguridad esencial que previene la ejecución accidental de imágenes comprometidas o modificadas.

Los beneficios clave de esta política incluyen:

- **Reproducibilidad:** Builds idénticos en cualquier momento y lugar.
- **Trazabilidad:** Auditoría completa de qué versión exacta de la imagen base se utilizó.
- **Control de supply chain:** Prevención de cambios no autorizados en imágenes base.
- **Reducción de riesgos:** Eliminación de floating tags que pueden cambiar sin control.
- **Builds determinísticos:** Garantía de que el código compilado hoy será idéntico al compilado mañana.

### Ejemplo de Implementación

```dockerfile
# Recomendado: Digest fijado (seguro)
FROM debian@sha256:67b30a61dc87758f0caf819646104f29ecbda97d920aaf5edc834128ac8493d3

# NO recomendado: Floating tag (riesgoso)
FROM debian:bookworm-slim
```

---

## Riesgo de Seguridad: El Dilema de la Fijación

La fijación de digests mediante SHA256 introduce un dilema de seguridad bien conocido en la industria: **la seguridad de reproducibilidad versus la seguridad de actualización**.

### Implicaciones de Usar Digests Fijados

Cuando se fija una imagen mediante digest, se obtiene:

- **Garantía de reproducibilidad:** La imagen exacta será utilizada siempre.
- **Costo de seguridad:** Las imágenes NO reciben automáticamente nuevos parches de seguridad.
- **Responsabilidad manual:** Nuevas correcciones publicadas por Debian, OpenSSL, glibc u otros componentes críticos NO serán consumidas hasta que se actualice manualmente el digest.
- **Riesgo de vulnerabilidades latentes:** Vulnerabilidades críticas podrían permanecer presentes en el sistema si no existe un programa activo de monitoreo y rotación de digests.

### Ejemplo de Escenario de Riesgo

Supongamos que se fija el digest de `debian:bookworm-slim` el 1 de enero de 2026. El 15 de enero, Debian publica un parche crítico para una vulnerabilidad en `glibc` (CVE-2026-XXXXX). Sin embargo:

- Las imágenes Docker construidas con el digest fijado el 1 de enero **seguirán conteniendo la versión vulnerable**.
- Los builds posteriores al 15 de enero **también contendrán la vulnerabilidad** si no se actualiza el digest.
- La vulnerabilidad permanecerá presente hasta que alguien actualice manualmente el digest y reconstruya todas las imágenes.

**Por esta razón, la rotación periódica de digests es obligatoria y no negociable.**

---

## Frecuencia de Revisión de Digests

La revisión y actualización de digests debe realizarse según la siguiente matriz de frecuencias:

| Situación | Frecuencia | Justificación |
|-----------|-----------|---------------|
| Revisión preventiva normal | Mensual | Capturar parches de seguridad regulares y actualizaciones de dependencias. |
| Ambientes críticos | Quincenal | Mayor exposición a riesgos; menor ventana de vulnerabilidad. |
| CVE crítica en Debian/OpenSSL/glibc/kernel userland | **Inmediata** | Vulnerabilidades que afectan directamente a la seguridad del runtime. |
| Incidente de supply chain o compromiso detectado | **Inmediata** | Situación de emergencia; requiere acción urgente. |
| Actualización menor de Node.js | Mensual | Alineada con revisión preventiva normal. |
| Actualización mayor de Node.js | Inmediata | Cambio de versión base (ej: Bullseye → Bookworm). |

---

## Procedimiento de Actualización de Digests

El procedimiento para actualizar digests debe seguir los siguientes pasos en orden:

### Paso 1: Revisar Nueva Imagen Base Debian

Antes de actualizar cualquier digest, es obligatorio verificar que la nueva versión de la imagen base está disponible y es segura. Se deben consultar las siguientes fuentes oficiales:

- **Docker Hub Oficial Debian:** https://hub.docker.com/_/debian (verificar tags disponibles y fechas de publicación)
- **Debian Security Tracker:** https://security-tracker.debian.org/tracker/ (identificar CVEs pendientes)
- **GitHub Official Images:** https://github.com/docker-library/official-images (revisar cambios recientes)
- **Debian Release Notes:** https://www.debian.org/releases/ (entender cambios de versión)

### Paso 2: Obtener Nuevo Digest

Una vez identificada la nueva versión, se debe obtener el digest SHA256 de forma verificable. Existen dos métodos recomendados:

#### Método A: Usando Docker CLI (si Docker está disponible)

```bash
# Descargar la imagen
docker pull debian:bookworm-slim

# Obtener el digest
docker inspect --format='{{index .RepoDigests 0}}' debian:bookworm-slim

# Salida esperada:
# debian@sha256:67b30a61dc87758f0caf819646104f29ecbda97d920aaf5edc834128ac8493d3
```

#### Método B: Usando curl y Docker Registry API (sin Docker)

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

Reemplazar el digest antiguo por el nuevo en **todos los Dockerfiles** que utilicen esa imagen base. Debe realizarse de forma consistente.

#### Antes (Digest Antiguo)

```dockerfile
FROM debian@sha256:89400a8b54c93d61bb2f971f1ada1d907b344f2422afabf23699fdf1f162faa0
```

#### Después (Digest Nuevo)

```dockerfile
FROM debian@sha256:67b30a61dc87758f0caf819646104f29ecbda97d920aaf5edc834128ac8493d3
```

**Nota:** Utilizar herramientas de búsqueda y reemplazo global (ej: `sed`, IDE) para garantizar consistencia. No realizar cambios manuales en archivos individuales.

### Paso 4: Ejecutar Validaciones Completas

Después de actualizar los digests, es obligatorio ejecutar todas las siguientes validaciones antes de publicar:

| Validación | Comando/Herramienta | Criterio de Éxito |
|-----------|-------------------|-------------------|
| **Build completo** | `docker build -f node*/*/Dockerfile .` | Todos los builds exitosos sin errores. |
| **Smoke tests** | `./common/scripts/smoke-test.sh <image>` | Node.js y npm ejecutan correctamente. |
| **Escaneo de vulnerabilidades** | `trivy image <image>` o `grype <image>` | Sin CVEs críticas o altas no mitigadas. |
| **Funcionamiento Node.js/npm** | `docker run --rm <image> node -v && npm -v` | Versiones correctas, sin errores. |
| **Usuario non-root** | `docker run --rm <image> id` | UID 10001 (nodeuser), no root. |
| **Pipeline GitLab** | Ejecutar `.gitlab-ci.yml` | Todos los jobs exitosos. |
| **Integridad de archivos** | `sha256sum` en archivos críticos | Hashes coinciden con valores esperados. |

### Paso 5: Publicar Nuevas Imágenes

Una vez que todas las validaciones han pasado exitosamente, se pueden publicar las nuevas imágenes. El proceso incluye:

1. **Crear commit Git** con los cambios de digests:
   ```bash
   git add node*/*/Dockerfile
   git commit -m "chore: rotate digest SHA256 for debian:bookworm-slim

   - Previous: sha256:89400a8b54c93d61bb2f971f1ada1d907b344f2422afabf23699fdf1f162faa0
   - New: sha256:67b30a61dc87758f0caf819646104f29ecbda97d920aaf5edc834128ac8493d3
   - Reason: Security update for glibc CVE-2026-XXXXX
   - Date: 2026-05-11
   - Validated: Trivy scan, smoke tests, pipeline"
   ```

2. **Crear tag de versión** (ej: v1.0.2):
   ```bash
   git tag -a v1.0.2 -m "Digest rotation for Debian security updates"
   git push origin main --tags
   ```

3. **Publicar imágenes en registry**:
   ```bash
   docker push registry.empresa.com/base/node20-dev:latest
   docker push registry.empresa.com/base/node20-runtime:latest
   ```

4. **Registrar cambio en CHANGELOG.md**:
   ```markdown
   ## [1.0.2] - 2026-05-11
   
   ### Security
   - Rotated Debian digest to include glibc security patches
   - Previous digest: sha256:89400a8b54c93d61bb2f971f1ada1d907b344f2422afabf23699fdf1f162faa0
   - New digest: sha256:67b30a61dc87758f0caf819646104f29ecbda97d920aaf5edc834128ac8493d3
   - CVEs mitigated: CVE-2026-XXXXX
   ```

5. **Notificar a equipos consumidores**:
   - Enviar comunicado a través de canales corporativos.
   - Incluir fecha de rotación, motivo y CVEs mitigadas.
   - Recomendar actualización de imágenes base en aplicaciones.

---

## Recomendaciones Operativas

Las siguientes recomendaciones deben ser seguidas en todo momento para mantener la integridad de la cadena de suministro:

1. **Nunca utilizar imágenes floating sin digest:** Todos los `FROM` deben incluir digest SHA256. El uso de tags flotantes (ej: `debian:bookworm-slim` sin digest) está **prohibido** en este repositorio.

2. **Nunca actualizar digests directamente en producción:** Cualquier cambio de digest debe ser validado completamente en ambientes de desarrollo y staging antes de ser publicado a producción.

3. **Mantener trazabilidad mediante Git:** Todos los cambios de digest deben ser registrados en Git con mensajes de commit descriptivos. No realizar cambios manuales sin registro.

4. **Ejecutar escaneo de vulnerabilidades después de cada rotación:** Herramientas como Trivy, Grype o Snyk deben ejecutarse automáticamente después de cada actualización de digest.

5. **Documentar excepciones y decisiones:** Si se decide no actualizar un digest en una rotación regular, documentar explícitamente la razón en el repositorio.

6. **Monitorear CVEs de forma proactiva:** Suscribirse a alertas de seguridad de Debian y OpenSSL para identificar CVEs críticas que requieran rotación inmediata.

7. **Automatizar rotaciones cuando sea posible:** Considerar herramientas como Dependabot, Renovate o scripts personalizados para automatizar la detección y propuesta de actualizaciones de digests.

---

## Excepciones y Procedimiento de Escalación

En situaciones de emergencia operativa, mitigación crítica de seguridad o incidentes de supply chain, puede autorizarse una rotación extraordinaria de digests fuera del calendario normal.

### Criterios para Excepción

Una excepción requiere cumplir **al menos uno** de los siguientes criterios:

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

Se recomienda utilizar las siguientes herramientas para facilitar la gestión de digests:

| Herramienta | Propósito | Enlace |
|------------|----------|--------|
| **Trivy** | Escaneo de vulnerabilidades en imágenes Docker. | https://github.com/aquasecurity/trivy |
| **Grype** | Análisis de vulnerabilidades basado en SBOM. | https://github.com/anchore/grype |
| **Snyk** | Monitoreo continuo de vulnerabilidades. | https://snyk.io/ |
| **Dependabot** | Automatización de actualizaciones de dependencias. | https://dependabot.com/ |
| **Renovate** | Automatización de actualizaciones de imágenes base. | https://www.whitesourcesoftware.com/free-developer-tools/renovate/ |
| **Syft** | Generación de SBOM (Software Bill of Materials). | https://github.com/anchore/syft |

---

## Historial de Cambios de Esta Política

| Versión | Fecha | Cambios |
|---------|-------|---------|
| 1.0 | 2026-05-11 | Versión inicial de la política. |

---

## Preguntas Frecuentes (FAQ)

**P: ¿Por qué no simplemente usar floating tags?**  
R: Los floating tags (ej: `debian:bookworm-slim`) pueden cambiar sin control, comprometiendo la reproducibilidad y la seguridad. Los digests SHA256 garantizan que la imagen exacta será utilizada siempre.

**P: ¿Qué sucede si no actualizo digests regularmente?**  
R: Las imágenes acumularán vulnerabilidades no parcheadas. Esto es especialmente crítico para vulnerabilidades en glibc, OpenSSL u otros componentes de bajo nivel que afectan a todas las aplicaciones.

**P: ¿Puedo actualizar digests sin ejecutar validaciones?**  
R: No. Las validaciones (smoke tests, escaneo de vulnerabilidades) son obligatorias antes de publicar cualquier cambio de digest.

**P: ¿Cuál es la diferencia entre un digest y un tag?**  
R: Un **tag** es una etiqueta mutable (ej: `latest`). Un **digest** es un hash SHA256 inmutable que identifica exactamente una versión de imagen. Los digests son más seguros.

**P: ¿Qué hago si descubro una vulnerabilidad después de publicar un digest?**  
R: Escalar inmediatamente al equipo de seguridad. Si la vulnerabilidad es crítica, ejecutar una rotación extraordinaria fuera del calendario normal.

---

## Contacto y Soporte

Para preguntas, reportar problemas o solicitar excepciones a esta política, contactar a:

- **Equipo de Arquitectura:** arquitectura@empresa.com
- **Equipo de Seguridad:** security@empresa.com
- **Equipo de DevOps:** devops@empresa.com

---

**Documento versión 1.0 | Última actualización: 11 de Mayo de 2026 | Clasificación: Interno**
