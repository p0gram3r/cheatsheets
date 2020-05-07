### Waiting for some other container

```
initContainers:
  - name: {{.Chart.Name}}-wait-for-arango
    image: byrnedo/alpine-curl:0.1.8
    command: ['sh', '-c', 'code="0"; while [[ $code != "200" && $code != "301" ]]; do echo "not ready, current status code $code waiting for 200 or 301"; code="$(curl --insecure -s -o /dev/null -w ''%{http_code}'' http://hugo-plus-arango:8529)"; sleep 5; done']

```