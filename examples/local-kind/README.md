# Trying the chart on kind

Everything bundled on a local cluster, with images built on your workstation. This is the setup the
chart was exercised on: Kubernetes 1.34, arm64.

## 1. Cluster and images

```bash
kind create cluster --name rikoo

# Build the four product images locally, then load them under the prefix the values expect.
for i in api worker sidecar-parsing mcp-sandbox; do
  docker tag "rikoo-${i}:latest" "rikoo/rikoo-${i}:v0.0.0-kind"
done
kind load docker-image --name rikoo \
  rikoo/rikoo-{api,worker,sidecar-parsing,mcp-sandbox}:v0.0.0-kind
```

The node pulls the store images (PostgreSQL with pgvector, Redis, MinIO) and the browser image by
itself. On Apple Silicon the product images have to be local **arm64** builds.

## 2. Sealing pair

```bash
kubectl create namespace rikoo
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -out sealing.private
openssl pkey -in sealing.private -pubout -out sealing.public
kubectl -n rikoo create secret generic rikoo-sealing \
  --from-file=sealing.pub=./sealing.public \
  --from-file=sealing.key=./sealing.private
```

Create it **before** installing. Otherwise the api recovers on its own once the Secret appears, but
the worker sits in the kubelet mount backoff for minutes; deleting its pod unblocks it.

## 3. Install

```bash
helm dependency update ../../charts/rikoo
helm install rikoo ../../charts/rikoo -n rikoo -f values.yaml
```

The migrations Job, a `post-install` hook, applies the schema before the api serves traffic. Expect
two to three minutes, mostly pulling the store images.

## 4. Checks

```bash
kubectl -n rikoo get pods
kubectl -n rikoo port-forward svc/rikoo-api 3000:http &
curl -fsS http://localhost:3000/api/v1/health     # {"status":"ok","edition":"ce",…}
curl -fsS -o /dev/null -w '%{http_code}\n' http://localhost:3000/          # Studio
curl -fsS -o /dev/null -w '%{http_code}\n' http://localhost:3000/widget/widget.js
```

Check the sandbox isolation rather than assume it. From the `mcp-sandbox` pod only Playwright
should answer; from the api, none of the sandbox pods should.

```bash
kubectl -n rikoo exec deploy/rikoo-mcp-sandbox -- node -e "
const s=require('node:net').connect(443,'1.1.1.1');
const t=setTimeout(()=>{console.log('internet: blocked');process.exit(0)},6000);
s.on('connect',()=>{clearTimeout(t);console.log('internet: REACHABLE — NetworkPolicies are not enforced');process.exit(1)});
s.on('error',()=>{clearTimeout(t);console.log('internet: blocked');process.exit(0)});"
```

If a port is already taken on your machine, forward to another one and set `rikoo.publicUrl` to
match: the session cookies and the anti-CSRF check compare against that origin.

## 5. Clean up

```bash
kind delete cluster --name rikoo
```
