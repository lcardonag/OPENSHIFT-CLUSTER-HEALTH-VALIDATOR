#!/bin/bash

# ************************************************************************************************ 
# * - DESCRIPCION: Shell para validación & generación de REPORTE de SALUD para Cluster OPENSHIFT *
# * - EJECUCION:   SHELL                                                                         *
# * - AUTOR:       Guerra Arnaiz, Cesar Ricardo                                                  *
# * - FECHA:       16/07/2024                                                                    *
# * - VERSION:     1.0                                                                           *
# ************************************************************************************************

clear

vCURRENT_DATE=`DATE +%Y%m%d%H%M%S`
vTRANSACTION="$vCURRENT_DATE - [INFO]": 
vWAIT_TIME=4
vDATE_LOG=`date +%Y%m%d`

USERNAME="admin"
PASSWORD="xxx"
TOKEN_NAME="sha256~8u_hOjnLFLTr6aA2Wpq6puwErKKb5Qc9DyN0qaaPfY4"
API_SERVER="https://c100-e.us-south.containers.cloud.ibm.com:30807"
REPORT_LOG_NAME="cluster-validator-report.log"

echo "${vTRANSACTION}> 0. Eliminando REPORTE anterior..."  
rm ${REPORT_LOG_NAME}

exec &> >(tee -a "${REPORT_LOG_NAME}")

echo ""
echo "${vTRANSACTION}> ******************** [PROCESO DE VALIDACIÓN: 'CLUSTER: OPENSHIFT'] ********************"
echo "${vTRANSACTION}> EJECUTANDO SCRIPT..."

echo ""
echo ""
echo "${vTRANSACTION}> 1. Autenticando en OPENSHIFT..." 
echo ""
echo "${vTRANSACTION}> [oc login --server=${API_SERVER} --username=${USERNAME} --password=${PASSWORD}]"
oc login --server=${API_SERVER} --username=${USERNAME} --password=${PASSWORD}
echo ""
echo "${vTRANSACTION}> [oc login --token=${TOKEN_NAME} --server=${API_SERVER}]"
oc login --token=${TOKEN_NAME} --server=${API_SERVER}
 
 
echo ""
echo "" 
echo "${vTRANSACTION}> 2. Validando información del CLÚSTER, la VERSIÓN (ACTUAL) & las VERSIONES (DISPONIBLEs) en el CLUSTER..."
echo ""
echo "${vTRANSACTION}> [oc version]"
oc version
echo ""
echo "${vTRANSACTION}> [oc cluster-info]"
oc cluster-info
echo ""
echo "${vTRANSACTION}> [oc get clusterversion]" 
oc get clusterversion
echo ""
echo "${vTRANSACTION}> [oc adm upgrade]" 
oc adm upgrade 

 
echo ""
echo ""
echo "${vTRANSACTION}> 3. Validando NODOS (MASTER/WORKER)..."
echo ""
echo "${vTRANSACTION}> [oc get nodes -o wide]"
oc get nodes -o wide
echo ""
echo "${vTRANSACTION}> [oc get nodes -l node-role.kubernetes.io/master]"
oc get nodes -l node-role.kubernetes.io/master
echo ""
echo "${vTRANSACTION}> [oc get nodes -l node-role.kubernetes.io/worker]"
oc get nodes -l node-role.kubernetes.io/worker
 
 
echo ""
echo ""
echo "${vTRANSACTION}> 4. Validando USUARIOS & GRUPOS...."
echo ""
echo "${vTRANSACTION}> [oc get users]"
oc get users
echo ""
echo "${vTRANSACTION}> [oc get groups]" 
oc get groups


echo ""
echo ""
echo "${vTRANSACTION}> 5. Validando PERSISTENT-VOLUME, PERSISTENT-VOLUME-CLAIN & STORAGE-CLASSES..."
echo ""
echo "${vTRANSACTION}> [oc get pv --all-namespaces]" 
oc get pv --all-namespaces
echo ""
echo "${vTRANSACTION}> [oc get pvc --all-namespaces]" 
oc get pvc --all-namespaces
echo ""
echo "${vTRANSACTION}> [oc get storageclass --all-namespaces]" 
oc get storageclass --all-namespaces


echo ""
echo ""
echo "${vTRANSACTION}> 6. Validando PERSISTENT-VOLUME (STORAGE) utilizados por PODs..."
echo ""
echo "${vTRANSACTION}> [Obteniendo STORAGE utilizados por PODs]" 
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


echo ""
echo ""
echo "${vTRANSACTION}> 7. Validando OPERATORs (ACTIVOS)..."
echo ""
echo "${vTRANSACTION}> [oc get clusteroperators]" 
oc get clusteroperators
echo ""
echo "${vTRANSACTION}> [oc get clusteroperators -o name]" 
oc get clusteroperators -o name


echo ""
echo ""
echo "${vTRANSACTION}> 8. Validando PODs..."
echo ""
echo "${vTRANSACTION}> [oc get pods --all-namespaces]"
oc get pods --all-namespaces


echo ""
echo ""
echo "${vTRANSACTION}> 9. Validando PODs en estado: [PENDING/ERROR] (NO READY)..."
echo ""
echo '${vTRANSACTION}> [oc get pods --all-namespaces -o json | jq -r ".items[] | select(.status.phase != \"Running\" and .status.phase != \"Succeeded\") | \"\(.metadata.namespace)\t\(.metadata.name)\t\(.status.phase)\""]'
oc get pods --all-namespaces -o json | jq -r '.items[] | select(.status.phase != "Running" and .status.phase != "Succeeded") | "\(.metadata.namespace)\t\(.metadata.name)\t\(.status.phase)"'
echo ""
echo "${vTRANSACTION}> [oc get pods --all-namespaces | grep -Ev '(\w)/\1|Completed']" 
oc get pods --all-namespaces | grep -Ev '(\w)/\1|Completed'


echo ""
echo ""
echo "${vTRANSACTION}> 10. Validando DEPLOYMENTs & DEPLOYMENTCONFIGs..."
echo ""
echo "${vTRANSACTION}> [oc get deployments --all-namespaces]"
oc get deployments --all-namespaces
echo ""
echo "${vTRANSACTION}> [oc get deploymentconfigs --all-namespaces]"
oc get deploymentconfigs --all-namespaces


echo ""
echo "" 
echo "${vTRANSACTION}> 11. Validando SERVICEs & ROUTEs..."
echo ""
echo "${vTRANSACTION}> [oc get services --all-namespaces]"
oc get services --all-namespaces
echo ""
echo "${vTRANSACTION}> [oc get routes  --all-namespaces]"
oc get routes  --all-namespaces


echo ""
echo ""
echo "${vTRANSACTION}> 12. Validando IMAGESTREAMs..."
echo ""
echo "${vTRANSACTION}> [oc get imagestreams --all-namespaces]"
oc get imagestreams --all-namespaces


echo ""
echo "" 
echo "${vTRANSACTION}> 13. Validando NETWORKPOLICIEs..."
echo ""
echo "${vTRANSACTION}> [oc get networkpolicies --all-namespaces]"
oc get networkpolicies --all-namespaces


echo ""
echo "" 
echo "${vTRANSACTION}> 14. Validando CAPACIDAD & CONSUMO de RECURSOS [CPU/RAM]..."
echo ""
echo "${vTRANSACTION}> [oc adm top nodes]"
oc adm top nodes
echo ""
echo "${vTRANSACTION}> [oc get nodes -o=custom-columns=NODE:.metadata.name,CPU:.status.capacity.cpu,MEMORY:.status.capacity.memory]"
oc get nodes -o=custom-columns=NODE:.metadata.name,CPU:.status.capacity.cpu,MEMORY:.status.capacity.memory
echo ""
echo '${vTRANSACTION}> [oc get nodes -o=custom-columns=NODE:.metadata.name,CPU:.status.capacity.cpu,MEMORY:.status.capacity.memory --no-headers | awk '\''{printf "%s\t%s\t%.2fMi\n", $1, $2, $3/1024/1024}'\'']'
oc get nodes -o=custom-columns=NODE:.metadata.name,CPU:.status.capacity.cpu,MEMORY:.status.capacity.memory --no-headers | awk '{printf "%s\t%s\t%.2fMi\n", $1, $2, $3/1024/1024}'
 

echo ""
echo "" 
echo "${vTRANSACTION}> 15. Validando CERTIFICADOS (UBICACIÓN & FECHA LÍMITE)..."
echo ""
echo '${vTRANSACTION}> [echo -e "NAMESPACE\tNAME\tEXPIRY" && oc get secrets -A -o go-template='{{range .items}}{{if eq .type "kubernetes.io/tls"}}{{.metadata.namespace}}{{" "}}{{.metadata.name}}{{" "}}{{index .data "tls.crt"}}{{"\n"}}{{end}}{{end}}' | while read namespace name cert; do echo -en "$namespace\t$name\t"; echo $cert | base64 -d | openssl x509 -noout -enddate; done | column -t]'
echo -e "NAMESPACE\tNAME\tEXPIRY" && oc get secrets -A -o go-template='{{range .items}}{{if eq .type "kubernetes.io/tls"}}{{.metadata.namespace}}{{" "}}{{.metadata.name}}{{" "}}{{index .data "tls.crt"}}{{"\n"}}{{end}}{{end}}' | while read namespace name cert; do echo -en "$namespace\t$name\t"; echo $cert | base64 -d | openssl x509 -noout -enddate; done | column -t


echo ""
echo "${vTRANSACTION}> 16. Validando existencia de MACHINES & MACHINECONFIGPOOL..."
echo ""
echo "${vTRANSACTION}> [oc get machineconfigpool]"
oc get machineconfigpool
echo ""
echo "${vTRANSACTION}> [oc get machines -n openshift-machine-api]"
oc get machines -n openshift-machine-api 
 

echo ""
echo "" 
echo "${vTRANSACTION}> 17. Validando existencia de: CERTIFICATE SIGNING REQUEST (CSR) en el CLUSTER (si están APROBADAS)..."
echo ""
echo "${vTRANSACTION}> [oc get csr]"
oc get csr 
  

echo ""
echo ""
echo "${vTRANSACTION}> 18. Validando DESPLIEGUE de APP..."
echo ""
NAMESPACE_NAME="dummy-test-cluster"
echo "${vTRANSACTION}> [oc create ns ${NAMESPACE_NAME}]"
oc create ns ${NAMESPACE_NAME}

echo ""
echo "${vTRANSACTION}> [Ejecutando YAML para el DEPLOYMENT del SERVICIO]"
cat <<EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dummy-micro-deploy
  namespace: ${NAMESPACE_NAME}
  labels:
    app: dummy-micro-service
    version: v1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dummy-micro-service
      version: v1
  template:
    metadata:
      labels:
        app: dummy-micro-service
        version: v1
    spec:
      containers:
      - image: maktup/dummy-micro-01:latest
        name: dummy-micro-container
        resources:
          limits:
            cpu: 300m
          requests:
            cpu: 100m
        ports:
        - containerPort: 8080
EOF

cat <<EOF | oc apply -f -
apiVersion: v1
kind: Service
metadata:
  name: dummy-micro-service
  namespace: ${NAMESPACE_NAME}
  labels:
    app: dummy-micro-service
spec:
  type: ClusterIP
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: dummy-micro-service
EOF

cat <<EOF | oc apply -f -
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: dummy-micro-route
  namespace: ${NAMESPACE_NAME}
  labels:
    app: dummy-micro-service
spec:
  port:
    targetPort: 8080
  to:
    kind: Service
    name: dummy-micro-service
EOF


echo ""
echo "" 
ROUTE_URL=$(oc get route dummy-micro-route -n ${NAMESPACE_NAME} -o jsonpath='{.spec.host}')
echo "${vTRANSACTION}> 19. Validando TEST de SERVICIO..."
echo "${vTRANSACTION}> [curl -s http://${ROUTE_URL}/dummy-micro-01/get/personas]"
echo "${vTRANSACTION}> Esperando: 120 seg para el termino del DESPLIEGUE... "
sleep 120
curl -s http://${ROUTE_URL}/dummy-micro-01/get/personas


echo ""
echo "" 
echo "${vTRANSACTION}> 20. Limpiando RECURSOS creados para el TEST..."
echo "" 
echo "${vTRANSACTION}> [oc delete all --all -n ${NAMESPACE_NAME}]"
oc delete all --all -n ${NAMESPACE_NAME}

echo "" 
echo "${vTRANSACTION}> [oc delete ns ${NAMESPACE_NAME}]"
oc delete ns ${NAMESPACE_NAME}


echo ""
echo ""
echo "${vTRANSACTION}> *********************** [PROCESO DE VALIDACIÓN: 'TERMINADO'] ***********************"
echo "${vTRANSACTION}> Exportando REPORTE de LOG: [${REPORT_LOG_NAME}]..."
echo ""

