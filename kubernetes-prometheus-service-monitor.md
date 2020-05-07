
step 1: Define ServiceMonitor
```
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: kube-varnish
  namespace: varnish
spec:
  endpoints:
  - interval: 10s
    port: metrics
    scheme: http
  selector:
    matchLabels:
      (key): (value)
```

step 2: Expose port in Service definition
```
ports:
- name: metrics
  port: 9131
  targetPort: metrics
  protocol: TCP
```

step 3. Remember to define port in Pod definition:
```
containers:
- name: ...
  image: ...
  imagePullPolicy: ...
  ports:
    - name: monitoring
      containerPort: 9131
      protocol: TCP
```

# Prometheus Object

### serviceMonitorNamespaceSelector
- By default, the Prometheus Operator only scans the namespace of the Prometheus CRD for ServiceMonitors
- to scan other namespaces: set `serviceMonitorNamespaceSelector` field
- The value must be of type `k8s.io/apimachinery/pkg/apis/meta/v1.LabelSelector`:
  ```
  serviceMonitorNamespaceSelector:
    matchLabels:
      prometheus: front-end-team
  ```


- add this label to each namespace that you want to scan for ServiceMonitors (e.g. prometheus: front-end-team) for a particular Prometheus (e.g. the front-end-team Prometheus)
  ```
  metadata:
    labels:
      prometheus: front-end-team
  ```


# ServiceMonitor
- https://github.com/coreos/prometheus-operator/blob/master/Documentation/design.md#servicemonitor
- name shown in UI = default/app-foo/0
  - default = namespace of the SM
  - app-foo = name of the SM

### monitoring service in other namespace
```
spec:
  namespaceSelector:
    matchNames:
    - foo
```
