{{/*
Expand the name of the chart.
*/}}
{{- define "phl-profile.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "phl-profile.fullname" -}}
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
{{- define "phl-profile.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "phl-profile.labels" -}}
helm.sh/chart: {{ include "phl-profile.chart" . }}
{{ include "phl-profile.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "phl-profile.selectorLabels" -}}
app.kubernetes.io/name: {{ include "phl-profile.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "phl-profile.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "phl-profile.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate a checksum for ConfigMap
*/}}
{{- define "phl-profile.configmapHash" -}}
{{- toYaml .Values.appConfig | sha256sum }}
{{- end }}

{{/*
Generate a checksum for Secret
*/}}
{{- define "phl-profile.secretHash" -}}
{{- toYaml .Values.appSecret.secrets | sha256sum }}
{{- end }}

{{/*
Combine both checksums
*/}}
{{- define "phl-profile.configSecretChecksum" -}}
{{ include "phl-profile.configmapHash" . }}-{{ include "phl-profile.secretHash" . }}
{{- end }}