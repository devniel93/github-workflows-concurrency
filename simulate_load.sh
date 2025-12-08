#!/bin/bash

# ========================================================================================
# SCRIPT DE SIMULACIÓN DE CARGA PARA GITHUB ACTIONS (V2)
# ========================================================================================
# Este script prueba dos comportamientos clave ahora que la concurrencia incluye 'api_name':
# 
# 1. PARALELISMO TOTAL: Múltiples APIs distintas desplegando al mismo tiempo.
# 2. ENCOLAMIENTO/CANCELACIÓN: La MISMA API solicitando múltiples despliegues seguidos.
# ========================================================================================

REPO=$(gh repo view --json owner,name -q ".owner.login + \"/\" + .name")

echo "🎯 Objetivo: $REPO"
echo "🚀 Iniciando simulación de concurrencia V2..."

# ----------------------------------------------------------------------------------------
# ESCENARIO 1: PARALELISMO (Diferentes APIs)
# Aunque van al mismo ambiente (dev) y misma APIM (apim-core), al tener nombres distintos
# y estar la variable 'api_name' en el grupo de concurrencia, NO deben bloquearse.
# Resultado esperado: 3 Ejecuciones simultáneas en paralelo.
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

wait # Esperar a que los comandos en background terminen de enviarse
echo "✅ Batch Paralelo enviado."
sleep 2 # Pequeña pausa para separar visualmente en la UI

# ----------------------------------------------------------------------------------------
# ESCENARIO 2: BLOQUEO Y CANCELACIÓN (Misma API repetida)
# Generamos 5 peticiones seguidas para la MISMA API.
# Al ser el mismo identificador de concurrencia, GitHub aplicará la lógica de cola.
# Resultado esperado: 
# - 1ra: In Progress (Corre)
# - 2da, 3ra, 4ta: Cancelled (Se cancelan por obsolescencia)
# - 5ta: Pending (Espera a que termine la 1ra)
# ----------------------------------------------------------------------------------------

echo ""
echo "--- Escenario 2: Stress Test (5 requests de 'Legacy-Monolith' -> dev/apim-core) ---"
echo "ℹ️  Esperamos: 1 Ejecutando, 3 Cancelados, 1 Pendiente."

TARGET_API="Legacy-Monolith-V1"

for i in {1..5}
do
   echo "📝 Solicitando despliegue #$i para: $TARGET_API..."
   
   BODY="### Nombre de la API
$TARGET_API

### Ambiente Destino
dev

### Instancia APIM
apim-core

### Equipo Solicitante
legacy-team

### Motivo del Despliegue
Prueba de Stress y Cancelación #$i"

   gh issue create --repo "$REPO" \
       --title "[AUTO] Deploy $TARGET_API #$i (Stress)" \
       --body "$BODY" \
       --label "deployment" > /dev/null
done

echo "✅ Batch Stress enviado."

echo ""
echo "🎉 Simulación V2 completa. Revisa 'Actions' para contrastar los comportamientos."
