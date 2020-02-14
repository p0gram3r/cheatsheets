### Initializing Helm
In a newly created Kubernetes cluster, Helm might not have been fully initialized yet. To do this, run
```
helm init

# see https://github.com/helm/helm/issues/3055#issuecomment-356347732
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
```

### misc

helm template . -f values-abc.yaml | less

