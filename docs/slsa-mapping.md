# SLSA mapping

[SLSA v1.0](https://slsa.dev/spec/v1.0/levels) defines four levels for the *build* track. Here's what this repo claims and where.

| Requirement | Where it's satisfied | Notes |
|---|---|---|
| **Build L1** — provenance available | `actions/attest-build-provenance@v1` step in `.github/workflows/release.yml` | GitHub native attestation, attached to the image in GHCR |
| **Build L2** — hosted, tamper-resistant build platform | GitHub-hosted runners; workflow gates via `if: github.event_name == 'push'` and branch protection | The runners are not under our control, and the workflow is in `main` (protected) |
| **Build L3** — non-falsifiable provenance | Sigstore Fulcio short-lived cert tied to the OIDC token from GitHub; signature written to Rekor (public transparency log) | Verifier pins `certificate-identity-regexp` to this repo's workflow path — an attacker would need to compromise GitHub Actions itself to forge |
| **Build L4** — hermetic, reproducible builds | _not claimed_ | Distroless final stage + `-trimpath` + pinned `go 1.22` get us closer than typical CI, but we are not building under a hermetic sandbox |

## What the signature actually says

Decode any of our signatures:

```bash
cosign verify --certificate-identity-regexp \
  "https://github.com/mohidev-tech/secure-supply-chain/.github/workflows/release.yml@refs/" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  ghcr.io/mohidev-tech/secure-supply-chain-app:main | jq '.[0].optional.Subject'
```

That subject is the **identity of the workflow file at the commit that produced the build**. Not a person. Not a long-lived robot account. The workflow file itself, attested by GitHub's OIDC.

## What the SBOM attestation adds

A signed signature alone tells you *who* built the image. The SBOM attestation tells you *what's in it* — every package, every version, every transitive dep, signed by the same identity. A consumer can:

1. Pull the SBOM (`scripts/download-sbom.sh`).
2. Cross-reference it against a vulnerability feed (Trivy, Grype, etc.) at any time after release.
3. Trust the result because the SBOM cannot have been swapped — the attestation signature would break.

This is the difference between "the image isn't vulnerable today" and "I can answer that question for any image we ever shipped, on demand."
