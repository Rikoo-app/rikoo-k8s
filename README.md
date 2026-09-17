# rikoo-k8s

Deploy **Rikoo**, the control platform for AI agents in production, on Kubernetes with Helm: one
application chart, sub-charts for the stores, examples, and unit tests for the chart itself.

| Path                             | What it holds                                                                                   |
| -------------------------------- | ----------------------------------------------------------------------------------------------- |
| `charts/rikoo/`                  | The chart: api, worker, migrations, parsing sidecar, MCP sandbox, bundled PostgreSQL / Redis / MinIO |
| `charts/rikoo/tests/`            | [helm-unittest](https://github.com/helm-unittest/helm-unittest) suites, run by `make test`       |
| `examples/minimal-installation/` | Everything bundled, credentials from one pre-created Secret, plus an ingress and TLS variant     |
| `examples/external-components/`  | External PostgreSQL, Redis and object storage                                                    |
| `examples/scaleway-kapsule/`     | A managed-cloud deployment: Kapsule, managed PostgreSQL, Object Storage                          |
| `examples/local-kind/`           | A full trial on a local kind cluster, with images built on your workstation                      |
| `docs/decisions.md`              | The decisions taken and why                                                                      |

Exercised on a kind cluster: install, migrations, upgrade and sandbox isolation are measured, not
merely rendered. See `docs/decisions.md`.

## What the chart deploys

```
                       ┌──────────── ingress (TLS, unbuffered SSE) ─────────────┐
                       ▼                                                        │
  ┌─────────┐   ┌─────────────┐    ┌──────────────┐     ┌──────────────────┐   │
  │ Studio  │──▶│  api  (x N) │───▶│ PostgreSQL   │◀────│  worker (x N)    │   │
  │ widget  │   │ REST + SSE  │    │ pgvector     │     │ LLM · runs · RAG │   │
  └─────────┘   │ serves web  │    ├──────────────┤     │ mail · vault     │   │
                └─────────────┘    │ Redis        │◀────│ (private key)    │   │
                       ▲           ├──────────────┤     └───┬───────┬──────┘   │
   migrations Job ─────┘           │ MinIO / S3   │◀────────┘       │          │
   (post-install, pre-upgrade)     └──────────────┘                 │          │
                                                                     ▼          │
                              ┌──── sandbox network (NetworkPolicies) ────┐     │
                              │ mcp-sandbox (core) ─▶ playwright-mcp ─▶ mcp-egress ──▶ internet
                              │  Files · Shell        Chromium          egress guard
                              └────────────────────────────────────────────┘
                                          sidecar-parsing (PDF/Office, optional)
```

- **api**: REST and SSE, serves the Studio and the widget bundle. Probes are `/healthz` (liveness,
  touching no dependency) and `/readyz` (PostgreSQL and Redis). It makes no outbound call of its
  own; work leaves through the queue.
- **worker**: job processors. Sole holder of the **vault private key**, mounted as a file. Health
  and operational metrics on an internal port (`/health`, `/metrics`).
- **migrations**: the schema migrations, run from the api image as a `post-install` and
  `pre-upgrade` Job; the api entrypoint replays the same idempotent command at start-up.
- **sidecar-parsing**: rich PDF and Office extraction, stateless, with resource limits as a net
  against decompression bombs.
- **MCP sandbox**: Files, Shell and Browser, isolated per run. Three NetworkPolicies keep the shell
  off the network entirely, let the browser out only through the egress proxy, and keep the api
  away from all three.
- **bundled stores** (each switchable to a managed service): PostgreSQL with pgvector, Redis, MinIO.

## Images

The chart pulls four images: `rikoo-api`, `rikoo-worker`, `rikoo-sidecar-parsing` and
`rikoo-mcp-sandbox`, plus the upstream `mcr.microsoft.com/playwright/mcp`. Both
**`rikoo.image.registry` and `rikoo.image.tag` are required**: an image without a version is a
mistake, and the registry depends on where your release pipeline publishes.

## Requirements

- Helm 3.14 or newer, Kubernetes 1.27 or newer.
- A CNI that enforces NetworkPolicies (Cilium, Calico). Without one the sandbox isolation does not
  hold; `rikoo.networkPolicy.enabled` stays true by default and `NOTES.txt` says so on install.
- An ingress controller. The SSE and body-size annotations are documented in `values.yaml`. For
  TLS, cert-manager or any equivalent.
- The **vault sealing pair**, an RSA 3072 key in PEM. Helm cannot derive a public key from a
  private one, so the chart never generates it:

  ```bash
  openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -out sealing.private
  openssl pkey -in sealing.private -pubout -out sealing.public
  ```

## Install

```bash
helm dependency update charts/rikoo
kubectl create namespace rikoo
kubectl -n rikoo apply -f examples/minimal-installation/secret.yaml   # once filled in
helm install rikoo charts/rikoo -n rikoo \
  -f examples/minimal-installation/values.yaml \
  --set rikoo.image.registry=registry.example.com/rikoo --set rikoo.image.tag=vX.Y.Z
```

Step by step, ingress and TLS variants, managed stores and cloud profiles: see `examples/`.

## Configuration

`charts/rikoo/values.yaml` is commented key by key; every variable it sets belongs to the product's
documented environment contract. Anything not modelled there goes through `rikoo.additionalEnv`,
`rikoo.<component>.pod.additionalEnv` or `rikoo.<component>.settings`.

Worth knowing:

- **Secrets**: every key takes `value` or `secretKeyRef`. Symmetric keys left empty are generated on
  first install and kept (`helm.sh/resource-policy: keep`). Under ArgoCD or any `helm template`
  pipeline, `lookup` cannot see the cluster: pin **every** key there.
- **Attachments**: the ingress body-size limit must be greater than or equal to
  `ATTACHMENT_MAX_BYTES`, and must never be the only limit.
- **Bundled MinIO and the browser**: the Studio uploads straight to object storage, so it needs a
  public route (`s3.ingress`) and `s3.browserEndpoint` set to that origin.
- **Worker and PostgreSQL**: `rikoo.worker.dbPool` times the replica count must stay below the
  database `max_connections`; the chart refuses a render that exceeds the bundled instance's 100.

## Development

```bash
make deps      # helm dependency update
make lint      # helm lint with values.lint.yaml
make test      # helm unittest
make template  # full render, for review
make examples  # render every example, so the values stay valid together
```

The workflows in `.github/` replay lint, tests and example renders on each pull request, and
publish the chart as an OCI package when `charts/rikoo/Chart.yaml` changes on `main`.

## License

MIT, see [LICENSE](./LICENSE). The chart is deployment tooling: the Enterprise modules it can
switch on remain governed by the product's Enterprise license and still require a signed key.
