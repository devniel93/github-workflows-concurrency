#!/bin/bash

# ========================================================================================
# SCRIPT DE SIMULACIÓN DE CARGA PARA GITHUB ACTIONS (V3)
# ========================================================================================
# Este script prueba tres comportamientos clave:
# 
# 1. PARALELISMO TOTAL: Múltiples APIs distintas desplegando al mismo tiempo.
# 2. ENCOLAMIENTO/CANCELACIÓN: La MISMA API solicitando múltiples despliegues al MISMO env.
# 3. INDEPENDENCIA DE AMBIENTE: La MISMA API desplegando a un ambiente DIFERENTE.
# ========================================================================================

REPO=$(gh repo view --json owner,name -q ".owner.login + \"/\" + .name")

echo "🎯 Objetivo: $REPO"
echo "🚀 Iniciando simulación de concurrencia V3..."

# ----------------------------------------------------------------------------------------
# ESCENARIO 1: PARALELISMO (Diferentes APIs)
# ----------------------------------------------------------------------------------------
echo ""
echo "--- Escenario 1: Paralelismo (3 APIs diferentes -> dev/apim-core) ---"
echo "ℹ️  Esperamos que estas 3 corran A LA VEZ (In Progress)."

APIS=("Payment-Service" "User-Service" "Notification-Service")

for api in "${APIS[@]}"
do
   echo "📝 Solicitando despliegue para: $api..."
   
   BODY="### Nombre de la API
$api

### Ambiente Destino
dev

### Instancia APIM
apim-core

### Equipo Solicitante
checkout-team

### Motivo del Despliegue
Prueba de Paralelismo"

   gh issue create --repo "$REPO" \
       --title "[AUTO] Deploy $api (Paralelo)" \
       --body "$BODY" \
       --label "deployment" > /dev/null &
done

wait
echo "✅ Batch Paralelo enviado."
sleep 2

# ----------------------------------------------------------------------------------------
# ESCENARIO 2 + 3: Stress en DEV y Paralelo en QA (Misma API)
# Generamos tráfico pesado para 'Legacy-Monolith-V1' en DEV.
# Inmediatamente lanzamos 'Legacy-Monolith-V1' en QA.
# ----------------------------------------------------------------------------------------

echo ""
echo "--- Escenario 2 y 3: Stress en DEV vs QA (Misma API: Legacy-Monolith-V1) ---"
echo "ℹ️  Esperamos: Cola/Cancelación en DEV, pero ejecución LIBRE en QA."

TARGET_API="Legacy-Monolith-V1"

# Parte A: Inundación en DEV
for i in {1..5}
do
   echo "📝 [DEV] Solicitando despliegue #$i para: $TARGET_API..."
   
   BODY="### Nombre de la API
$TARGET_API

### Ambiente Destino
dev

### Instancia APIM
apim-core

### Equipo Solicitante
legacy-team

### Motivo del Despliegue
Prueba de Stress DEV #$i"

   gh issue create --repo "$REPO" \
       --title "[AUTO] Deploy $TARGET_API #$i (Stress DEV)" \
       --body "$BODY" \
       --label "deployment" > /dev/null
done

# Parte B: Solicitud Unitaria en QA
echo "📝 [QA]  Solicitando despliegue para: $TARGET_API en QA..."
   
BODY_QA="### Nombre de la API
$TARGET_API

### Ambiente Destino
qa

### Instancia APIM
apim-core

### Equipo Solicitante
legacy-team

### Motivo del Despliegue
Prueba Cross-Env QA"

gh issue create --repo "$REPO" \
    --title "[AUTO] Deploy $TARGET_API (QA - Paralelo)" \
    --body "$BODY_QA" \
    --label "deployment" > /dev/null

echo "✅ Simulaciones enviadas."

echo ""
echo "🎉 Simulación V3 completa. Verifica que el Job de QA esté corriendo mientras los de DEV se pelean."
