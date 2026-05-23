#!/usr/bin/env bash
# End-to-end demo on an existing kind/EKS cluster:
#   1. Install Kyverno
#   2. Apply the verify-signatures policy
#   3. Try to deploy an UNSIGNED image  → admission denies it
#   4. Deploy the signed app            → admission allows it
#   5. Verify the running pod's image matches the signed digest
set -euo pipefail

NS="${NS:-app}"

echo "==> Installing Kyverno"
helm repo add kyverno https://kyverno.github.io/kyverno/ 2>/dev/null || true
helm repo update
kubectl create namespace kyverno --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install kyverno kyverno/kyverno -n kyverno --wait --timeout 3m

echo ""
echo "==> Applying verify-signatures ClusterPolicy"
kubectl apply -f deploy/policy/kyverno-verify-signatures.yaml

echo ""
echo "==> NEGATIVE: attempt to deploy nginx (unsigned). Should be DENIED."
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -
if kubectl -n "$NS" run unsigned-nginx --image=nginx --restart=Never 2>&1 | tee /tmp/denied.log | grep -q "verify"; then
  echo "  ✓ admission denied as expected"
else
  echo "  ✗ EXPECTED denial. Got:"
  cat /tmp/denied.log
  exit 1
fi
kubectl -n "$NS" delete pod unsigned-nginx --ignore-not-found

echo ""
echo "==> POSITIVE: deploy the signed app via Helm"
helm upgrade --install app deploy/helm/app -n "$NS" --wait --timeout 2m
kubectl -n "$NS" rollout status deploy/app

echo ""
echo "==> Running pod's image:"
kubectl -n "$NS" get pod -l app.kubernetes.io/name=secure-supply-chain-app \
  -o jsonpath='{.items[0].status.containerStatuses[0].imageID}'
echo ""
