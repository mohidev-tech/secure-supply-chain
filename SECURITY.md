# Security policy

This repo's whole purpose is to **demonstrate supply-chain security**. So security reports against it are taken seriously — and the threat model is more interesting than for a typical app, since the artifact (a signed image) is itself what gets shipped to consumers.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting:

→ [Report a vulnerability](https://github.com/mohidev-tech/secure-supply-chain/security/advisories/new)

Please include:

- A short description.
- The component (workflow, policy, helm chart, signing script).
- A reproducer if possible. For supply-chain issues this often means: a publishable scenario where a verifier would incorrectly accept (or reject) an image.

I aim to acknowledge within **72 hours** and fix critical issues within **30 days**.

## Verifying our published artifacts yourself

Don't trust this README — verify directly:

```bash
cosign verify \
  --certificate-identity-regexp "https://github.com/mohidev-tech/secure-supply-chain/.github/workflows/release.yml@refs/" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  ghcr.io/mohidev-tech/secure-supply-chain-app:main

cosign verify-attestation \
  --type spdxjson \
  --certificate-identity-regexp "https://github.com/mohidev-tech/secure-supply-chain/.github/workflows/release.yml@refs/" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  ghcr.io/mohidev-tech/secure-supply-chain-app:main
```

If either fails, **don't deploy** — and please report it.

## What's in scope

- A scenario where an unsigned or wrongly-signed image gets admitted by the policy in `deploy/policy/`.
- A workflow file change that would cause signatures from forks or unrelated branches to validate.
- Secrets exposed in CI logs.
- Path traversal or arbitrary file write via scripts.
- A way to publish to `ghcr.io/mohidev-tech/secure-supply-chain-app*` without going through `.github/workflows/release.yml@refs/heads/main`.

## What's out of scope

- Vulnerabilities in Sigstore (Fulcio, Rekor, Cosign) — report upstream, then let us know if we need to bump a dep.
- Vulnerabilities in upstream base images (distroless) — same.
- "An attacker who compromises GitHub itself could sign images" — yes, that's the trust root we're documenting. SLSA L3 is "non-falsifiable provenance assuming the build platform isn't compromised."

## The trust chain in one paragraph

A consumer of `ghcr.io/mohidev-tech/secure-supply-chain-app@sha256:...` is trusting, in order:

1. **GitHub** to issue OIDC tokens only to the workflow that actually runs.
2. **Sigstore Fulcio** to issue a code-signing cert only when GitHub's OIDC token verifies.
3. **Sigstore Rekor** to record the signature in an append-only public log.
4. **GHCR** to serve the image at the digest the signature was made over.

If any link is broken, the signature should fail to verify. If verification ever silently succeeds when one of these is broken, that's a critical bug — please report it.

## Hardening if you fork this

- **Pin the cosign version** in `release.yml`. We use `sigstore/cosign-installer@v3` — pin to a SHA in your fork if you care about supply chain on the supply-chain tool.
- **Use a self-hosted runner** if you don't trust GitHub-hosted ones with your signing identity. The workflow needs `id-token: write`; that's all the OIDC permission required.
- **Run your own Rekor** if you're airgapped or paranoid. Document the new URL in the verify policies.
