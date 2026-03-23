{{/*
Common labels - har template mein use hote hain
*/}}
{{- define "my-app.labels" -}}
app: {{ .Release.Name }}-my-app
chart: {{ .Chart.Name }}-{{ .Chart.Version }}
release: {{ .Release.Name }}
{{- end }}
