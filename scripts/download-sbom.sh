#!/usr/bin/env bash
# Pull the SBOM attestation out of the registry and decode the SPDX payload.
#
#   ./scripts/download-sbom.sh [IMAGE_REF] > sbom.spdx.json
set -euo pipefail

IMAGE="${1:-ghcr.io/mohidev-tech/secure-supply-chain-app:main}"

cosign download attestation "${IMAGE}" \
  | jq -r '.payload' \
  | base64 -d \
  | jq '.predicate'
