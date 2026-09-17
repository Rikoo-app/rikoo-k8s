# External components

Each file switches one bundled store off and points Rikoo at a managed service. They compose, on
top of `../minimal-installation/values.yaml`:

```bash
helm upgrade --install rikoo ../../charts/rikoo -n rikoo \
  -f ../minimal-installation/values.yaml \
  -f external-postgres.yaml -f external-redis.yaml -f external-s3.yaml \
  --set rikoo.image.registry=<registry>/<namespace> --set rikoo.image.tag=vX.Y.Z
```

| File | Replaces | Notes |
| ---- | -------- | ----- |
| `external-postgres.yaml` | Bundled PostgreSQL | pgvector must be available on the instance, and the role must be able to create extensions |
| `external-redis.yaml` | Bundled Redis | The target must run with `maxmemory-policy noeviction` |
| `external-s3.yaml` | Bundled MinIO | Any S3-compatible storage; path-style addressing is usually off there |

The Secrets referenced (`rikoo-db`, `rikoo-redis`, `rikoo-s3`) are created before the install, by
hand or through an external secrets operator. Never a credential in a committed values file.
