# Proyecto de Análisis de Concurrencia en GitHub Actions

Este repositorio está diseñado para experimentar, observar y medir cómo GitHub Actions maneja la concurrencia cuando múltiples usuarios o equipos disparan workflows simultáneamente.

## 🎯 Objetivo del Proyecto

Simular un entorno real de despliegue donde:
1. Múltiples equipos solicitan despliegues al mismo tiempo.
2. Existen recursos compartidos (Ambientes: `dev`, `qa`, `prd`) y (APIM: `core`, `channel`, etc.).
3. Se requiere controlar el acceso para evitar colisiones (Queueing) o permitir paralelismo cuando los recursos son distintos.

## 🏗 Estructura

- **.github/issue_template/deploy-api.yml**: Formulario de Issue estructurado para solicitar despliegues.
- **.github/workflows/deploy.yaml**: Workflow principal.
    - **Job 1**: Analiza el cuerpo del Issue (parsing).
    - **Job 2**: Simula el despliegue con un `sleep 90`. Este job tiene la configuración de `concurrency`.
- **simulate_load.sh**: Script para generar tráfico masivo de issues automáticamente.

## 🚀 Cómo Ejecutar la Prueba

### Prerrequisitos
- Tener instalado [GitHub CLI](https://cli.github.com/).
- Estar autenticado (`gh auth login`).
- Tener permisos para crear issues en este repositorio.

### Paso 1: Generar Carga
Ejecuta el script de simulación desde tu terminal:

```bash
./simulate_load.sh
```

Esto creará:
- **5 Issues** compitiendo por `dev` / `apim-core`.
- **1 Issue** para `qa`.
- **1 Issue** para `prd`.

### Paso 2: Observar en GitHub Actions
Ve a la pestaña **Actions** de tu repositorio.

1. Verás múltiples workflows disparados (uno por cada Issue).
2. **Observación clave**:
    - El primer workflow de `dev` entrará en ejecución (círculo amarillo girando).
    - Los otros 4 workflows de `dev` se quedarán en estado **Pending** (amarillo estático) o "Queued", indicando que están esperando que se libere el grupo de concurrencia.
    - Los workflows de `qa` y `prd` deberían ejecutarse **en paralelo** al de `dev`, ya que sus grupos de concurrencia son distintos (`deploy-qa-apim-channel`, etc.).

## ⚙️ Configuración de Concurrencia

El comportamiento está definido en `.github/workflows/deploy.yaml`. Actualmente está configurado para la máxima granularidad:

```javascript
// deploy.yaml - Job parse-metadata
const concurrencyGroup = `deploy-${environment}-${apimInstance}`;
```

### Variantes de Prueba

Para probar otros comportamientos, edita el archivo `.github/workflows/deploy.yaml` y cambia la variable `concurrencyGroup` en el paso de script JS:

1. **Bloqueo estricto por Ambiente**:
   ```javascript
   const concurrencyGroup = `deploy-${environment}`;
   ```
   *Efecto*: Todos los despliegues a `dev` harán cola, sin importar si van a APIMs distintos.

2. **Bloqueo por APIM**:
    ```javascript
    const concurrencyGroup = `deploy-${apimInstance}`;
    ```
    *Efecto*: Bloquea si usan la misma instancia de APIM, aunque sean ambientes distintos (útil si la APIM es un recurso global).

## 📊 Resultados Esperados

| Escenario | Comportamiento del Workflow | Estado en UI |
|-----------|-----------------------------|--------------|
| Workflow A (dev) corriendo | Ejecutando `sleep 90` | In Progress |
| Workflow B (dev) llega | Detecta `deploy-dev-apim-core` ocupado | Pending / Queued |
| Workflow C (qa) llega | Detecta `deploy-qa-...` libre | In Progress (Paralelo) |

---
**Nota**: Este proyecto demuestra el uso de `concurrency` a nivel de Job con claves dinámicas, una técnica avanzada para orquestar despliegues complejos sin herramientas externas.
