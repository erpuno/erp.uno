{{/*
Expand the name of the chart.
*/}}
{{- define "erp-uno.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "erp-uno.fullname" -}}
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
{{- define "erp-uno.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "erp-uno.labels" -}}
helm.sh/chart: {{ include "erp-uno.chart" . }}
{{ include "erp-uno.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "erp-uno.selectorLabels" -}}
app.kubernetes.io/name: {{ include "erp-uno.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Service selector for a specific service
*/}}
{{- define "erp-uno.serviceSelectorLabels" -}}
app.kubernetes.io/name: {{ include "erp-uno.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
service: {{ .service }}
{{- end }}

{{/*
Resource requests/limits with defaults
*/}}
{{- define "erp-uno.resources" -}}
{{- $type := .type }}
{{- $resources := .resources }}
{{- if $resources }}
resources:
  {{- if $resources.requests }}
  requests:
    {{- if $resources.requests.cpu }}
    cpu: {{ $resources.requests.cpu }}
    {{- else if eq $type "stateless" }}
    cpu: {{ .defaults.stateless.requests.cpu }}
    {{- else }}
    cpu: {{ .defaults.stateful.requests.cpu }}
    {{- end }}
    {{- if $resources.requests.memory }}
    memory: {{ $resources.requests.memory }}
    {{- else if eq $type "stateless" }}
    memory: {{ .defaults.stateless.requests.memory }}
    {{- else }}
    memory: {{ .defaults.stateful.requests.memory }}
    {{- end }}
  {{- else if eq $type "stateless" }}
  requests:
    cpu: {{ .defaults.stateless.requests.cpu }}
    memory: {{ .defaults.stateless.requests.memory }}
  {{- else }}
  requests:
    cpu: {{ .defaults.stateful.requests.cpu }}
    memory: {{ .defaults.stateful.requests.memory }}
  {{- end }}
  {{- if $resources.limits }}
  limits:
    {{- if $resources.limits.cpu }}
    cpu: {{ $resources.limits.cpu }}
    {{- else if eq $type "stateless" }}
    cpu: {{ .defaults.stateless.limits.cpu }}
    {{- else }}
    cpu: {{ .defaults.stateful.limits.cpu }}
    {{- end }}
    {{- if $resources.limits.memory }}
    memory: {{ $resources.limits.memory }}
    {{- else if eq $type "stateless" }}
    memory: {{ .defaults.stateless.limits.memory }}
    {{- else }}
    memory: {{ .defaults.stateful.limits.memory }}
    {{- end }}
  {{- else if eq $type "stateless" }}
  limits:
    cpu: {{ .defaults.stateless.limits.cpu }}
    memory: {{ .defaults.stateless.limits.memory }}
  {{- else }}
  limits:
    cpu: {{ .defaults.stateful.limits.cpu }}
    memory: {{ .defaults.stateful.limits.memory }}
  {{- end }}
{{- else if eq $type "stateless" }}
resources:
  requests:
    cpu: {{ .defaults.stateless.requests.cpu }}
    memory: {{ .defaults.stateless.requests.memory }}
  limits:
    cpu: {{ .defaults.stateless.limits.cpu }}
    memory: {{ .defaults.stateless.limits.memory }}
{{- else }}
resources:
  requests:
    cpu: {{ .defaults.stateful.requests.cpu }}
    memory: {{ .defaults.stateful.requests.memory }}
  limits:
    cpu: {{ .defaults.stateful.limits.cpu }}
    memory: {{ .defaults.stateful.limits.memory }}
{{- end }}
{{- end }}
