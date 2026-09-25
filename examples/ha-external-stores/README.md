# HA production, external stores

Three replicas of the api and of the worker, spread across zones, with managed PostgreSQL, Redis and
object storage. No credential is written in the values file: every one of them is read from a Secret
you create first.

```bash
kubectl create namespace rikoo
kubectl -n rikoo create secret docker-registry rikoo-registry \
  --docker-server=<registry> --docker-username=<user> --docker-password=<token>
# create the five Secrets listed below, then:
helm install rikoo rikoo/rikoo -n rikoo -f values.yaml \
  --set rikoo.image.registry=<registry>/<namespace> --set rikoo.image.tag=vX.Y.Z
```

## What you must provide

| Secret | Keys | Notes |
| --- | --- | --- |
| `rikoo-app` | `widget-signing-key`, `widget-visitor-key`, `totp-key`, `sandbox-token-secret` | 32 characters minimum each, `openssl rand -hex 24` |
| `rikoo-sealing` | `sealing.pub`, `sealing.key` | RSA 3072 PEM pair, generated once with OpenSSL. The chart never creates it, and a regenerated pair makes every stored secret unreadable |
| `rikoo-db` | `url` | Owner connection string. The role must be able to `CREATE EXTENSION vector`, which usually means owning the database |
| `rikoo-redis-url` | `url` | `rediss://…`. The instance must run `maxmemory-policy noeviction` |
| `rikoo-s3` | `access-key-id`, `secret-access-key` | |

The four application keys are pinned here rather than generated. The chart can generate them on
first install and keep them, but under a GitOps render (`helm template`, ArgoCD) `lookup` sees no
cluster, so each sync would rotate them and invalidate every widget token in flight.

## What your cluster must provide

- **A CNI that enforces NetworkPolicies.** The sandbox isolation is three NetworkPolicies and
  nothing else. Where they are not enforced, the boundary does not exist.
- **KEDA**, for the worker's queue-depth scaling, plus a `TriggerAuthentication` named `rikoo-redis`
  carrying the Redis address and password. Without KEDA, set `rikoo.worker.keda.enabled: false` and
  use `hpa` instead, accepting that CPU is a poor signal for a queue.
- **A metrics server**, for the api's HPA.
- **Three zones**, or the spread constraints have nothing to spread over. They are
  `ScheduleAnyway`, so a smaller cluster still schedules; it just does not spread.

## Why the worker scales on queue depth and the api on CPU

The api is request-driven: its CPU tracks its load. The worker is not. A worker waiting on a slow
model call uses almost no CPU while the backlog grows, so CPU-based scaling would leave runs queued
behind idle-looking pods. The signal is the depth of the BullMQ wait list.

Adjust `listName` if you scale on a different queue than `llm`. `listLength: "5"` means one more
replica per five waiting jobs, per replica.

## The database connection budget

`maxReplicaCount: 12` at `dbPool: 15` is 180 connections at full stretch, plus the api's own. Check
that against your instance's maximum before raising either number. The chart refuses a pair that
would exceed a *bundled* PostgreSQL, but it cannot know the limit of a managed one.

## What is not redundant

The MCP sandbox holds one workspace per conversation. A second replica would be asked about state it
does not have, so it runs a single pod with the `Recreate` strategy, and its browser and egress proxy
follow it. A conversation whose sandbox pod is replaced loses that workspace: the run reports the
failure rather than returning a wrong answer, and the conversation can be resumed. Rolling the
sandbox is therefore a visible, if brief, interruption for conversations using tools at that moment.

Everything else here survives the loss of a pod, a node or a zone.

## Settings

`rikoo.settings` and the per-service `settings` maps carry the product variables the chart does not
model. Every name is checked at render time against `env-contract.json`, shipped with the chart: a
name this version of Rikoo does not read is refused, so is a secret (it would land in a ConfigMap),
so is a name the chart already sets, and so is a name no reachable service reads. `VARIABLES.md`
lists what you may set.
