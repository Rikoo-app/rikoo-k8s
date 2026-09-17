{{/*
Expand the name of the chart.
*/}}
{{- define "rikoo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "rikoo.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "rikoo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Registry and tag of the Rikoo images. Both are required: an image without a version is a
mistake, and the registry depends on where the release pipeline publishes.
*/}}
{{- define "rikoo.image.tag" -}}
{{- if not .Values.rikoo.image.tag -}}
{{- fail "rikoo.image.tag is required: the release tag of the Rikoo images, for example v1.2.3" -}}
{{- end -}}
{{- .Values.rikoo.image.tag -}}
{{- end }}

{{/*
Common labels
*/}}
{{- define "rikoo.labels" -}}
helm.sh/chart: {{ include "rikoo.chart" . }}
{{ include "rikoo.selectorLabels" . }}
app.kubernetes.io/version: {{ include "rikoo.image.tag" . | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: rikoo
{{- end }}

{{/*
Selector labels
*/}}
{{- define "rikoo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rikoo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "rikoo.serviceAccountName" -}}
{{- if .Values.rikoo.serviceAccount.create }}
{{- default (include "rikoo.fullname" .) .Values.rikoo.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.rikoo.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Full image reference of a Rikoo component. Takes (dict "root" $ "component" .Values.rikoo.<c>).
*/}}
{{- define "rikoo.image" -}}
{{- $tag := coalesce .component.image.tag .root.Values.rikoo.image.tag -}}
{{- if not $tag -}}{{- $tag = include "rikoo.image.tag" .root -}}{{- end -}}
{{- printf "%s/%s:%s" .root.Values.rikoo.image.registry .component.image.repository $tag -}}
{{- end }}

{{/*
Version stamped on logs, spans and /api/v1/health: `rikoo.version` or the image tag.
*/}}
{{- define "rikoo.version" -}}
{{- .Values.rikoo.version | default (include "rikoo.image.tag" .) -}}
{{- end }}

{{/*
Fullname of an aliased sub-chart, computed the way the sub-chart's own fullname helper does
(groundhog2k/postgres, groundhog2k/redis and minio/minio share the standard pattern, with the
dependency alias as the chart name). This is what the sub-chart names its Service.
Takes (list $ "<alias>").
*/}}
{{- define "rikoo.subchart.fullname" -}}
{{- $ctx := index . 0 -}}
{{- $alias := index . 1 -}}
{{- $vals := index $ctx.Values $alias -}}
{{- if $vals.fullnameOverride -}}
{{- $vals.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default $alias $vals.nameOverride -}}
{{- if contains $name $ctx.Release.Name -}}
{{- $ctx.Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" $ctx.Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Names of the chart-managed Secrets. The sub-charts read these names from plain values (Helm
cannot template sub-chart values), so the values keys are the single source of truth.
*/}}
{{- define "rikoo.postgresql.authSecretName" -}}
{{- .Values.postgresql.settings.existingSecret | default "rikoo-postgresql-auth" -}}
{{- end -}}

{{- define "rikoo.s3.authSecretName" -}}
{{- .Values.s3.existingSecret | default "rikoo-s3-auth" -}}
{{- end -}}

{{- define "rikoo.appSecretName" -}}
{{- printf "%s-app" (include "rikoo.fullname" .) -}}
{{- end -}}

{{- define "rikoo.sealingSecretName" -}}
{{- .Values.rikoo.secrets.sealing.existingSecret | default (printf "%s-sealing" (include "rikoo.fullname" .)) -}}
{{- end -}}

{{/*
Hostnames of the stores.
*/}}
{{- define "rikoo.postgresql.hostname" -}}
{{- if .Values.postgresql.host }}
{{- .Values.postgresql.host }}
{{- else if .Values.postgresql.deploy }}
{{- include "rikoo.subchart.fullname" (list . "postgresql") -}}
{{- end }}
{{- end }}

{{- define "rikoo.redis.hostname" -}}
{{- if .Values.redis.host }}
{{- .Values.redis.host }}
{{- else if .Values.redis.deploy }}
{{- include "rikoo.subchart.fullname" (list . "redis") -}}
{{- end }}
{{- end }}

{{- define "rikoo.s3.endpoint" -}}
{{- if .Values.s3.endpoint }}
{{- .Values.s3.endpoint }}
{{- else if .Values.s3.deploy }}
{{- printf "http://%s:%v" (include "rikoo.subchart.fullname" (list . "s3")) .Values.s3.service.port -}}
{{- end }}
{{- end }}

{{/*
Component service names (one place, read by the env helpers and the NetworkPolicies).
*/}}
{{- define "rikoo.api.serviceName" -}}
{{- printf "%s-api" (include "rikoo.fullname" .) -}}
{{- end -}}
{{- define "rikoo.worker.serviceName" -}}
{{- printf "%s-worker" (include "rikoo.fullname" .) -}}
{{- end -}}
{{- define "rikoo.sidecar.serviceName" -}}
{{- printf "%s-sidecar-parsing" (include "rikoo.fullname" .) -}}
{{- end -}}
{{- define "rikoo.sandbox.serviceName" -}}
{{- printf "%s-mcp-sandbox" (include "rikoo.fullname" .) -}}
{{- end -}}
{{- define "rikoo.sandbox.egressServiceName" -}}
{{- printf "%s-mcp-egress" (include "rikoo.fullname" .) -}}
{{- end -}}
{{- define "rikoo.sandbox.playwrightServiceName" -}}
{{- printf "%s-playwright-mcp" (include "rikoo.fullname" .) -}}
{{- end -}}

{{- define "rikoo.sidecar.url" -}}
{{- if .Values.rikoo.sidecarParsing.url -}}
{{- .Values.rikoo.sidecarParsing.url -}}
{{- else if .Values.rikoo.sidecarParsing.enabled -}}
{{- printf "http://%s:%v" (include "rikoo.sidecar.serviceName" .) .Values.rikoo.sidecarParsing.port -}}
{{- end -}}
{{- end -}}

{{- define "rikoo.sandbox.url" -}}
{{- if .Values.rikoo.sandbox.url -}}
{{- .Values.rikoo.sandbox.url -}}
{{- else if .Values.rikoo.sandbox.enabled -}}
{{- printf "http://%s:%v" (include "rikoo.sandbox.serviceName" .) .Values.rikoo.sandbox.core.port -}}
{{- end -}}
{{- end -}}

{{/*
Get a value from either a direct value or a secret reference, or nothing if neither is provided.
Takes (dict "key" "<values path>" "value" <{value, secretKeyRef}>).
*/}}
{{- define "rikoo.getValueOrSecret" -}}
{{- $ref := .value.secretKeyRef | default dict -}}
{{- if (and $ref.name $ref.key) -}}
{{- if .value.value -}}
{{- fail (printf ".value and .secretKeyRef are mutually exclusive for %s" .key) -}}
{{- end -}}
valueFrom:
  secretKeyRef:
    name: {{ $ref.name }}
    key: {{ $ref.key }}
{{- else if .value.value -}}
value: {{ .value.value | quote }}
{{- end -}}
{{- end -}}

{{/*
Whether a {value, secretKeyRef} entry carries something.
*/}}
{{- define "rikoo.isProvided" -}}
{{- $ref := .secretKeyRef | default dict -}}
{{- if or .value (and $ref.name $ref.key) -}}true{{- end -}}
{{- end -}}

{{/*
Resolve an app credential: explicit value / secretKeyRef, else the chart-managed `<release>-app` Secret.
Takes (dict "root" $ "key" "<values path>" "value" <entry> "secretKey" "<key in the app Secret>").
*/}}
{{- define "rikoo.getAppSecretValue" -}}
{{- $resolved := include "rikoo.getValueOrSecret" (dict "key" .key "value" .value) -}}
{{- if $resolved -}}
{{- $resolved -}}
{{- else -}}
valueFrom:
  secretKeyRef:
    name: {{ include "rikoo.appSecretName" .root }}
    key: {{ .secretKey | quote }}
{{- end -}}
{{- end -}}

{{/*
Get value of a specific environment variable from a list if it exists
*/}}
{{- define "rikoo.getEnvVar" -}}
{{- $envVarName := .name -}}
{{- range .env -}}
{{- if eq .name $envVarName -}}
{{ .value }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Feature flags: RIKOO_FEATURE_<KEY> = on|off, absent = the product's own default.
*/}}
{{- define "rikoo.featureEnv" -}}
{{- range $key, $val := .Values.rikoo.features }}
{{- if not (kindIs "invalid" $val) }}
- name: RIKOO_FEATURE_{{ $key | snakecase | upper }}
  value: {{ ternary "on" "off" (eq (toString $val) "true") | quote }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
PostgreSQL connection (DATABASE_URL, APP_DATABASE_URL). Takes (dict "root" $ "pool" <int|nil>).
The password travels through its own variable and is expanded by Kubernetes (`$(VAR)`), so the
URL itself never holds a literal secret in the manifest.
*/}}
{{- define "rikoo.databaseEnv" -}}
{{- $root := .root -}}
{{- $pg := $root.Values.postgresql -}}
{{- $pool := .pool -}}
{{- if include "rikoo.isProvided" $pg.url }}
- name: DATABASE_URL
  {{- include "rikoo.getValueOrSecret" (dict "key" "postgresql.url" "value" $pg.url) | nindent 2 }}
{{- else }}
- name: RIKOO_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      {{- if $pg.auth.existingSecret }}
      name: {{ $pg.auth.existingSecret }}
      key: {{ required "postgresql.auth.existingSecretPasswordKey is required with postgresql.auth.existingSecret" $pg.auth.existingSecretPasswordKey }}
      {{- else if $pg.deploy }}
      name: {{ include "rikoo.postgresql.authSecretName" $root }}
      key: POSTGRES_PASSWORD
      {{- else }}
      name: {{ printf "%s-postgresql" (include "rikoo.fullname" $root) }}
      key: password
      {{- end }}
{{- $host := include "rikoo.postgresql.hostname" $root -}}
{{- $args := list -}}
{{- if $pg.connectionArgs -}}{{- $args = append $args $pg.connectionArgs -}}{{- end -}}
{{- if $pool -}}{{- $args = append $args (printf "connection_limit=%v" $pool) -}}{{- end -}}
{{- $query := "" -}}
{{- if $args -}}{{- $query = printf "?%s" (join "&" $args) -}}{{- end }}
- name: DATABASE_URL
  value: {{ printf "postgresql://%s:$(RIKOO_DB_PASSWORD)@%s:%v/%s%s" $pg.auth.username $host $pg.port $pg.auth.database $query | quote }}
{{- end }}
{{- if include "rikoo.isProvided" $pg.appUrl }}
- name: APP_DATABASE_URL
  {{- include "rikoo.getValueOrSecret" (dict "key" "postgresql.appUrl" "value" $pg.appUrl) | nindent 2 }}
{{- end }}
{{- end -}}

{{/*
Redis connection (REDIS_URL).
*/}}
{{- define "rikoo.redisEnv" -}}
{{- if include "rikoo.isProvided" .Values.redis.url }}
- name: REDIS_URL
  {{- include "rikoo.getValueOrSecret" (dict "key" "redis.url" "value" .Values.redis.url) | nindent 2 }}
{{- else }}
- name: REDIS_URL
  value: {{ printf "redis://%s:%v/%v" (include "rikoo.redis.hostname" .) .Values.redis.port .Values.redis.database | quote }}
{{- end }}
{{- end -}}

{{/*
Object storage (S3_*), shared by api and worker. The api signs URLs, the worker moves objects.
*/}}
{{- define "rikoo.s3Env" }}
- name: S3_ENDPOINT
  value: {{ required "s3.endpoint is required when s3.deploy is false" (include "rikoo.s3.endpoint" .) | quote }}
- name: S3_BUCKET
  value: {{ .Values.s3.bucket | quote }}
- name: S3_REGION
  value: {{ .Values.s3.region | quote }}
- name: S3_FORCE_PATH_STYLE
  value: {{ .Values.s3.forcePathStyle | quote }}
{{- if .Values.s3.deploy }}
- name: S3_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "rikoo.s3.authSecretName" . }}
      key: rootUser
- name: S3_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "rikoo.s3.authSecretName" . }}
      key: rootPassword
{{- else }}
- name: S3_ACCESS_KEY_ID
  {{- include "rikoo.getValueOrSecret" (dict "key" "s3.accessKeyId" "value" .Values.s3.accessKeyId) | nindent 2 }}
- name: S3_SECRET_ACCESS_KEY
  {{- include "rikoo.getValueOrSecret" (dict "key" "s3.secretAccessKey" "value" .Values.s3.secretAccessKey) | nindent 2 }}
{{- end }}
{{- with .Values.s3.uploadUrlTtlSec }}
- name: S3_UPLOAD_URL_TTL_SEC
  value: {{ . | quote }}
{{- end }}
{{- end -}}

{{/*
OTEL variables common to api and worker (the endpoints differ per service, see the component env).
*/}}
{{- define "rikoo.otelCommonEnv" -}}
{{- $o := .Values.rikoo.otel -}}
{{- with $o.protocol }}
- name: OTEL_EXPORTER_OTLP_PROTOCOL
  value: {{ . | quote }}
{{- end }}
{{- with $o.compression }}
- name: OTEL_EXPORTER_OTLP_COMPRESSION
  value: {{ . | quote }}
{{- end }}
{{- with $o.timeout }}
- name: OTEL_EXPORTER_OTLP_TIMEOUT
  value: {{ . | quote }}
{{- end }}
{{- with $o.sampler }}
- name: OTEL_TRACES_SAMPLER
  value: {{ . | quote }}
{{- end }}
{{- with $o.samplerArg }}
- name: OTEL_TRACES_SAMPLER_ARG
  value: {{ . | quote }}
{{- end }}
{{- with $o.sdkDisabled }}
- name: OTEL_SDK_DISABLED
  value: {{ . | quote }}
{{- end }}
{{- with $o.logLevel }}
- name: OTEL_LOG_LEVEL
  value: {{ . | quote }}
{{- end }}
{{- with $o.resourceAttributes }}
- name: OTEL_RESOURCE_ATTRIBUTES
  value: {{ . | quote }}
{{- end }}
{{- end -}}

{{/*
Variables common to api and worker. Non-secret, static ones live in the ConfigMap (envFrom);
here: the ones that are computed, secret, or per-release.
*/}}
{{- define "rikoo.commonEnv" -}}
- name: NODE_ENV
  value: {{ .Values.rikoo.nodeEnv | quote }}
- name: RIKOO_VERSION
  value: {{ include "rikoo.version" . | quote }}
- name: WIDGET_SIGNING_KEY
  {{- include "rikoo.getAppSecretValue" (dict "root" . "key" "rikoo.secrets.widgetSigningKey" "value" .Values.rikoo.secrets.widgetSigningKey "secretKey" "widget-signing-key") | nindent 2 }}
{{- with (include "rikoo.getValueOrSecret" (dict "key" "rikoo.license.deploymentLicense" "value" .Values.rikoo.license.deploymentLicense)) }}
- name: RIKOO_DEPLOYMENT_LICENSE
  {{- . | nindent 2 }}
{{- end }}
{{- with (include "rikoo.getValueOrSecret" (dict "key" "rikoo.license.licenseKey" "value" .Values.rikoo.license.licenseKey)) }}
- name: RIKOO_LICENSE_KEY
  {{- . | nindent 2 }}
{{- end }}
{{ include "rikoo.featureEnv" . }}
{{ include "rikoo.redisEnv" . }}
{{ include "rikoo.s3Env" . }}
{{ include "rikoo.otelCommonEnv" . }}
{{- end -}}

{{/*
api-only variables.
*/}}
{{- define "rikoo.apiEnv" -}}
- name: PORT
  value: {{ .Values.rikoo.api.service.port | quote }}
{{- include "rikoo.databaseEnv" (dict "root" . "pool" nil) }}
- name: RIKOO_SECRETS_PUBLIC_KEY
  {{- $sealing := .Values.rikoo.secrets.sealing }}
  {{- if $sealing.existingSecret }}
  valueFrom:
    secretKeyRef:
      name: {{ $sealing.existingSecret }}
      key: {{ $sealing.existingSecretPublicKey | quote }}
  {{- else if $sealing.publicKey.value }}
  valueFrom:
    secretKeyRef:
      name: {{ include "rikoo.sealingSecretName" . }}
      key: sealing.pub
  {{- else }}
  {{- include "rikoo.getValueOrSecret" (dict "key" "rikoo.secrets.sealing.publicKey" "value" $sealing.publicKey) | nindent 2 }}
  {{- end }}
- name: RIKOO_TOTP_KEY
  {{- include "rikoo.getAppSecretValue" (dict "root" . "key" "rikoo.secrets.totpKey" "value" .Values.rikoo.secrets.totpKey "secretKey" "totp-key") | nindent 2 }}
- name: WIDGET_VISITOR_KEY
  {{- include "rikoo.getAppSecretValue" (dict "root" . "key" "rikoo.secrets.widgetVisitorKey" "value" .Values.rikoo.secrets.widgetVisitorKey "secretKey" "widget-visitor-key") | nindent 2 }}
{{- with .Values.s3.browserEndpoint }}
- name: S3_BROWSER_ENDPOINT
  value: {{ . | quote }}
{{- end }}
- name: OTEL_SERVICE_NAME
  value: "rikoo-api"
{{- with .Values.rikoo.otel.api.endpoint }}
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: {{ . | quote }}
{{- end }}
{{- with .Values.rikoo.otel.api.tracesEndpoint }}
- name: OTEL_EXPORTER_OTLP_TRACES_ENDPOINT
  value: {{ . | quote }}
{{- end }}
{{- with (include "rikoo.getValueOrSecret" (dict "key" "rikoo.otel.api.headers" "value" .Values.rikoo.otel.api.headers)) }}
- name: OTEL_EXPORTER_OTLP_HEADERS
  {{- . | nindent 2 }}
{{- end }}
- name: OTEL_METRICS_EXPORTER
  value: {{ .Values.rikoo.otel.api.metricsExporter | quote }}
- name: OTEL_EXPORTER_PROMETHEUS_PORT
  value: {{ .Values.rikoo.otel.api.prometheusPort | quote }}
{{- range $k, $v := .Values.rikoo.api.settings }}
- name: {{ $k }}
  value: {{ $v | quote }}
{{- end }}
{{- end -}}

{{/*
worker-only variables.
*/}}
{{- define "rikoo.workerEnv" -}}
- name: WORKER_HEALTH_PORT
  value: {{ .Values.rikoo.worker.healthPort | quote }}
{{- include "rikoo.databaseEnv" (dict "root" . "pool" .Values.rikoo.worker.dbPool) }}
- name: RUN_CONCURRENCY
  value: {{ .Values.rikoo.worker.runConcurrency | quote }}
- name: RIKOO_SECRETS_PRIVATE_KEY_FILE
  value: {{ include "rikoo.sealing.privateKeyPath" . | quote }}
{{- with (include "rikoo.sealing.previousKeyPath" .) }}
- name: RIKOO_SECRETS_PRIVATE_KEYS_PREVIOUS_FILE
  value: {{ . | quote }}
{{- end }}
- name: MCP_SANDBOX_TOKEN_SECRET
  {{- include "rikoo.getAppSecretValue" (dict "root" . "key" "rikoo.secrets.sandboxTokenSecret" "value" .Values.rikoo.secrets.sandboxTokenSecret "secretKey" "sandbox-token-secret") | nindent 2 }}
{{- with (include "rikoo.sandbox.url" .) }}
- name: MCP_SANDBOX_URL
  value: {{ . | quote }}
{{- end }}
{{- with (include "rikoo.sidecar.url" .) }}
- name: RAG_SIDECAR_URL
  value: {{ . | quote }}
{{- end }}
{{- with (include "rikoo.getValueOrSecret" (dict "key" "rikoo.smtp.url" "value" .Values.rikoo.smtp.url)) }}
- name: SMTP_URL
  {{- . | nindent 2 }}
{{- end }}
{{- with .Values.rikoo.smtp.from }}
- name: EMAIL_FROM
  value: {{ . | quote }}
{{- end }}
{{- with .Values.rikoo.smtp.cloudflare.accountId }}
- name: CLOUDFLARE_EMAIL_ACCOUNT_ID
  value: {{ . | quote }}
{{- end }}
{{- with (include "rikoo.getValueOrSecret" (dict "key" "rikoo.smtp.cloudflare.apiToken" "value" .Values.rikoo.smtp.cloudflare.apiToken)) }}
- name: CLOUDFLARE_EMAIL_API_TOKEN
  {{- . | nindent 2 }}
{{- end }}
- name: OTEL_SERVICE_NAME
  value: "rikoo-worker"
{{- with .Values.rikoo.otel.endpoint }}
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: {{ . | quote }}
{{- end }}
{{- with .Values.rikoo.otel.tracesEndpoint }}
- name: OTEL_EXPORTER_OTLP_TRACES_ENDPOINT
  value: {{ . | quote }}
{{- end }}
{{- with (include "rikoo.getValueOrSecret" (dict "key" "rikoo.otel.headers" "value" .Values.rikoo.otel.headers)) }}
- name: OTEL_EXPORTER_OTLP_HEADERS
  {{- . | nindent 2 }}
{{- end }}
- name: OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT
  value: {{ .Values.rikoo.otel.captureMessageContent | quote }}
{{- range $k, $v := .Values.rikoo.worker.settings }}
- name: {{ $k }}
  value: {{ $v | quote }}
{{- end }}
{{- end -}}

{{/*
Sealing key files in the worker. The Secret is mounted under /run/secrets/rikoo, read-only.
*/}}
{{- define "rikoo.sealing.mountPath" -}}/run/secrets/rikoo{{- end -}}

{{- define "rikoo.sealing.privateKeyPath" -}}
{{- $s := .Values.rikoo.secrets.sealing -}}
{{- if $s.existingSecret -}}
{{- printf "%s/%s" (include "rikoo.sealing.mountPath" .) $s.existingSecretPrivateKey -}}
{{- else -}}
{{- printf "%s/sealing.key" (include "rikoo.sealing.mountPath" .) -}}
{{- end -}}
{{- end -}}

{{- define "rikoo.sealing.previousKeyPath" -}}
{{- $s := .Values.rikoo.secrets.sealing -}}
{{- if $s.existingSecret -}}
{{- with $s.existingSecretPreviousKey -}}{{- printf "%s/%s" (include "rikoo.sealing.mountPath" $) . -}}{{- end -}}
{{- else if include "rikoo.isProvided" $s.previousPrivateKeys -}}
{{- printf "%s/sealing.previous.key" (include "rikoo.sealing.mountPath" .) -}}
{{- end -}}
{{- end -}}

{{/*
Volume carrying the sealing private key(s) into the worker. Three shapes, one mount:
 - existingSecret: the operator's Secret, mounted whole;
 - keys given by value: the chart-managed `<release>-sealing` Secret;
 - keys given by secretKeyRef: a projected volume mapping each referenced key to its file name.
*/}}
{{- define "rikoo.sealing.volume" -}}
{{- $s := .Values.rikoo.secrets.sealing -}}
{{- if $s.existingSecret }}
secret:
  secretName: {{ $s.existingSecret }}
  defaultMode: 0400
{{- else if $s.privateKey.value }}
secret:
  secretName: {{ include "rikoo.sealingSecretName" . }}
  defaultMode: 0400
{{- else }}
{{- $ref := $s.privateKey.secretKeyRef | default dict -}}
{{- if not (and $ref.name $ref.key) -}}
{{- fail "rikoo.secrets.sealing: the vault private key is required for the worker. Generate an RSA 3072 pair with OpenSSL, then set sealing.existingSecret or sealing.privateKey and sealing.publicKey (value or secretKeyRef)." -}}
{{- end }}
projected:
  defaultMode: 0400
  sources:
    - secret:
        name: {{ $ref.name }}
        items:
          - key: {{ $ref.key }}
            path: sealing.key
    {{- $prev := $s.previousPrivateKeys.secretKeyRef | default dict }}
    {{- if and $prev.name $prev.key }}
    - secret:
        name: {{ $prev.name }}
        items:
          - key: {{ $prev.key }}
            path: sealing.previous.key
    {{- end }}
{{- end }}
{{- end -}}

{{/*
Scheduling of a component pod: nodeSelector, affinity, tolerations, topology, priority, DNS.
Takes (dict "root" $ "pod" <component.pod>).
*/}}
{{- define "rikoo.scheduling" -}}
{{- $g := .root.Values.rikoo -}}
{{- with (coalesce .pod.nodeSelector $g.nodeSelector) }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with (coalesce .pod.affinity $g.affinity) }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with (coalesce .pod.tolerations $g.tolerations) }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with (coalesce .pod.topologySpreadConstraints $g.pod.topologySpreadConstraints) }}
topologySpreadConstraints:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with (coalesce .pod.priorityClassName $g.priorityClassName) }}
priorityClassName: {{ . | quote }}
{{- end }}
{{- with $g.dnsConfig }}
dnsConfig:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}

{{/*
Pod annotations of a component: the global ones, the component ones, and a checksum of the shared
ConfigMap so that a configuration change rolls the pods. Takes (dict "root" $ "pod" <component.pod>).
*/}}
{{- define "rikoo.podAnnotations" -}}
{{- $ann := merge (.pod.annotations | default dict) (.root.Values.rikoo.pod.annotations | default dict) -}}
{{- $_ := set $ann "checksum/config" (include "rikoo.configChecksum" .root) -}}
{{- toYaml $ann -}}
{{- end -}}

{{/*
Checksum of what feeds the shared ConfigMap, computed from the values (not from the rendered
template, which a partial render such as helm-unittest cannot resolve).
*/}}
{{- define "rikoo.configChecksum" -}}
{{- $r := .Values.rikoo -}}
{{- dict "publicUrl" $r.publicUrl "corsOrigins" $r.corsOrigins "trustProxyHops" $r.trustProxyHops "logging" $r.logging "locale" $r.locale "signupMode" $r.signupMode "sessionSecureCookies" $r.sessionSecureCookies "upgradeUrl" $r.license.upgradeUrl "egress" $r.egress "attachments" $r.attachments | toYaml | sha256sum -}}
{{- end -}}

{{/*
Image pull secrets of a component. Takes (dict "root" $ "component" <component>).
*/}}
{{- define "rikoo.pullSecrets" -}}
{{- with (.component.image.pullSecrets | default .root.Values.rikoo.image.pullSecrets) }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}
