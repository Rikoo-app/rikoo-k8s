# Rikoo on Scaleway Kapsule

A managed-cloud deployment: images from a private Container Registry namespace, managed PostgreSQL
over a private network, managed Object Storage, Redis inside the cluster, and the embedded MCP
sandbox isolated by NetworkPolicies, which Kapsule enforces.

## Once per cluster

```bash
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace
helm upgrade --install cert-manager oci://quay.io/jetstack/charts/cert-manager -n cert-manager --create-namespace --set crds.enabled=true
kubectl create namespace rikoo
```

## Secrets

Three Secrets in the `rikoo` namespace, created before the install:

| Secret | Keys | Source |
| ------ | ---- | ------ |
| `rikoo-app` | `DATABASE_URL`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`, `WIDGET_SIGNING_KEY`, `RIKOO_TOTP_KEY`, `MCP_SANDBOX_TOKEN_SECRET`, `RIKOO_DEPLOYMENT_LICENSE`, `SMTP_URL` | Your secret store |
| `rikoo-sealing` | `sealing.pub`, `sealing.key` | The RSA 3072 pair you generated with OpenSSL |
| `rikoo-registry` | type `docker-registry` | A registry pull credential |

The recommended path is an external secrets operator, or a GitOps controller that decrypts sealed
manifests, so no value is ever committed. A one-off `kubectl create secret` is fine to get started.

## Install

```bash
helm upgrade --install rikoo oci://<chart-registry>/rikoo -n rikoo \
  -f values.yaml --set rikoo.image.tag=vX.Y.Z
kubectl -n rikoo rollout status deploy/rikoo-api
curl -fsS https://rikoo.example.com/api/v1/health
```

A release is one image tag. Rolling back is the same command with the previous tag, or
`helm rollback rikoo <revision>`.

## Worth knowing

- **Migrations** run twice over: the api entrypoint applies them at start-up, and a `pre-upgrade`
  Job stops the release before any pod rolls if one fails.
- **Sandbox network**: three NetworkPolicies. The shell has no route out at all, and the browser
  leaves only through the egress proxy.
- **Redis** keeps a PVC; the memory cap and `noeviction` live in `redisConfig`.
- **Attachments**: the ingress `proxy-body-size` must be greater than or equal to the product cap
  (`ATTACHMENT_MAX_BYTES`), and must never be the only limit.
