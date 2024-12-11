{{/*
Expand the name of the chart.
*/}}
{{- define "phl-dev-svc-products.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "phl-dev-svc-products.fullname" -}}
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
{{- define "phl-dev-svc-products.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "phl-dev-svc-products.labels" -}}
helm.sh/chart: {{ include "phl-dev-svc-products.chart" . }}
{{ include "phl-dev-svc-products.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "phl-dev-svc-products.selectorLabels" -}}
app.kubernetes.io/name: {{ include "phl-dev-svc-products.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "phl-dev-svc-products.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "phl-dev-svc-products.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate a checksum for ConfigMap
*/}}
{{- define "phl-products.configmapHash" -}}
{{- toYaml .Values.appConfig | sha256sum }}
{{- end }}

{{/*
Generate a checksum for Secret
*/}}
{{- define "phl-products.secretHash" -}}
{{- toYaml .Values.appSecret.secrets | sha256sum }}
{{- end }}

{{/*
Combine both checksums
*/}}
{{- define "phl-products.configSecretChecksum" -}}
{{ include "phl-products.configmapHash" . }}-{{ include "phl-products.secretHash" . }}
{{- end }}