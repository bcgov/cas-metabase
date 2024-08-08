{{/*
Expand the name of the chart.
*/}}
{{- define "cas-obps-postgres.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cas-obps-postgres.fullname" -}}
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
{{- define "cas-obps-postgres.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Gets the prefix of the namespace. (<openshift_nameplate>, ... )
*/}}
{{- define "cas-obps-postgres.namespacePrefix" }}
{{- (split "-" .Release.Namespace)._0 | trim -}}
{{- end }}

{{/*
Gets the suffix of the namespace. (-dev, -tools, ... )
*/}}
{{- define "cas-obps-postgres.namespaceSuffix" }}
{{- (split "-" .Release.Namespace)._1 | trim -}}
{{- end }}

{{/*
Create an app-name appended with environment. (app-name-dev, app-name-tools, ... )
*/}}
{{- define "cas-obps-postgres.nameWithEnvironment" }}
{{- printf "%s-%s" .Chart.Name  (split "-" .Release.Namespace)._1 }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cas-obps-postgres.labels" -}}
helm.sh/chart: {{ include "cas-obps-postgres.chart" . }}
{{ include "cas-obps-postgres.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cas-obps-postgres.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cas-obps-postgres.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "cas-obps-postgres.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "cas-obps-postgres.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

