# Troubleshooting

| Symptom | Likely cause | What to do |
| --- | --- | --- |
| `helm install` refuses: `rikoo.image.registry is required` or `rikoo.image.tag is required` | No registry or no version | Set both: `--set rikoo.image.registry=registry.example.com/rikoo --set rikoo.image.tag=vX.Y.Z` |
| `helm install` refuses: `vault PUBLIC key is required` or `PRIVATE key` | The sealing pair is missing | Generate an RSA 3072 PEM pair with OpenSSL, then set `rikoo.secrets.sealing.existingSecret` (keys `sealing.pub` and `sealing.key`) |
| api pods in `ImagePullBackOff` | Private registry without a pull secret | `kubectl create secret docker-registry …` and list it in `rikoo.image.pullSecrets` |
| api in `CreateContainerConfigError`, worker stuck in `Init:0/1` | The sealing Secret did not exist at install time | Create it, then `kubectl -n <ns> delete pod -l app.kubernetes.io/component=worker`: the api recovers on its own within seconds, the worker would otherwise sit in the kubelet mount backoff for minutes |
| Bundled MinIO in `ErrImagePull` from `docker.io/minio/minio` | Wrong registry | MinIO publishes its `RELEASE.*` tags on **quay.io**; the chart points there by default, do not move it back to Docker Hub |
| api in `CrashLoopBackOff`, log mentions environment validation | A variable required in production is missing (`PUBLIC_URL`, `S3_*`, `WIDGET_SIGNING_KEY`…) | Read the message: it names the variable. Set it through values, never through a mounted `.env` |
| api `Running` but never `Ready` | `/readyz` returns 503: PostgreSQL or Redis unreachable | Port-forward and `curl /readyz`: the body says which dependency is `down` |
| The migrations Job fails on upgrade | The database refused a migration | `kubectl logs job/<release>-migrations`. The release has not rolled; fix, then upgrade again |
| Worker looping on `wait-for-api` | The api never reaches `/readyz` (long migrations, database down) | Look at the api first. Use `rikoo.worker.waitForApi: false` only to diagnose |
| Browser upload refused (CORS, or a 403 on the signature) | `s3.browserEndpoint` missing, or different from the signed origin | Give the store a public route (`s3.ingress` for the bundled MinIO) and set `s3.browserEndpoint` to that origin |
| Upload cut short, proxy error page instead of a JSON error | The ingress body-size limit is below `ATTACHMENT_MAX_BYTES` | Raise it, for example `nginx.ingress.kubernetes.io/proxy-body-size: 12m` |
| Streamed answers arrive all at once | The proxy buffers the response | `proxy-buffering: "off"` and a high `proxy-read-timeout` |
| The sandbox Browser tool answers 403 | The `--allowed-hosts` authority does not match `SANDBOX_PLAYWRIGHT_URL` | The chart keeps them aligned; check for a `fullnameOverride` or a changed port |
| The sandbox Shell reaches the internet | The CNI does not enforce NetworkPolicies | Use a CNI that does, or set `rikoo.sandbox.enabled: false` |
| Bundled PostgreSQL: "too many connections" | `rikoo.worker.dbPool` times the replica count is too high | Lower `dbPool`, or raise `max_connections` through `postgresql.customConfig` |
| Generated secrets rotate on every ArgoCD sync | `lookup` is blind under `helm template` | Pin every key with `value` or `secretKeyRef` |
