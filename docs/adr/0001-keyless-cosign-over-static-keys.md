# ADR 0001 — Keyless cosign over static signing keys

## Status
Accepted

## Context
Image signing needs a key. Two camps:

1. **Static keypair** — generate `cosign generate-key-pair`, store the private half in GitHub Actions secrets or Vault, distribute the public half to verifiers. This is the classic PKI shape.
2. **Keyless (OIDC + Fulcio + Rekor)** — the workflow gets a short-lived OIDC token from GitHub, exchanges it with the Sigstore Fulcio CA for a code-signing certificate valid for ~10 minutes, signs the image, and writes the signature to the public Rekor transparency log. No long-lived secret exists.

## Decision
Use **keyless**. The workflow has `id-token: write` permission; everything downstream verifies against the GitHub OIDC issuer + the specific workflow file path.

## Why
- **No key to rotate, no key to leak.** The biggest operational win. There is literally no static secret an attacker could steal that would let them sign as us.
- **The signer identity is auditable.** `cosign verify` returns the certificate subject — exactly which workflow file in which branch produced the signature. A compromised GHCR token alone cannot forge this; the attacker would also need to land code in the workflow on `main`, which is gated by branch protection + review.
- **Transparency by default.** Every signature is in Rekor's public append-only log. A surprise signature shows up in monitoring.
- **Matches the SLSA L3+ build-platform model.** Fulcio is exactly the "trusted builder identity" piece SLSA expects.

## Consequences
- ✅ Verifiers must reach the Sigstore public-good infrastructure (Fulcio, Rekor) at admission time. For airgapped environments this would not work without running our own — a Phase 4+ concern, out of scope here.
- ✅ Signature verification scripts (`scripts/verify.sh`) and admission policies must specify the exact `certificate-identity` regex. This is a feature: it pins WHO can sign, not just whether something is signed.
- ⚠️ Rotation of the issuer is GitHub's responsibility. If GitHub's OIDC issuer changes, every verifier policy needs updating. Mitigation: the regex pattern is in one place per consumer.
