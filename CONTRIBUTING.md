# Contributing to secure-supply-chain

PRs welcome. The repo's whole purpose is to be **a reference pipeline**, so changes that improve clarity or trustworthiness of the chain are the most valuable. Adding bells and whistles is less valuable.

## Local development loop

```bash
git clone https://github.com/mohidev-tech/secure-supply-chain
cd secure-supply-chain

# Build + test the sample app
cd app
go test -race ./...
go run ./cmd/app    # listens on :8080
cd ..

# Lint the policies
kubectl --dry-run=client apply -f deploy/policy/kyverno-verify-signatures.yaml

# Lint the chart
helm lint deploy/helm/app
```

## Where to make changes

| You want to... | Edit |
|---|---|
| Add a new SAST or SCA tool to the pipeline | `.github/workflows/release.yml` — new step in `static-analysis` job |
| Change what gets signed or attested | `release.yml` — the `cosign sign` / `cosign attest` steps |
| Tighten the admission policy | `deploy/policy/kyverno-verify-signatures.yaml` |
| Add a second image (e.g. a worker) | New service dir under `app/`, new Dockerfile, second matrix entry in `release.yml` |
| Document a design decision | New file under `docs/adr/` |
| Update the SLSA mapping | `docs/slsa-mapping.md` — claims should be defensible, not aspirational |

## PR checklist

- [ ] Static-analysis job is green on the PR.
- [ ] If you changed the workflow, you tested it on a fork first (cosign keyless needs a real GitHub-hosted run; you can't run it locally).
- [ ] If you tightened a policy, you updated `scripts/demo.sh` so the negative-then-positive flow still works.
- [ ] If you changed the signer identity (e.g. a different workflow filename), you updated the Kyverno `certificate-identity` regex AND the `scripts/verify.sh` command.

## What "good" looks like in this repo

- **The chain self-verifies.** Every PR that touches signing/attestation must keep the `verify` job working — it pulls what we just pushed and runs the same `cosign verify` an admission controller would.
- **Defense in depth, not "just" cosign.** SAST, SCA, the image scan on the published digest, the SBOM attestation, and the admission policy are all complementary. PRs shouldn't replace one with another; they should improve one.
- **Pin by digest, not tag, anywhere it matters.** Tags are mutable; the signature is over the digest. The Helm chart already does this — keep it that way.

## What's deliberately out of scope

- A management UI / dashboard. The audit trail lives in Rekor + GitHub Code Scanning; that's the answer.
- A custom signing root. We use the Sigstore public good. If you need a private root, fork and run your own Fulcio/Rekor — it's documented but it's not this repo.
- Multi-registry support. GHCR only. Extending to ECR / GAR is a 30-line workflow change but adds matrix complexity.

## Reporting security issues

Don't open a public issue. See [SECURITY.md](SECURITY.md).

## License

By submitting a PR you agree the contribution is Apache 2.0 licensed. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
