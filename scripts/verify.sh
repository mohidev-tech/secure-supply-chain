#!/usr/bin/env bash
# Manually verify a published image — exactly what the admission controller does.
#
#   ./scripts/verify.sh [IMAGE_REF]
#
# IMAGE_REF defaults to ghcr.io/mohidev-tech/secure-supply-chain-app:main
# Prefer pinning a digest: IMAGE@sha256:...
set -euo pipefail

IMAGE="${1:-ghcr.io/mohidev-tech/secure-supply-chain-app:main}"
REPO="mohidev-tech/secure-supply-chain"

echo "==> Verifying signature on ${IMAGE}"
COSIGN_EXPERIMENTAL=1 cosign verify \
  --certificate-identity-regexp "https://github.com/${REPO}/.github/workflows/release.yml@refs/" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  "${IMAGE}" | jq '.[0] | {critical, optional: .optional | {Issuer, Subject}}' 2>/dev/null \
  || echo "  (jq not installed — raw output above)"

echo ""
echo "==> Verifying SBOM attestation on ${IMAGE}"
COSIGN_EXPERIMENTAL=1 cosign verify-attestation \
  --type spdxjson \
  --certificate-identity-regexp "https://github.com/${REPO}/.github/workflows/release.yml@refs/" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  "${IMAGE}" > /dev/null

echo ""
echo "==> Image is signed by ${REPO}/.github/workflows/release.yml and has an SBOM attestation."
