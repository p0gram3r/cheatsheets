### Creating Helm Charts
```
# Create a blank chart
helm create <chartname>

# Lint the chart
helm lint <chartname>

# Package the chart into <chartname>.tgz
helm package <chartname>

# Install chart dependencies
helm dependency update
```

### dry-run
```
helm template . -f values-abc.yaml | less

helm install --dry-run --debug <name> .
```

### using additional repositories
```
helm repo add oteemocharts https://oteemo.github.io/charts
helm install nexus oteemocharts/sonatype-nexus
```

### Defining secrets
```
apiVersion: v1
kind: Secret
metadata:
  name: my-fancy-secret
type: Opaque
data:
  username: {{ .Values.username | b64enc | quote }}
  password: {{ .Values.password | b64enc | quote }}
```
