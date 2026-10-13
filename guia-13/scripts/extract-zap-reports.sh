#!/usr/bin/env bash
set -Eeuo pipefail

B="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
NAMESPACE="devops-portfolio"
LOCAL_DIR="$B/../reportes"
POD_NAME="zap-report-extractor"
PVC_NAME="zap-reports"

echo "================================================================"
echo "         INICIANDO EXTRACCIÓN DE REPORTES DE ZAP                "
echo "================================================================"

mkdir -p "$LOCAL_DIR"

kubectl apply -f - <<PODEOF
apiVersion: v1
kind: Pod
metadata:
  name: $POD_NAME
  namespace: $NAMESPACE
spec:
  containers:
  - name: extractor
    image: alpine:latest
    command: ["sleep", "3600"]
    volumeMounts:
    - name: zap-storage
      mountPath: /mnt/zap-data
  volumes:
  - name: zap-storage
    persistentVolumeClaim:
      claimName: $PVC_NAME
PODEOF

kubectl wait --for=condition=Ready pod/$POD_NAME -n "$NAMESPACE" --timeout=60s

if kubectl cp "$NAMESPACE/$POD_NAME:/mnt/zap-data/" "$LOCAL_DIR/"; then
    echo " -> [OK] Archivos copiados exitosamente."
else
    echo " -> [AVISO] Hubo un problema en la copia."
fi

kubectl delete pod "$POD_NAME" -n "$NAMESPACE" --grace-period=0 --force >/dev/null 2>&1 || true
