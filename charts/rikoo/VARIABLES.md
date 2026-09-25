<!-- GENERATED from env-contract.json by tools/variables-doc.mjs. Do not edit by hand.
     Regenerate: make variables-doc. Verify: make contract-check. -->

# Environment variables

Every variable this version of Rikoo reads in a cluster, from `env-contract.json`, which the product
generates from its own manifest and ships inside this chart. 196 in total.

**Set through** says where it belongs. A variable the chart already models has a typed value of its
own, and setting it in a `settings` map is refused at render time: two sources for one name would
leave the winner to render order. The `settings` maps are checked against this same contract, so a
mistyped name is refused instead of silently doing nothing.

What each variable *does* is not described here. See the product's own documentation for that; this
file answers whether you may set something and in which shape.

## Required by a self-hosted deployment

| Variable | Set through | Format | Default |
| --- | --- | --- | --- |
| `NODE_ENV` | a chart value | `development \| test \| production` | `development` |
| `REDIS_URL` | a chart value | `redis-url` |  |
| `PUBLIC_URL` | a chart value | `origin` | `http://localhost:3000` |
| `TRUST_PROXY_HOPS` | a chart value | `int` |  |
| `RIKOO_SECRETS_PUBLIC_KEY` | a chart value | `pem-public` |  |
| `RIKOO_SECRETS_PRIVATE_KEY_FILE` | a chart value | `path` |  |
| `S3_ENDPOINT` | a chart value | `http-url` |  |
| `S3_BUCKET` | a chart value | `nonempty` |  |

## Secrets

Never set these in a `settings` map or as a literal in `additionalEnv`: both are written in clear,
one into a ConfigMap and the other into a Deployment. Use the chart's own setting where there is one,
or `additionalEnvFrom` with a Secret.

| Variable | Set through | Format | Default |
| --- | --- | --- | --- |
| `DATABASE_URL` | a chart value | `postgres-url` |  |
| `APP_DATABASE_URL` | a chart value | `postgres-url` |  |
| `RIKOO_SECRETS_PRIVATE_KEY` | `rikoo.worker.settings` | `pem-private` |  |
| `RIKOO_SECRETS_PRIVATE_KEYS_PREVIOUS` | `rikoo.worker.settings` | `pem-private` |  |
| `S3_ACCESS_KEY_ID` | a chart value | `nonempty` |  |
| `S3_SECRET_ACCESS_KEY` | a chart value | `nonempty` |  |
| `S3_ACCESS_KEY` | `rikoo.worker.settings` | `nonempty` |  |
| `S3_SECRET_KEY` | `rikoo.worker.settings` | `nonempty` |  |
| `MINIO_ROOT_PASSWORD` | `rikoo.api.settings` | `nonempty` | `rikoominio` |
| `RIKOO_DEPLOYMENT_LICENSE` | a chart value | `base64` |  |
| `RIKOO_LICENSE_KEY` | a chart value | `nonempty` |  |
| `WIDGET_SIGNING_KEY` | a chart value | `nonempty` | `dev-insecure-widget-signing-key-x` |
| `WIDGET_VISITOR_KEY` | a chart value | `nonempty` |  |
| `RIKOO_TOTP_KEY` | a chart value | `nonempty` |  |
| `SMTP_URL` | a chart value | `url` |  |
| `CLOUDFLARE_EMAIL_API_TOKEN` | a chart value | `nonempty` |  |
| `STRIPE_SECRET_KEY` | `rikoo.settings` | `nonempty` |  |
| `STRIPE_WEBHOOK_SECRET` | `rikoo.settings` | `nonempty` |  |
| `EE_ADMIN_TOKEN` | `rikoo.settings` | `nonempty` |  |
| `PORTAL_ADMIN_TOKEN` | `rikoo.settings` | `nonempty` |  |
| `MCP_SANDBOX_TOKEN_SECRET` | a chart value | `nonempty` |  |
| `BRAVE_SEARCH_API_KEY` | `rikoo.worker.settings` | `nonempty` |  |
| `QDRANT_API_KEY` | `rikoo.settings` | `nonempty` |  |
| `OTEL_EXPORTER_OTLP_HEADERS` | a chart value | `nonempty` |  |
| `OTEL_EXPORTER_OTLP_HEADERS_API` | `rikoo.api.settings` | `nonempty` |  |

## Optional

| Variable | Set through | Format | Default |
| --- | --- | --- | --- |
| `PORT` | a chart value | `int` | `3000` |
| `WORKER_HEALTH_PORT` | a chart value | `int` | `3100` |
| `CORS_ORIGINS` | a chart value | `csv-urls` | `http://localhost:3000,http://localhost:4200` |
| `RIKOO_VERSION` | a chart value | `nonempty` | `0.0.0` |
| `RIKOO_SECRETS_PRIVATE_KEYS_PREVIOUS_FILE` | a chart value | `path` |  |
| `S3_BROWSER_ENDPOINT` | a chart value | `http-url` | `http://localhost:9000` |
| `S3_REGION` | a chart value | `nonempty` | `us-east-1` |
| `S3_FORCE_PATH_STYLE` | a chart value | `bool` | `true` |
| `S3_MAX_UPLOAD_BYTES` | `rikoo.api.settings` | `int` |  |
| `S3_UPLOAD_URL_TTL_SEC` | a chart value | `int` |  |
| `MINIO_ROOT_USER` | `rikoo.api.settings` | `nonempty` | `rikoo` |
| `RLS_ORG_POOL_MAX` | `rikoo.settings` | `int` |  |
| `RIKOO_UPGRADE_URL` | a chart value | `http-url` | `https://rikoo.io/enterprise` |
| `RIKOO_FEATURE_USAGE` | `rikoo.features` | `bool` |  |
| `RIKOO_FEATURE_FEEDBACK` | `rikoo.features` | `bool` |  |
| `RIKOO_FEATURE_AUDIT` | `rikoo.features` | `bool` |  |
| `RIKOO_FEATURE_HITL` | `rikoo.features` | `bool` |  |
| `RIKOO_FEATURE_GATES` | `rikoo.features` | `bool` |  |
| `RIKOO_FEATURE_SSO` | `rikoo.features` | `bool` |  |
| `RIKOO_FEATURE_CONNECTORS` | `rikoo.features` | `bool` |  |
| `RIKOO_FEATURE_OTLP_FANOUT` | `rikoo.features` | `bool` |  |
| `RIKOO_FEATURE_VARIABLES` | `rikoo.features` | `bool` |  |
| `RIKOO_FEATURE_ALERTING` | `rikoo.features` | `bool` |  |
| `WIDGET_STREAM_TICKET_TTL_SEC` | `rikoo.api.settings` | `int` |  |
| `WIDGET_CONVERSATION_IDLE_SEC` | `rikoo.api.settings` | `int` |  |
| `WIDGET_RUN_MAX_COST_USD` | `rikoo.api.settings` | `decimal` |  |
| `WIDGET_RUN_MAX_COST_EUR` | `rikoo.api.settings` | `decimal` |  |
| `WIDGET_RUN_MAX_TOKENS` | `rikoo.api.settings` | `int` |  |
| `WIDGET_DIST_PATH` | `rikoo.api.settings` | `path` |  |
| `SERVE_WEB` | `rikoo.api.settings` | `bool` | `true` |
| `WEB_DIST_PATH` | `rikoo.api.settings` | `path` |  |
| `WEB_LOCALE` | a chart value | `en \| fr` | `en` |
| `SESSION_SECURE_COOKIES` | a chart value | `true \| false` |  |
| `SESSION_RETENTION_DAYS` | `rikoo.worker.settings` | `int` |  |
| `SIGNUP_MODE` | a chart value | `invite \| open \| closed` |  |
| `SIGNUP_UNINVITED_MAX_PER_HOUR` | `rikoo.api.settings` | `int` |  |
| `TENANT_PURGE_GRACE_DAYS` | `rikoo.settings` | `int` |  |
| `EMAIL_FROM` | a chart value | `email-from` | `Rikoo <no-reply@rikoo.local>` |
| `CLOUDFLARE_EMAIL_ACCOUNT_ID` | a chart value | `nonempty` |  |
| `PLATFORM_IDP_GOOGLE_CLIENT_ID` | `rikoo.settings` | `nonempty` |  |
| `PLATFORM_IDP_APPLE_CLIENT_ID` | `rikoo.settings` | `nonempty` |  |
| `RUN_CONCURRENCY` | a chart value | `int` | `1` |
| `RUN_LOCK_TTL_MS` | `rikoo.worker.settings` | `int` |  |
| `RUN_RELAY_INTERVAL_MS` | `rikoo.worker.settings` | `int` | `500` |
| `RUN_WAIT_BUDGET_MS` | `rikoo.worker.settings` | `int` | `300000` |
| `RUN_HISTORY_MAX_TURNS` | `rikoo.worker.settings` | `int` | `8` |
| `RUN_HISTORY_MESSAGE_MAX_CHARS` | `rikoo.worker.settings` | `int` | `4000` |
| `RUN_CONTEXT_TOTAL_MAX_CHARS` | `rikoo.worker.settings` | `int` | `300000` |
| `RUN_TOOL_RESULT_MAX_CHARS` | `rikoo.worker.settings` | `int` | `24000` |
| `RUN_TOOL_ROUND_MAX_CHARS` | `rikoo.worker.settings` | `int` | `48000` |
| `RUN_TOOL_RESULT_MAX_IMAGES` | `rikoo.worker.settings` | `int` | `3` |
| `RUN_TOOL_PREVIEW_CHARS` | `rikoo.worker.settings` | `int` |  |
| `RUN_KNOWLEDGE_CHUNK_MAX_CHARS` | `rikoo.worker.settings` | `int` | `4000` |
| `RUN_KNOWLEDGE_RESULT_MAX_CHARS` | `rikoo.worker.settings` | `int` | `24000` |
| `RUN_KNOWLEDGE_ROUND_MAX_CHARS` | `rikoo.worker.settings` | `int` | `48000` |
| `RUN_KNOWLEDGE_CONTEXT_MAX_CHARS` | `rikoo.worker.settings` | `int` |  |
| `RUN_SKILL_INSTRUCTIONS_MAX_CHARS` | `rikoo.worker.settings` | `int` |  |
| `RUN_VIEW_ATTACHMENT_MAX_CHARS` | `rikoo.worker.settings` | `int` | `8000` |
| `RUN_VIEW_ATTACHMENT_MAX_IMAGES` | `rikoo.worker.settings` | `int` | `3` |
| `RUN_VIEW_ATTACHMENT_MAX_TOKENS` | `rikoo.worker.settings` | `int` | `24000` |
| `RUN_ABORT_RELAY_INTERVAL_MS` | `rikoo.worker.settings` | `int` |  |
| `RUN_RESUME_RELAY_INTERVAL_MS` | `rikoo.worker.settings` | `int` |  |
| `ASK_USER_TIMEOUT_MINUTES` | `rikoo.worker.settings` | `int` |  |
| `PAGE_TOOL_HOT_WAIT_MS` | `rikoo.worker.settings` | `int` |  |
| `PAGE_TOOL_HOT_BUDGET_MS` | `rikoo.worker.settings` | `int` |  |
| `HITL_DECISION_RELAY_INTERVAL_MS` | `rikoo.worker.settings` | `int` |  |
| `PIPELINE_RELAY_INTERVAL_MS` | `rikoo.worker.settings` | `int` |  |
| `TRACE_WRITE_CONCURRENCY` | `rikoo.worker.settings` | `int` | `4` |
| `RAG_INGEST_CONCURRENCY` | `rikoo.worker.settings` | `int` | `2` |
| `RAG_INGEST_INSERT_BATCH` | `rikoo.worker.settings` | `int` | `250` |
| `RAG_INGEST_TX_TIMEOUT_MS` | `rikoo.worker.settings` | `int` | `60000` |
| `RAG_EMBED_BATCH` | `rikoo.worker.settings` | `int` |  |
| `RAG_EMBED_BATCH_CHARS` | `rikoo.worker.settings` | `int` |  |
| `RAG_MAX_CHUNKS_PER_SOURCE` | `rikoo.worker.settings` | `int` |  |
| `RAG_HNSW_EF_SEARCH` | `rikoo.worker.settings` | `int` |  |
| `RETRIEVAL_SEARCH_CONCURRENCY` | `rikoo.worker.settings` | `int` | `8` |
| `RETRIEVAL_SEARCH_RELAY_INTERVAL_MS` | `rikoo.worker.settings` | `int` |  |
| `RAG_RELAY_INTERVAL_MS` | `rikoo.worker.settings` | `int` |  |
| `RAG_PDF_TIMEOUT_MS` | `rikoo.worker.settings` | `int` |  |
| `RAG_TMP_DIR` | `rikoo.worker.settings` | `path` |  |
| `RAG_SIDECAR_URL` | a chart value | `http-url` | `http://sidecar-parsing:8001` |
| `KNOWLEDGE_CONCURRENCY` | `rikoo.worker.settings` | `int` | `4` |
| `KNOWLEDGE_CLEANUP_CONCURRENCY` | `rikoo.worker.settings` | `int` | `1` |
| `KNOWLEDGE_RELAY_INTERVAL_MS` | `rikoo.worker.settings` | `int` |  |
| `KNOWLEDGE_INFLIGHT_STALE_MS` | `rikoo.worker.settings` | `int` |  |
| `KNOWLEDGE_AWAITING_UPLOAD_STALE_MS` | `rikoo.worker.settings` | `int` |  |
| `SOURCE_SYNC_CONCURRENCY` | `rikoo.worker.settings` | `int` |  |
| `ATTACHMENT_EXTRA_MEDIA_TYPES` | `rikoo.settings` | `nonempty` |  |
| `ATTACHMENT_MAX_BYTES` | a chart value | `int` |  |
| `ATTACHMENT_MAX_AUDIO_BYTES` | a chart value | `int` |  |
| `ATTACHMENT_MAX_PER_TURN` | a chart value | `int` |  |
| `ATTACHMENT_MAX_TURN_BYTES` | a chart value | `int` |  |
| `ATTACHMENT_RETENTION_DAYS` | a chart value | `int` |  |
| `ATTACHMENT_PDF_RENDER_MAX_PAGES` | `rikoo.worker.settings` | `int` | `5` |
| `ATTACHMENT_PDF_RENDER_TIMEOUT_MS` | `rikoo.worker.settings` | `int` | `120000` |
| `WEB_IMAGE_MAX_BYTES` | `rikoo.worker.settings` | `int` |  |
| `WEB_IMAGE_RETENTION_DAYS` | `rikoo.worker.settings` | `int` |  |
| `SIDECAR_MAX_UPLOAD_BYTES` | a chart value | `int` |  |
| `SIDECAR_MAX_TEXT_CHARS` | a chart value | `int` |  |
| `MCP_SANDBOX_URL` | a chart value | `http-url` | `http://mcp-sandbox:8090` |
| `MCP_SANDBOX_BROWSER_URL` | `rikoo.worker.settings` | `http-url` |  |
| `MCP_SANDBOX_TYPE` | `rikoo.settings` | `none \| gvisor \| microvm` | `none` |
| `MCP_SANDBOX_WORKSPACE_TTL_S` | `rikoo.worker.settings` | `int` | `900` |
| `WORKSPACE_SURFACE_WIDGET` | `rikoo.settings` | `bool` | `false` |
| `WORKSPACE_SURFACE_API` | `rikoo.settings` | `bool` | `true` |
| `WORKSPACE_SURFACE_SLACK` | `rikoo.settings` | `bool` | `true` |
| `WORKSPACE_SURFACE_STUDIO` | `rikoo.settings` | `bool` | `true` |
| `MCP_HEALTH_ENABLED` | `rikoo.worker.settings` | `bool` | `true` |
| `MCP_HEALTH_DEFAULT_INTERVAL_S` | `rikoo.worker.settings` | `int` | `600` |
| `MCP_SCHEMA_DRIFT_POLICY` | `rikoo.worker.settings` | `nonempty` |  |
| `SANDBOX_ROOT` | a chart value | `path` | `/workspaces` |
| `SANDBOX_PORT` | a chart value | `int` |  |
| `SANDBOX_PLAYWRIGHT_URL` | a chart value | `http-url` |  |
| `SANDBOX_ROLE` | a chart value | `core \| egress` | `core` |
| `SANDBOX_EGRESS_BROWSER_HOST` | — | `host` |  |
| `SANDBOX_EGRESS_PROXY_HOST` | a chart value | `host` |  |
| `SANDBOX_EGRESS_PROXY_PORT` | a chart value | `int` | `8899` |
| `SANDBOX_SHELL_TIMEOUT_MS` | a chart value | `int` | `30000` |
| `SANDBOX_BACKEND` | `rikoo.worker.settings` | `bundle \| kubernetes` | `bundle` |
| `SANDBOX_WORKSPACE_IDLE_TTL_MS` | `rikoo.worker.settings` | `int` | `1800000` |
| `SANDBOX_BRIDGE_MAX_FILE_BYTES` | — | `int` | `104857600` |
| `SANDBOX_BRIDGE_MAX_TOTAL_BYTES` | — | `int` | `536870912` |
| `SANDBOX_BRIDGE_MAX_COLLECT_FILES` | — | `int` | `50` |
| `SANDBOX_BRIDGE_MAX_COLLECT_BYTES` | — | `int` | `209715200` |
| `SANDBOX_WALK_MAX_ENTRIES` | — | `int` | `50000` |
| `SANDBOX_WALK_MAX_DEPTH` | — | `int` | `64` |
| `SANDBOX_READ_MAX_CHARS` | — | `int` | `8000` |
| `SANDBOX_SHELL_MAX_OUTPUT_BYTES` | a chart value | `int` | `262144` |
| `SANDBOX_WORKSPACE_LEASE_TTL_MS` | — | `int` |  |
| `SANDBOX_IDLE_TTL_MS` | a chart value | `int` | `600000` |
| `SANDBOX_PYTHON_TIMEOUT_MS` | — | `int` | `120000` |
| `SANDBOX_EXEC_MAX_PROCESSES` | — | `int` | `256` |
| `SANDBOX_EXEC_MAX_ADDRESS_SPACE_BYTES` | — | `int` | `1073741824` |
| `SANDBOX_DISK_PER_CONVERSATION_BYTES` | — | `int` | `1073741824` |
| `RIKOO_EGRESS_ALLOW_CIDRS` | a chart value | `nonempty` |  |
| `RIKOO_EGRESS_DEV_ALLOWLIST` | a chart value | `nonempty` |  |
| `QDRANT_URL` | `rikoo.settings` | `http-url` |  |
| `QDRANT_COLLECTION` | `rikoo.settings` | `nonempty` |  |
| `QDRANT_VECTOR_SIZE` | `rikoo.settings` | `int` |  |
| `QDRANT_DISTANCE` | `rikoo.settings` | `nonempty` |  |
| `LOG_LEVEL` | a chart value | `fatal \| error \| warn \| info \| debug \| trace \| silent` | `info` |
| `LOG_FORMAT` | a chart value | `json \| pretty` | `json` |
| `LOG_SLOW_QUERY_MS` | a chart value | `int` | `200` |
| `AUDIT_RETENTION_DAYS` | `rikoo.worker.settings` | `int` |  |
| `AUDIT_PURGE_BATCH` | `rikoo.worker.settings` | `int` |  |
| `OTEL_SDK_DISABLED` | a chart value | `bool` |  |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | a chart value | `http-url` |  |
| `OTEL_EXPORTER_OTLP_ENDPOINT_API` | `rikoo.api.settings` | `http-url` |  |
| `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` | a chart value | `http-url` |  |
| `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT_API` | `rikoo.api.settings` | `http-url` |  |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | a chart value | `grpc \| http/protobuf \| http/json` |  |
| `OTEL_EXPORTER_OTLP_COMPRESSION` | a chart value | `nonempty` |  |
| `OTEL_EXPORTER_OTLP_TIMEOUT` | a chart value | `int` |  |
| `OTEL_EXPORTER_PROMETHEUS_PORT_API` | `rikoo.api.settings` | `int` | `9464` |
| `OTEL_METRICS_EXPORTER_API` | `rikoo.api.settings` | `nonempty` | `none` |
| `OTEL_SERVICE_NAME` | a chart value | `nonempty` | `rikoo-worker` |
| `OTEL_SERVICE_NAME_API` | `rikoo.api.settings` | `nonempty` | `rikoo-api` |
| `OTEL_RESOURCE_ATTRIBUTES` | a chart value | `nonempty` |  |
| `OTEL_TRACES_SAMPLER` | a chart value | `nonempty` |  |
| `OTEL_TRACES_SAMPLER_ARG` | a chart value | `nonempty` |  |
| `OTEL_LOG_LEVEL` | a chart value | `nonempty` |  |
| `OTEL_GENAI_CAPTURE_CONTENT` | `rikoo.worker.settings` | `bool` | `false` |
| `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` | a chart value | `bool` |  |
