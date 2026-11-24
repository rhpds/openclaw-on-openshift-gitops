{{/*
Helpers for the tenant chart.

These exist mostly to absorb the difference between what AgnosticV
passes (claws.namespace, tenant.name) and what the seat components were
written against (seat.namespace, seat.username), so neither side has to
be rewritten to match the other.
*/}}

{{- define "tenant.repoURL" -}}
{{- coalesce .Values.gitops.repoURL .Values.gitops.repoUrl -}}
{{- end -}}

{{- define "tenant.revision" -}}
{{- .Values.gitops.revision | default "main" -}}
{{- end -}}

{{/*
Prefix for the shared component charts, WITH a trailing slash when
non-empty and empty otherwise.

components/ sits at the REPO ROOT so the cluster and tenant charts can
share it. The usual `{{ basePath }}/components/x` would then render as
`/components/x`, a leading slash Argo should not be given, so the
separator travels with the prefix instead.
*/}}
{{- define "tenant.componentPath" -}}
{{- $b := .Values.gitops.basePath | default "" | trimSuffix "/" -}}
{{- if $b }}{{ $b }}/{{ end -}}
{{- end -}}

{{/*
The tenant's namespace.

claws.namespace is what the catalog item sets, and it is authoritative
because ocp4_workload_tenant_namespace has already created exactly that
namespace. seat.namespace is the by-hand override.
*/}}
{{- define "tenant.namespace" -}}
{{- if .Values.seat.namespace -}}
{{- .Values.seat.namespace -}}
{{- else if .Values.claws.namespace -}}
{{- .Values.claws.namespace -}}
{{- else -}}
{{- printf "user-%s-claws" (required "set tenant.name or claws.namespace" .Values.tenant.name) -}}
{{- end -}}
{{- end -}}

{{/*
The tenant's username.

Must match the Keycloak user the tenant item created, because the key
mint logs in as them. Getting this wrong does not fail loudly: the
mint hook refuses to fall back to its own ServiceAccount, so the
tenant is simply reported as skipped.
*/}}
{{- define "tenant.username" -}}
{{- if .Values.seat.username -}}
{{- .Values.seat.username -}}
{{- else if .Values.tenant.user.name -}}
{{- .Values.tenant.user.name -}}
{{- else -}}
{{- printf "user-%s" (required "set tenant.name or tenant.user.name" .Values.tenant.name) -}}
{{- end -}}
{{- end -}}

{{/*
The per-tenant part of the audience hostname.

Stable and short. Derived from the tenant name rather than a counter,
because tenants arrive one order at a time and there is no counter to
derive from.
*/}}
{{- define "tenant.userCode" -}}
{{- if .Values.seat.userCode -}}
{{- .Values.seat.userCode -}}
{{- else -}}
{{- printf "user%s" (.Values.tenant.name | default "0" | sha256sum | trunc 5) -}}
{{- end -}}
{{- end -}}

{{/*
The in-cluster MaaS gateway host.

Deliberately NOT the same thing as claws.models.url, which is an
upstream LiteMaaS endpoint when the catalog item injects one. Keeping
them separate is what lets a tenant fall back to upstream without the
rest of the chart pretending the gateway is there.
*/}}
{{- define "tenant.maasGatewayHost" -}}
{{- if .Values.maas.gatewayHost -}}
{{- .Values.maas.gatewayHost -}}
{{- else -}}
{{- printf "maas.%s" (required "set cluster.appsDomain or maas.gatewayHost" .Values.cluster.appsDomain) -}}
{{- end -}}
{{- end -}}

{{/*
What the seat uses as its OpenAI-compatible base URL.

An injected LiteMaaS endpoint wins, because if one was issued the
tenant is meant to use it. Otherwise the in-cluster gateway.
*/}}
{{- define "tenant.apiBase" -}}
{{- if .Values.claws.models.url -}}
{{- printf "%s/v1" (.Values.claws.models.url | trimSuffix "/" | trimSuffix "/v1") -}}
{{- else -}}
{{- printf "https://%s/v1" (include "tenant.maasGatewayHost" .) -}}
{{- end -}}
{{- end -}}

{{/*
Where this tenant posts traces. Derived, so it cannot name a collector
Service that the cluster chart did not create.
*/}}
{{- define "tenant.traceEndpoint" -}}
{{- printf "http://%s-collector.%s.svc.cluster.local:4318/v1/traces" .Values.tracing.collectorName .Values.tracing.namespace -}}
{{- end -}}

{{- define "tenant.labels" -}}
demo.redhat.com/application: "openclaw-on-openshift"
demo.redhat.com/tenant: {{ .Values.tenant.name | default "unset" | quote }}
{{- end -}}
