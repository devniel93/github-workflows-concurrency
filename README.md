# Proyecto de Análisis de Concurrencia en GitHub Actions

Este repositorio está diseñado para experimentar, observar y medir cómo GitHub Actions maneja la concurrencia cuando múltiples usuarios o equipos disparan workflows simultáneamente.

## 🎯 Objetivo del Proyecto

Simular un entorno real de despliegue donde:
1.  Múltiples equipos solicitan despliegues al mismo tiempo.
2.  Existen recursos compartidos (Ambientes: `dev`, `qa`, `prd`) y (APIM: `core`, `channel`, etc.).
3.  Se requiere controlar el acceso para evitar colisiones (**Queueing/Locking**) pero permitir **Paralelismo** cuando los recursos son distintos.

---

## ⚙️ Estrategia de Concurrencia (Actual)

La configuración actual utiliza **bloqueo estricto por API y Ambiente**. Esto significa que:
*   ✅ **Dos APIs diferentes** (`ApiA` y `ApiB`) pueden desplegar a `dev` **al mismo tiempo**. (Paralelismo)
*   ✅ **La misma API** puede desplegar a `dev` y `qa` **al mismo tiempo**. (Independencia de Ambiente)
*   ⛔ **La misma API** intentando desplegar varias veces a `dev` **será encolada**. (Serialización)

**Código en `deploy.yaml`:**
```javascript
const concurrencyGroup = `deploy-${apiName}-${environment}-${apimInstance}`;
// Ejemplo: deploy-Payment-Service-dev-apim-core
```

### Comportamiento de "Cola y Cancelación"
GitHub Actions optimiza la cola. Si una API lanza 5 despliegues seguidos muy rápido:
1.  El **#1** entra y corre.
2.  El **#2, #3, #4** entran a la cola, pero son **cancelados** automáticamente cuando llega el #5 ("Canceling since a higher priority waiting request... exists").
3.  El **#5** queda en espera (Pending) y corre cuando termina el #1.

*Esto asegura que siempre se despliegue la versión más reciente, descartando las intermedias obsoletas.*

---

## 🚀 Pruebas de Carga

Este repositorio incluye un script automatizado `simulate_load.sh` que prueba 3 escenarios clave:

### Prerrequisitos
- [GitHub CLI](https://cli.github.com/) instalado y autenticado (`gh auth login`).

### Ejecución
```bash
./simulate_load.sh
```

### Escenarios Probados

| Escenario | Descripción | Comportamiento Esperado |
|-----------|-------------|-------------------------|
| **1. Paralelismo de APIs** | 3 APIs distintas (`Payment`, `User`, `Notification`) solicitan despliegue a `dev` al mismo tiempo. | **Todos corren a la vez (In Progress).** No hay bloqueo porque son APIs distintas. |
| **2. Saturación por API** | La misma API (`Legacy-Monolith`) lanza 5 solicitudes seguidas a `dev`. | **1 En ejecución, 3 Cancelados, 1 Pendiente.** Demonstración de optimización de cola. |
| **3. Cross-Environment** | La API (`Legacy-Monolith`) lanza a `qa` mientras `dev` está saturado. | **Corre inmediatamente (In Progress).** El bloqueo de `dev` no afecta a `qa`. |

---

## 🏗 Estructura del Proyecto

- **.github/ISSUE_TEMPLATE/deploy-api.yml**: Formulario de Issue para solicitar despliegues.
- **.github/workflows/deploy.yaml**: Workflow principal.
    - **Job 1**: Extrae metadatos (API Name, Env, APIM) del cuerpo del issue.
    - **Job 2**: Define la `concurrency` dinámica y simula trabajo con `sleep 50`.
- **simulate_load.sh**: Script de bash que usa `gh` para generar los escenarios de prueba.

---

## 📊 Resumen de Resultados

| Acción | Resultado | ¿Por qué? |
|--------|-----------|-----------|
| API A en Dev + API B en Dev | ✅ Paralelo | `concurrency_group` diferente (nombre de API). |
| API A en Dev + API A en QA | ✅ Paralelo | `concurrency_group` diferente (nombre de ambiente). |
| API A en Dev (v1) + API A en Dev (v2) | ⏳ Encolado | `concurrency_group` idéntico. |
| API A en Dev (v1...v5 Ráfaga) | 🚫 Cancelación Intermedia | Optimización nativa de GitHub Actions (Freshness). |
