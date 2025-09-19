#!/bin/bash
# ************************************************************************************************
# * - DESCRIPCION: Shell para validación & generación de REPORTE de SALUD para Cluster OPENSHIFT *
# * - EJECUCION:   ./health-check.sh <api_server_url> <token>                                    *
# * - AUTOR:       Guerra Arnaiz, Cesar Ricardo (Modificado para seguridad y compatibilidad)     *
# * - FECHA:       18/09/2025                                                                    *
# * - VERSION:     2.0                                                                           *
# ************************************************************************************************

# --- Input Validation ---
if [ "$#" -ne 2 ]; then
    echo "ERROR: Invalid arguments."
    echo "Usage: $0 <api_server_url> <token>"
    echo "Example: $0 https://api.mycluster.com:6443 your-sha256-token"
    exit 1
fi

clear

# --- Variable Setup ---
API_SERVER="$1"
TOKEN="$2"
vCURRENT_DATE=$(date +%Y%m%d%H%M%S) # Corrected 'date' command
vTRANSACTION="$vCURRENT_DATE - [INFO]":
REPORT_LOG_NAME="cluster-validator-report.log"
NAMESPACE_NAME="dummy-test-cluster-$vCURRENT_DATE"

# --- Report Initialization ---
echo "${vTRANSACTION}> 0. Eliminando REPORTE anterior..."
rm -f ${REPORT_LOG_NAME} # Use -f to avoid errors if file doesn't exist
exec &> >(tee -a "${REPORT_LOG_NAME}")

echo ""
echo "${vTRANSACTION}> ******************** [PROCESO DE VALIDACIÓN: 'CLUSTER: OPENSHIFT'] ********************"
echo "${vTRANSACTION}> EJECUTANDO SCRIPT..."

# --- Step 1: Authentication ---
echo ""
echo "${vTRANSACTION}> 1. Autenticando en OPENSHIFT de forma segura..."
oc login --token=${TOKEN} --server=${API_SERVER}

if [ $? -ne 0 ]; then
    echo "FATAL: OpenShift login failed. Please check your token and API server URL."
    exit 1
fi
echo "${vTRANSACTION}> Autenticación exitosa."

# --- Step 2: Cluster Version Information ---
echo ""
echo "${vTRANSACTION}> 2. Validando información del CLÚSTER y VERSIONES..."
echo "--> [oc version]" && oc version
echo "--> [oc cluster-info]" && oc cluster-info
echo "--> [oc get clusterversion]" && oc get clusterversion
echo "--> [oc adm upgrade]" && oc adm upgrade

# --- Step 3: Node Validation ---
echo ""
echo "${vTRANSACTION}> 3. Validando NODOS (MASTER/WORKER)..."
echo "--> [oc get nodes -o wide]" && oc get nodes -o wide

# --- Step 4: User and Group Validation ---
echo ""
echo "${vTRANSACTION}> 4. Validando USUARIOS & GRUPOS..."
echo "--> [oc get users]" && oc get users
echo "--> [oc get groups]" && oc get groups

# --- Step 5: Storage Validation ---
echo ""
echo "${vTRANSACTION}> 5. Validando PERSISTENT-VOLUME, PERSISTENT-VOLUME-CLAIN & STORAGE-CLASSES..."
echo "--> [oc get pv --all-namespaces]" && oc get pv --all-namespaces
echo "--> [oc get pvc --all-namespaces]" && oc get pvc --all-namespaces
echo "--> [oc get storageclass --all-namespaces]" && oc get storageclass --all-namespaces

# --- Step 6: Pod Storage Usage ---
echo ""
echo "${vTRANSACTION}> 6. Validando PERSISTENT-VOLUME (STORAGE) utilizados por PODs..."
kubectl get pods --all-namespaces --no-headers -o custom-columns=NODE:.spec.nodeName,NAMESPACE:.metadata.namespace,POD:.metadata.name,PVC:.spec.volumes[*].persistentVolumeClaim.claimName | \
while IFS=' ' read -r vNODE vNAMESPACE vPOD vPVC ; do
    if [ "$vPVC" != "<none>" ]; then
        vPV=$(oc get pvc "$vPVC" -o=jsonpath='{.spec.volumeName}' -n "$vNAMESPACE" 2>/dev/null)
        if [ -n "$vPV" ]; then
            vPV_DETAILS=$(oc get pv "$vPV" -o jsonpath='{.spec}' 2>/dev/null)
            if [ -n "$vPV_DETAILS" ]; then
                vCAPACIDAD=$(echo "$vPV_DETAILS" | jq -r '.capacity.storage // "-"')
                echo -e "NODE: $vNODE \t CAPACITY: $vCAPACIDAD"
            fi
        fi
    fi
done

# --- Step 7: Operator Validation ---
echo ""
echo "${vTRANSACTION}> 7. Validando OPERATORs (ACTIVOS)..."
echo "--> [oc get clusteroperators]" && oc get clusteroperators

# --- Step 8 & 9: Pod Status Validation ---
echo ""
echo "${vTRANSACTION}> 8. Validando PODs en estado: [PENDING/ERROR] (NO READY)..."
oc get pods --all-namespaces -o json | jq -r '.items[] | select(.status.phase != "Running" and .status.phase != "Succeeded") | "\(.metadata.namespace)\t\(.metadata.name)\t\(.status.phase)"'
echo "--> [oc get pods --all-namespaces | grep -Ev '(\w)/\1|Completed|Running']"
oc get pods --all-namespaces | grep -Ev '(\w)/\1|Completed|Running'

# --- Step 10 - 13: Standard Resource Checks ---
echo ""
echo "${vTRANSACTION}> 10. Validando DEPLOYMENTs & DEPLOYMENTCONFIGs..."
echo "--> [oc get deployments --all-namespaces]" && oc get deployments --all-namespaces
echo "--> [oc get deploymentconfigs --all-namespaces]" && oc get deploymentconfigs --all-namespaces
echo ""
echo "${vTRANSACTION}> 11. Validando SERVICEs & ROUTEs..."
echo "--> [oc get services --all-namespaces]" && oc get services --all-namespaces
echo "--> [oc get routes --all-namespaces]" && oc get routes --all-namespaces
echo ""
echo "${vTRANSACTION}> 12. Validando IMAGESTREAMs..."
echo "--> [oc get imagestreams --all-namespaces]" && oc get imagestreams --all-namespaces
echo ""
echo "${vTRANSACTION}> 13. Validando NETWORKPOLICIEs..."
echo "--> [oc get networkpolicies --all-namespaces]" && oc get networkpolicies --all-namespaces

# --- Step 14: Resource Capacity and Consumption ---
echo ""
echo "${vTRANSACTION}> 14. Validando CAPACIDAD & CONSUMO de RECURSOS [CPU/RAM]..."
echo "--> [oc adm top nodes]" && oc adm top nodes
echo "--> [oc get nodes -o=custom-columns=NODE:.metadata.name,CPU:.status.capacity.cpu,MEMORY:.status.capacity.memory]" && oc get nodes -o=custom-columns=NODE:.metadata.name,CPU:.status.capacity.cpu,MEMORY:.status.capacity.memory

# --- Step 15: Certificate Validation ---
echo ""
echo "${vTRANSACTION}> 15. Validando CERTIFICADOS (UBICACIÓN & FECHA LÍMITE)..."
# macOS compatibility fix for base64 decode
b64_decode="base64 -d"
if [[ "$(uname)" == "Darwin" ]]; then
  b64_decode="base64 -D"
fi
echo -e "NAMESPACE\tNAME\tEXPIRY" && oc get secrets -A -o go-template='{{range .items}}{{if eq .type "kubernetes.io/tls"}}{{.metadata.namespace}}{{" "}}{{.metadata.name}}{{" "}}{{index .data "tls.crt"}}{{"\n"}}{{end}}{{end}}' | while read namespace name cert; do echo -en "$namespace\t$name\t"; echo $cert | $b64_decode | openssl x509 -noout -enddate 2>/dev/null; done | column -t

# --- Step 16 & 17: Machine and CSR Validation ---
echo ""
echo "${vTRANSACTION}> 16. Validando existencia de MACHINES & MACHINECONFIGPOOL..."
echo "--> [oc get machineconfigpool]" && oc get machineconfigpool
echo "--> [oc get machines -n openshift-machine-api]" && oc get machines -n openshift-machine-api
echo ""
echo "${vTRANSACTION}> 17. Validando CERTIFICATE SIGNING REQUEST (CSR)..."
echo "--> [oc get csr]" && oc get csr

# --- Step 18: Smoke Test - App Deployment ---
echo ""
echo "${vTRANSACTION}> 18. Iniciando SMOKE TEST de despliegue de APP..."
echo "--> [oc create ns ${NAMESPACE_NAME}]"
oc create ns ${NAMESPACE_NAME}
echo "--> [Ejecutando YAML para el DEPLOYMENT del SERVICIO]"
cat <<EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dummy-micro-deploy
  namespace: ${NAMESPACE_NAME}
  labels:
    app: dummy-micro-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dummy-micro-service
  template:
    metadata:
      labels:
        app: dummy-micro-service
    spec:
      containers:
      - image: maktup/dummy-micro-01:latest
        name: dummy-micro-container
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: dummy-micro-service
  namespace: ${NAMESPACE_NAME}
  labels:
    app: dummy-micro-service
spec:
  ports:
  - port: 8080
  selector:
    app: dummy-micro-service
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: dummy-micro-route
  namespace: ${NAMESPACE_NAME}
spec:
  to:
    kind: Service
    name: dummy-micro-service
EOF

# --- Step 19: Smoke Test - Service Validation ---
echo ""
echo "${vTRANSACTION}> 19. Validando TEST de SERVICIO..."
# Improved wait: Replaced unreliable 'sleep' with 'rollout status'
echo "--> Esperando que el despliegue esté listo (máximo 2 minutos)... "
if oc rollout status deployment/dummy-micro-deploy -n ${NAMESPACE_NAME} --timeout=120s; then
    ROUTE_URL=$(oc get route dummy-micro-route -n ${NAMESPACE_NAME} -o jsonpath='{.spec.host}')
    echo "--> [curl -s http://${ROUTE_URL}/dummy-micro-01/get/personas]"
    curl -s http://${ROUTE_URL}/dummy-micro-01/get/personas
else
    echo "ERROR: El despliegue de prueba no estuvo listo a tiempo."
fi

# --- Step 20: Smoke Test - Cleanup ---
echo ""
echo ""
echo "${vTRANSACTION}> 20. Limpiando RECURSOS creados para el TEST..."
echo "--> [oc delete ns ${NAMESPACE_NAME}]"
oc delete ns ${NAMESPACE_NAME}

# --- Completion ---
echo ""
echo ""
echo "${vTRANSACTION}> *********************** [PROCESO DE VALIDACIÓN: 'TERMINADO'] ***********************"
echo "${vTRANSACTION}> Exportando REPORTE de LOG: [${REPORT_LOG_NAME}]..."
echo ""
