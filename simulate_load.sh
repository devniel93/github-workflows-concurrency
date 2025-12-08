#!/bin/bash

# ========================================================================================
# SCRIPT DE SIMULACIÓN DE CARGA PARA GITHUB ACTIONS
# ========================================================================================
# Este script utiliza 'gh' (GitHub CLI) para crear múltiples issues rápidamente.
# El objetivo es disparar varios workflows casi simultáneamente para observar la concurrencia.
#
# Requisitos:
# 1. GitHub CLI instalado (brew install gh)
# 2. Autenticado (gh auth login)
# ========================================================================================

REPO=$(gh repo view --json owner,name -q ".owner.login + \"/\" + .name")

echo "🎯 Objetivo: $REPO"
echo "🚀 Iniciando simulación de concurrencia..."

# ----------------------------------------------------------------------------------------
# ESCENARIO 1: ALTA COMPETENCIA (Mismo Recurso)
# Crearemos 5 issues que apuntan a 'dev' y 'apim-core'.
# Resultado esperado: 1 Ejecución, 4 en Cola (Pending) si concurrency está activo.
# ----------------------------------------------------------------------------------------

echo ""
echo "--- Escenario 1: Alta Competencia (5 requests a dev/apim-core) ---"
for i in {1..5}
do
   echo "📝 Creando Issue #$i..."
   
   # Construimos el cuerpo respetando el formato del Issue Template
   BODY="### Nombre de la API
API-Simulada-$i

### Ambiente Destino
dev

### Instancia APIM
apim-core

### Equipo Solicitante
payments-team

### Motivo del Despliegue
Prueba de carga automatizada batch 1"

   gh issue create --repo "$REPO" \
       --title "[AUTO] Deploy Request $i (Competencia)" \
       --body "$BODY" \
       --label "deployment" > /dev/null
done

echo "✅ Batch 1 enviado."

# ----------------------------------------------------------------------------------------
# ESCENARIO 2: RECURSOS PARALELOS
# Crearemos 2 issues para ambientes distintos (qa y prd).
# Resultado esperado: Deberían ejecutarse en paralelo sin bloquearse entre sí 
# (ni bloquear a los de dev, asumiendo concurrency por grupo).
# ----------------------------------------------------------------------------------------

echo ""
echo "--- Escenario 2: Recursos Paralelos (QA y PRD) ---"

BODY_QA="### Nombre de la API
API-QA-Service

### Ambiente Destino
qa

### Instancia APIM
apim-channel

### Equipo Solicitante
logistics-team

### Motivo del Despliegue
Prueba paralela"

gh issue create --repo "$REPO" \
    --title "[AUTO] Deploy Request QA (Paralelo)" \
    --body "$BODY_QA" \
    --label "deployment" > /dev/null

echo "📝 Issue QA Creado."

BODY_PRD="### Nombre de la API
API-PRD-Service

### Ambiente Destino
prd

### Instancia APIM
apim-core

### Equipo Solicitante
users-team

### Motivo del Despliegue
Prueba paralela"

gh issue create --repo "$REPO" \
    --title "[AUTO] Deploy Request PRD (Paralelo)" \
    --body "$BODY_PRD" \
    --label "deployment" > /dev/null

echo "📝 Issue PRD Creado."

echo ""
echo "🎉 Simulación completa. Revisa la pestaña 'Actions' en tu repositorio."
