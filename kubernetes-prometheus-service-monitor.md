
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