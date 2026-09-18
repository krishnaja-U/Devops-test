#!/usr/bin/env bash
set -e

CLUSTER="demo"
NAMESPACE="demo"
RELEASE="demo"

echo "==> Setting up cluster"
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER}$"; then
  echo "    Cluster exists, reusing"
else
  echo "    Creating cluster..."
  kind create cluster --name "$CLUSTER" --wait 5m
fi

kubectl config use-context "kind-${CLUSTER}" >/dev/null
echo "    Done"

echo "==> Creating namespace"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
echo "    Done"

echo "==> Installing ingress-nginx"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>/dev/null || true
helm repo update ingress-nginx >/dev/null 2>&1
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace --wait >/dev/null 2>&1
echo "    Done"

echo "==> Building image"
docker build -t demo-service:latest ./svc >/dev/null
echo "    Done"

echo "==> Loading image"
kind load docker-image demo-service:latest --name "$CLUSTER"
echo "    Done"

echo "==> Installing chart"
helm upgrade --install "$RELEASE" ./chart \
  --namespace "$NAMESPACE" \
  --set image.repository=demo-service \
  --set image.tag=latest \
  --wait >/dev/null
echo "    Done"

echo ""
echo "=== All set ==="
echo ""
echo "Test it:"
echo "  kubectl port-forward -n $NAMESPACE svc/$RELEASE 8080:80 &"
echo "  curl http://localhost:8080"
echo ""
EOF
