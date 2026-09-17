# Minimal installation

Everything bundled: PostgreSQL with pgvector, Redis, MinIO, the parsing sidecar and the MCP
sandbox. Credentials come from one Secret created before the install (`secret.yaml`).

```bash
kubectl create namespace rikoo

# The images live in a private registry, so the cluster needs a pull secret.
kubectl -n rikoo create secret docker-registry rikoo-registry \
  --docker-server=<registry> --docker-username=<user> --docker-password=<token>

# Vault sealing pair, RSA 3072 in PEM. The chart never generates it.
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -out sealing.private
openssl pkey -in sealing.private -pubout -out sealing.public
# Copy both into secret.yaml, replace the other placeholders, then:
kubectl -n rikoo apply -f secret.yaml

helm dependency update ../../charts/rikoo
helm install rikoo ../../charts/rikoo -n rikoo -f values.yaml \
  --set rikoo.image.registry=<registry>/<namespace> --set rikoo.image.tag=vX.Y.Z
```

Check it:

```bash
kubectl -n rikoo get pods
kubectl -n rikoo port-forward svc/rikoo-api 3000:http &
curl -fsS http://localhost:3000/api/v1/health
```

With an ingress and TLS: `-f values.yaml -f with-ingress.yaml`, which assumes ingress-nginx and
cert-manager. The bundled MinIO gets a public route there too, required for browser uploads
(`s3.browserEndpoint`).

The first install generates the `rikoo-app` Secret for any symmetric key you did not supply, and
keeps it through uninstall (`helm.sh/resource-policy: keep`). Under ArgoCD or any `helm template`
pipeline, pin **every** key: `lookup` cannot see the cluster there.
