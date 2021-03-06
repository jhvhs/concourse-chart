{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "concourse.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified web node(s) name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "concourse.web.fullname" -}}
{{- $name := default "web" .Values.web.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified worker node(s) name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "concourse.worker.fullname" -}}
{{- $name := default "worker" .Values.worker.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified postgresql name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "concourse.postgresql.fullname" -}}
{{- $name := default "postgresql" .Values.postgresql.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "concourse.secret.required" -}}
{{- if .is }}
{{- required (printf "secrets.%s is required because secrets.create is true and %s is true" .key .is) (index .root.Values.secrets .key ) | b64enc | quote }}
{{- else -}}
{{- required (printf "secrets.%s is required because secrets.create is true and %s isn't true" .key .isnt) (index .root.Values.secrets .key ) | b64enc | quote }}
{{- end -}}
{{- end -}}

{{- define "concourse.namespacePrefix" -}}
{{- default (printf "%s-" .Release.Name ) .Values.concourse.web.kubernetes.namespacePrefix -}}
{{- end -}}

{{- define "concourse.are-there-additional-volumes.with-the-name.concourse-work-dir" }}
  {{- range .Values.worker.additionalVolumes }}
    {{- if .name | eq "concourse-work-dir" }}
      {{- .name }}
    {{- end }}
  {{- end }}
{{- end }}


{{/*
Creates the address of the TSA service.
*/}}
{{- define "concourse.web.tsa.address" -}}
{{- $port := .Values.concourse.web.tsa.bindPort -}}
{{ template "concourse.web.fullname" . }}:{{- print $port -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for deployment.
*/}}
{{- define "concourse.deployment.apiVersion" -}}
{{- if semverCompare "<1.9-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "extensions/v1beta1" -}}
{{- else -}}
{{- print "apps/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for statefulset.
*/}}
{{- define "concourse.statefulset.apiVersion" -}}
{{- if semverCompare "<1.9-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "apps/v1beta2" -}}
{{- else -}}
{{- print "apps/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for ingress.
*/}}
{{- define "concourse.ingress.apiVersion" -}}
{{- if semverCompare "<1.14-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "extensions/v1beta1" -}}
{{- else -}}
{{- print "networking.k8s.io/v1beta1" -}}
{{- end -}}
{{- end -}}

{{/*
Create a registry image reference for use in a spec.
Includes the `image` and `imagePullPolicy` keys.
*/}}
{{- define "concourse.registryImage" -}}
image: {{ include "concourse.imageReference" . }}
{{- $pullPolicy := include "concourse.imagePullPolicy" . -}}
{{- if $pullPolicy }}
{{ $pullPolicy }}
{{- end -}}
{{- end -}}

{{/*
The most complete image reference, including the
registry address, repository, tag and digest when available.
*/}}
{{- define "concourse.imageReference" -}}
{{- if (or .values.image .values.imageTag .values.imageDigest) -}}
{{ include "concourse.deprecatedImageReference" . }}
{{- else -}}
{{ include "concourse.conventionalImageReference" . }}
{{- end -}}
{{- end -}}

{{- define "concourse.conventionalImageReference" -}}
{{ include "concourse.conventionalImagePath" . }}
{{- if .image.tag -}}
{{- printf ":%s" .image.tag -}}
{{- end -}}
{{- if .image.digest -}}
{{- printf "@%s" .image.digest -}}
{{- end -}}
{{- end -}}

{{- define "concourse.conventionalImagePath" -}}
{{- $registry := include "concourse.imageRegistry" . -}}
{{- $namespace := include "concourse.imageNamespace" . -}}
{{- printf "%s/%s/%s" $registry $namespace .image.name -}}
{{- end -}}

{{- define "concourse.deprecatedImageReference" -}}
{{- if (or .values.image .values.imageTag .values.imageDigest) -}}
{{- coalesce .values.image (include "concourse.conventionalImagePath" .) -}}
{{- $tag := coalesce .values.imageTag .image.tag -}}
{{- if $tag -}}
{{- printf ":%s" $tag -}}
{{- end -}}
{{- $digest := coalesce .values.imageDigest .image.digest -}}
{{- if $digest -}}
{{- printf "@%s" $digest -}}
{{- end -}}
{{- else -}}
{{- include "concourse.conventionalImageReference" . -}}
{{- end -}}
{{- end -}}


{{- define "concourse.imageRegistry" -}}
{{- if or (and .image.useOriginalRegistry (empty .image.registry)) (and .values.useOriginalRegistry (empty .values.imageRegistry)) -}}
{{- include "concourse.originalImageRegistry" . -}}
{{- else -}}
{{- include "concourse.customImageRegistry" . -}}
{{- end -}}
{{- end -}}

{{- define "concourse.originalImageRegistry" -}}
{{- printf (coalesce .image.originalRegistry .values.originalImageRegistry "docker.io") -}}
{{- end -}}

{{- define "concourse.customImageRegistry" -}}
{{- printf (coalesce .image.registry .values.imageRegistry .values.global.imageRegistry (include "concourse.originalImageRegistry" .)) -}}
{{- end -}}

{{- define "concourse.imageNamespace" -}}
{{- if or (and .image.useOriginalNamespace (empty .image.namespace)) (and .values.useOriginalNamespace (empty .values.imageNamespace)) -}}
{{- include "concourse.originalImageNamespace" . -}}
{{- else -}}
{{- include "concourse.customImageNamespace" . -}}
{{- end -}}
{{- end -}}

{{- define "concourse.originalImageNamespace" -}}
{{- printf (coalesce .image.originalNamespace .values.originalImageNamespace "library") -}}
{{- end -}}

{{- define "concourse.customImageNamespace" -}}
{{- printf (coalesce .image.namespace .values.imageNamespace .values.global.imageNamespace (include "concourse.originalImageNamespace" .)) -}}
{{- end -}}

{{/*
Specify the image pull policy
*/}}
{{- define "concourse.imagePullPolicy" -}}
{{- $policy := coalesce .values.imagePullPolicy .image.pullPolicy .values.global.imagePullPolicy -}}
{{- if $policy -}}
imagePullPolicy: "{{- $policy -}}"
{{- end -}}
{{- end -}}

{{/*
Use the image pull secrets. All of the specified secrets will be used
*/}}
{{- define "concourse.imagePullSecrets" -}}
{{- $secrets := .Values.global.imagePullSecrets -}}
{{- range $_, $chartSecret := .Values.imagePullSecrets -}}
{{- if $secrets -}}
{{- $secrets = append $secrets $chartSecret -}}
{{- else -}}
{{- $secrets = list $chartSecret -}}
{{- end -}}
{{- end -}}
{{- range $_, $image := .Values.images -}}
{{- range $_, $s := $image.pullSecrets -}}
{{- if $secrets -}}
{{- $secrets = append $secrets $s -}}
{{- else -}}
{{- $secrets = list $s -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- if $secrets }}
imagePullSecrets:
{{- range $secrets }}
- name: {{ . }}
{{- end }}
{{- end -}}
{{- end -}}
