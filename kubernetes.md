## definition files
- yaml format
- always contains 4 mandatory top level fields:
```
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app: myapp
spec:
  containers:
    - name: nginx-container
      image: nginx
```

## useful commands
```
# saves some typing :-)
alias k=kubectl
alias a='rm a && vi a'
alias c='kubectl create -f a'

# list all Pods/... and show status information
kubectl get (object-type)

# create a pod definition yaml based on running pod
kubectl get pod <pod-name> -o yaml > pod-definition.yaml

# create an object based on a definition yaml
kubectl create -f definition.yml

# create an object based on an image
# requires configured docker registry to download the images from
kubectl run nginx --image nginx                      ### Deployment
kubectl run nginx --image nginx --restart=Never      ### Pod
kubectl run nginx --image nginx --restart=OnFailure  ### job

# shows lots of information about an object
kubectl describe (object-type) (name_of_object)

# delete an object
kubectl delete (object-type) (name_of_object)

# edit an object
# may not be possible for all properties of the object!
kubectl edit (object-type) (name_of_object)

# get shell to container in pod
kubectl exec -it (name_of_container) -- /bin/bash

# read file inside container
kubectl exec (name_of_container) cat /log/app.log
```


## Shortcuts & Aliases
- po for Pods
- rs for ReplicaSets
- deploy for Deployments
- svc for Services
- netpol for Network Policies
- ns for Namespaces
- pv for Persistent Volumes
- pvc for Persistent Volumes Claims
- sa for service accounts


## Pods

- smallest unit that can be created and deployed
- wraps a single instance of a service or application
- contains one or more containers that are tightly coupled
- uses a Container runtime (e.g. Docker)


## ReplicaSets

#### Replication Controllers
- ensure number of running Pods is constant
- may span across multiple nodes in a cluster
- predecessor of ReplicaSets!
- A replication controller definition file must provide the number of replicas and a template of a Pod definition
  ```
  apiVersion: v1
  kind: ReplicationController
  metadata:
    name: myapp-rc
    labels:
      app: myapp
  spec:
    replicas: 3
    template:
      metadata:
        name: myapp-pod
        labels:
          app: myapp
          type: frontend
      spec:
        containers:
          - name: nginx-container
            image: nginx
  ```

- commands
  ```
  # create ReplicationController based on yaml
  kubectl create -f (rc-definition.yml)

  # list all replication controllers
  kubectl get replicationcontroller
  ```

- all Pods of a Replication Controller are automatically prefixed with the name of the the Replication Controller plus a random hash

#### ReplicaSets
- successor of Replication Controllers, slightly different definition format
  ```
  apiVersion: apps/v1
  kind: ReplicaSet
  metadata:
    name: myapp-replicaset
    labels:
      app: myapp
  spec:
    replicas: 3
    template:
      metadata:
        name: myapp-pod
        labels:
          app: myapp
          type: frontend
      spec:
        containers:
          - name: nginx-container
            image: nginx
    selector:
      matchLabels:
        type:  frontend
  ```

- note: ReplicaSets can also manage Pods not created as part of their definition (e.g. Pods that have existed before the creation of the ReplicaSet). That is why the selector is important!
- commands
  ```
  # create ReplicaSet based on yaml
  kubectl create -f (replicaset-definition.yml)

  # list all
  kubectl get replicaset
  kubectl get rs

  # get details
  kubectl describe (myapp-replicaset)

  # export replicaSet definition yaml
  kubectl get rs <myapp-replicaset> -o yaml > replicaset-definition.yaml

  # delete replicaset and all underlying Pods (!)
  kubectl delete rs (myapp-replicaset)
  ```

#### Scaling ReplicaSets
- Option 1: update definition file, e.g. `replicas: 6` instead of `3`, followed by
  ```
  kubectl replace -f (replicaset-definition.yml)
  ```

- Option 2: use `scale` command (does not modify the definition file)
  ```
  # scale via definition file name
  kubectl scale (replicaset-definition.yml) --replicas=6

  # scale via replicaSet name
  kubectl scale rs (myapp-replicaset) --replicas=6
  ```


## Deployments

- provide us with the capability to upgrade the underlying instances seamlessly
- requires a definition yaml with `kind: Deployment`:
  ```
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: blue
  spec:
    replicas: 6
    selector:
      matchLabels:
        type: b
    template:
      metadata:
        labels:
          type: b
      spec:
        containers:
        - name: nginx
          image: nginx
  ```

- to see all actions that have been executed as part of the deployment:
```
kubectl get all
```


## Namespaces

- default namespace = `Default`
- k8s reserved NS: `kube-system` and `kube-public`
- to access resources in a different namespace:
  ```
  mysql.connect("db-service.dev.svc.cluster-local")

  # db-service = service name
  # dev = namespace
  # svc = Service
  # cluster-local = domain
  ```

#### The --namespace option
```
# list Pods of a specific namespace:
kubectl get pods --namespace=(some_namespace)

# ... shorter version
kubectl get pods -n (some_namespace)

# list all Pods of all namespaces
kubectl get pods --all-namespaces
```

- can also be used in `create` commands
  - Alternative: provide `namespace` option in definition yaml under `metadata`

#### Creating a namespace
- via definition yaml:
  ```
  apiVersion: v1
  kind: Namespace
  metadata:
    name: dev
  ```

- via command:
  ```
  kubectl create namespace dev
  ```

#### Switching the currently active namespace
```
kubectl config set-context $(kubectl config current-context) --namespace=(namespace-to-switch-to)
```

#### Resource Quotas
- used to limit resources for a specific namespace
- example:
  ```
  apiVersion: v1
  kind: ResourceQuota
  metadata:
    name: compute-Quotas
    namespace: dev
  spec:
    hard:
      pods: "10"
      requests.cpu: "4"
      requests.memory: 5G1
      limits.cpu: "10"
      limits.memory: 10G1

  ```


## Labels and Selectors

- labels are key-value entries under `metadata` in a definition file
- select on console:
  ```
  kubectl get pods --selector (labelKey=labelValue)
  ```

- in Selectors, simply repeat the label definition to match the target objects with the respective labels


## Rollout and Versioning

```
kubectl rollout status (name-of-deployment

kubectl rollout history (name-of-deployment)
```

- possible rollout strategies:
  - Recreate = destroy all instances simultaneously and create new ones
  - Rolling-Update = Default: shut down and re-create a few instances and repeat until finished
  - defined in `spec / strategy / type`
- applying changes to existing deployments:
  ```
  # using existing yaml
  kubectl apply -f deployment-definition.yml

  # change deployment directly
  kubectl set image (name-of-deployment) (container-name)=(image)
  ```

- Upgrades of Deployments result in a second ReplicaSet being created
  - after Pod of RS2 has been created, one of RS1 is shut down
  - number of affected Pods can be configured in `spec / strategy`
  - can be monitored via `kubectl get rs`
- to rollback a deployment:
  ```
  kubectl rollout undo (name-of-deployment)
  ```

- hint: the `kubectl run (name) --image=(image)` command creates a Deployment with a single pod


## Pod commands and arguments

#### Docker commands
- containers are not meant to host an OS
- instead, they execute a specified command. After this command is finished, the container is shut down
- example: ubuntu sleeper image
  ```
  FROM ubuntu

  ENTRYPOINT ["sleep"]

  CMD ["5"]
  ```

- usage: `docker run ubuntu-sleeper 10` to sleep 10 seconds after container start. If no time is specified, the default value `5` is used (as provided in `CMD` param)

#### Kubernetes commands
- additional parameters for the Docker run command is added to the `args` section under its container
- a different Docker entry point must be specified under `command`
- example
  ```
  apiVersion: v1
  kind: Pod
  metadata:
    name: ubuntu-sleeper-pod
  spec:
    containers:
      - name: ubuntu-sleeper
        image: ubuntu-sleeper
        command: ["sleep2.0"]
        args: ["arg1", "arg2", "arg3"]
  ```


## ENV variables
- use `env` property under `.spec.containers[*]`
- value is an array of entries containing `name` and `value` properties:
  ```
  spec:
    containers:
      - name: ...
        image: ...
        env:
          - name: APP_COLOR
            value: ...
  ```

#### ENV value types
- plain key value
  ```
  env:
    - name: APP_COLOR
      value: pink
  ```

#### Configuration Maps
- map of key/value pairs relevant for one or more Pods
- imperative creation:
  ```
  # directly via command
  kubectl create configmap (config-name) --from-literal=(key)=(value)

  # use existing file
  kubectl create configmap (config-name) --from-file=(path-to-file)
  ```

- declarative creation via separate definition file
  ```
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: app-config
  data:
    APP_COLOR: pink
    APP_MODE: prod
  ```

- reference in Pod definition:
  ```
  env:
    - name: ...
      valueFrom:
        - configMapRef:
           name: app-config
  ```
  or
  ```
  env:
    - name: ...
      valueFrom:
        - configMapKeyRef:
           name: app-config
           key: APP_MODE
  ```

#### Secrets
- similar to ConfigMaps, but values are encoded
- imperative creation:
  ```
  kubectl create secret generic (secret-name) --from-literal=(key)=(value)
  kubectl create secret generic (secret-name) --from-file=(path-to-file)
  ```

- declarative creation via separate definition file
  ```
  apiVersion: v1
  kind: Secret
  metadata:
    name: app-secret
  data:
    DB_PASSWORD: base64EncodedPassword
  ```

- values must be given as base64 encoded string!
  ```
  echo -n "secret" | base64
  echo -n "bXlzcWw=" | base64 --decode
  ```

- reference in Pod definition:
  ```
  envFrom:
    - secretRef:
       name: app-secret
  ```
  or
  ```
  env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: DB_PASSWORD
  ```

- secrets can be mounted as Volumes! For each key a separate file is created inside the Pod containing the value of the secret


## Security Contexts

#### Docker Security
- namespaces are used to separate all containers
- processes are actually executed on Docker host but with different PIDs
- by default container processes are run with root user
  - can be configured in Dockerfile, e.g.:
    ```
    FROM ubuntu
    USER 1337
    ```
  - the capabilities made available to the user can be configured

#### Kubernetes Security Context
- can be configured on container or Pod level
  - all settings on Pod level affect all Containers inside the Pod
  - settings of the Container overwrite settings of Pod
- note: `capabilities` are only supported on container level!
- definition either under `spec` (= Pod level) or under `containers`
  ```
  securityContext:
    runAsUser: 1337
    capabilities:
      add: ["MAC_ADMIN", "..."]
  ```


## Service Accounts

```
kubectl create serviceaccount (name-of-serviceaccount)
```

- during creation of a service account, a token is generated as well which must be used by other applications for authentication
- tokens are stored in secret objects. To view:
  ```
  kubectl describe secret (name-of-serviceaccount-token)
  ```

- if TPA is another k8s container, the secret can be mounted as Volume
  - the default service account ("default") is automatically mounted to every Pod
  - to disable: `automountServiceAccountToken: false`
- to specify a different service account:
  ```
  spec:
    serviceAccount: someOtherServiceAccount
  ```

- the SA of an existing Pod cannot be modified! The Pod must be deleted and re-created in order to change the SA
- if the Pod was created as part of a Deployment, the Deployment CAN be edited! A change to the service account will automatically re-create the Pod


## Resource Requirements

- k8s Scheduler decides which node a Pod goes to
  - if a node does not contain enough resources, the scheduler picks another one
  - if there are no sufficient resources on any of the nodes, the scheduler will hold back the deployment and put the Pod in "pending" state (e.g. insufficient cpu)
- Pod definition:
  ```
  spec:
    containers:
    - name: (...)
      image: (...)
      resources:
        requests:
          memory: "512Mi"
          cpu: 0.5
        limits:
          memory: "2Gi"
          cpu: 1
  ```

- CPU
  - limit default: 1
  - lowest value: 1m or 0.001
  - 1 CPU equals 1 AWS vCPU, 1 GCP Core, 1 Azure Core, 1 Hyperthread
  - exceeding the limit will cause CPU throttling
- Memory
  - limit default: 512 Mi
  - units as G, M, K or Gi, Mi, Ki
  - exceeding the limit will cause the container to be terminated (status: OOMKilled)


## Taints and Tolerations

- restrictions on which pods can be scheduled on which node
- default: balance equally on all available nodes
- Taints are set on Nodes:
```
kubectl taint node (node-name) key=value:taint-effect
```

- possible taint-effects:
  - NoSchedule = do not schedule pod on this node
  - PreferNoSchedule = tries to avoid scheduling on this node, but there is no guarantee that it won't happen
  - NoExecute = new pods will not be scheduled on this node and existing pods will be evicted if they do not tolerate this taint
- Tolerations are set on Pods
  ```
  spec:
    containers:
    - name: (...)
      image: (...)
    tolerations:
    - key: "app"
      operator: "Equal"
      value: "blue"
      effect: "NoSchedule"
  ```

- taints make sure that only Pods with certain Toleration are allowed on a node. However, the Pod might still be deployed on any other node
- k8s master node automatically has a taint that prevents any Pods from being scheduled on it


## Node Selector

- simple way to define which Pod should go to which node
- requires node to be labelled:
  ```
  kubectl label node (node-name) (label-key)=(label-value)

  # example
  kubectl label node node123 size=Large
  ```

- Pod definition:
  ```
  spec:
    containers:
      - name: (...)
    nodeSelector:
      size: Large
  ```

- only works for simple selectors, but not for advanced expressions like "Large OR Medium" or "NOT Small"


## Node Affinity

- more complex and more flexible than Node Selectors
- Pod definition:
  ```
  spec:
    containers:
      - name: (...)
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: size
              operator: In
              values:
              - Large
              - Medium
  ```


## Multi-Container Pods

- useful for services that share the same lifecycle (i.e. created and destroyed together, sharing the same network and storage volume)
- different design patterns:
  - sidecar = e.g. a simple log agent next to a web server
  - adapter = e.g. the log agents of different pods need to convert the format before sending data to the central server
  - ambassador = e.g. different connectors for each environment
- simply add another entry to the `spec / container` section of the Pod definition file


## Readiness & Liveness Probes

- Pod Status
  - high level information
  - Pending = Pod is about to being scheduled on a node
  - ContainerCreating = scheduling started
  - Running
- Pod Conditions
  - more fine granular
  - boolean properties
  - see `Conditions` when running `kubectl describe pod (pod-name)`

#### Readiness Probes
- is my application ready for usage?
- Kubernetes asumes that a container is immediately ready when its status is 'Running' --> might cause problems when traffic hits the container which is not ready yet
- to avoid this, add a readiness probe to the Pod definition:
  ```
  spec:
    Containers:
    - name: ...
      image: ...
      readinessProbe:
        httpGet:
          path: /api/ready
          port: 8080
        initialDelaySeconds
        periodSeconds: 5
        failureThreshold: 8
  ```

- other probes: `tcpSocket` for TCP tests and `exec` for executing commands

#### Liveness Probes
- is my application healthy?
- in Pod definition file:
  ```
  spec:
    Containers:
    - name: ...
      image: ...
      livenessProbe:
        httpGet:
          path: /api/healthy
          port: 8080
  ```


## Container Logging

- getting access to SysOut logging
  ```
  # single container pods
  kubectl logs -f (pod-name)

  # multi container pods
  kubectl logs -f (pod-name) (container-name)
  ```


## Monitoring a K8s cluster

- lverages tools like Metrics Server, Prometheus, ElasticStack, ...
- Metrics Server stores data in-memory only
- K8s runs an agent on each node called "Kubelet"
  - receives API commands from master node
  - contains a sub-component called cAdvisor which retrieves performance metrics from the Pods
- to setup Metrics Server:
  - minikube: `minikube addons enable metrics-server`
  - all other enviroments: `git clone http://github.com/kubernetes-incubator/metrics-server.git`
- to view performance metrics:
  ```
  kubectl top node
  kubectl top pod
  ```


## Jobs

- Recap: Docker containers are shut down when task is done
- K8s wants Pods to live forever and thus restarts a Pod when a container was shut down
  - this behaviour is defined under `spec / restartPolicy` which by default is set to `Always`
  - other possible values: `Never` and `OnFailure`
- K8s object `Job` is designed to run a number of Pods to complete a certain task
  ```
  apiVersion: batch/v1
  kind: Job
  metadata:
    name: math-ad-job
  spec:
    template:
      spec:
        restartPolicy: Never
        containers:
          - name: math-add
            image: ubuntu
            command: ['expr', '3', '+', '4']
  ```

- to view the result:
  ```
  kubectl get jobs
  # NAME             DESIRED   SUCCESSFUL   AGE
  # throw-dice-job   1         1            28s

  kubectl get pods
  # NAME                   READY     STATUS      RESTARTS   AGE
  # throw-dice-job-2n8s8   0/1       Completed   2          37s

  # access output of pod
  kubectl logs throw-dice-job-2n8s8
  ```

- by default only a single Pod is create. To setup more and let them run simultaneously:
  ```
  spec:
    completions: 4
    parallelism: 2
    template:
      (...)
  ```

- Note that even if you specify `.spec.parallelism = 1` and `.spec.completions = 1` and `.spec.template.spec.restartPolicy = "Never"`, the same program may sometimes be started twice! This may happen for a number of reasons, such as when the pod is kicked off the node (node is upgraded, rebooted, deleted, etc.)
- when a job is completed, the respective Pods are not deleted

## CronJobs

```
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: reporting-cron-job
spec:
  schedule: "*/1 * * * *"
  jobTemplate:
    spec:
      (spec of a regular job)
      completions: ...
      parallelism: ...
      template: ...
```


## Services

- enable communication between various components inside and outside of an app
- Types:
  - NodePort = make an internal port accessible from a port of the node
  - ClusterIP = virtual IP for a group of Pods inside the cluster
  - LoadBalancer
- Node Port definition
  ```
  apiVersion: v1
  kind: Service
  metadata:
    name: myapp-service
  spec:
    type: NodePort
    ports:
      - targetPort: 80
        port: 80
        nodePort: 30008
    selector:
      (all labels describing the pod)
      app: myapp
      type: frontend
  ```

- only mandatory port = `port`
  - default of targetPort = value of port
  - default of nodePort = random value starting at 30000
- ClusterIP
  ```
  apiVersion: v1
  kind: Service
  metadata:
    name: backend
  spec:
    type: ClusterIP
    ports:
      - targetPort: 80
        port: 80
    selector:
      (all labels describing the pod)
  ```


## Ingress

- allows access to your application using a single externally accessible url
  - can be configured to route to different services within a cluster
  - handles SSL

#### step 1: setup the Ingress Controller
```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: ingress-controller
  namespace: ingress-space
spec:
  replicas: 1
  selector:
    matchLabels:
      name: nginx-ingress
  template:
    metadata:
      labels:
        name: nginx-ingress
    spec:
      serviceAccountName: ingress-serviceaccount
      containers:
        - name: nginx-ingress-controller
          image: quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.21.0
          args:
            - /nginx-ingress-controller
            - --configmap=$(POD_NAMESPACE)/nginx-configuration
            - --default-backend-service=app-space/default-http-backend
          env:
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          ports:
            - name: http
              containerPort: 80
            - name: https
              containerPort: 443
```

#### step 2: add a Service to make Ingress accessible
```
kubectl expose deployment ingress-controller --type NodePort --name=ingress --port=80 --namespace=ingress-space --dry-run -o yaml
```

#### step 3: create the load balancer configuration
```
kubectl create configmap nginx-configuration --namespace ingress-space
```

#### step 4: set permissions to access these objects
```
kubectl create serviceaccount ingress-serviceaccount --namespace ingress-space
```

- after that RoleBindings must be defined in this account!

#### step 5: assign paths to services
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress-wear
  namespace: app-space
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - http:
      paths:
      - path: /wear
        backend:
          serviceName: wear-service
          servicePort: 80
      - path: /watch
        backend:
          serviceName: video-service
          servicePort: 80
```


## Network Policies

- by default: all Pods are allowed to communicate with all other Pods inside the same cluster ("All Allow" rule)
- to prevent this for certain Pods: create a Network Policy
  ```
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: db-policy
  spec:
    podSelector:
      matchLabels:
        role: db
    policyTypes:
    - Ingress
    ingress:
    - from:
      - podSelector:
          matchLabels:
            name: api-pod
      ports:
      - protocol: TCP
        port: 3306
  ```

- Ingress = incoming traffic
- Egress = outgoing traffic (only actively sent, responses are not considered egress)


## Volumes

- example: Pod generates as random number and writes it to a file:
```
apiVersion: v1
kind: Pod
metadata:
  name: random-number-generator
spec:
  containers:
  - image: alpine
    name: alpine
    command: ["/bin/bash", "-c"]
    args: ["shuf -i 0-100 -n 1 >> /opt/number.out;"]
    volumeMounts:
    - mountPath: /opt
      name: data-volume
  volumes:
  - name: data-volume
    hostPath:
      path: /data
      type: Directory
```

- Note: volume type `Directory` only works fine for a single node environment. In a multi node cluster, use a different type like NFS, ClusterFS, Flocker, AWS, Azure, GCP...
  ```
  volumes:
  - name: data-volume
    awsElasticBlockStore:
      volumeId: (volumeId)
      fsType: ext4
  - name: persistent-volume
    persistentVolumeClaim:
      claimName: (myclaim)
  ```


## Persistent Volumes

- defining volume in Pod definition is cumbersome, especially when working in an environment with many pods. Instead use persistent volumes:
  ```
  apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: pv-vol1
  spec:
    accessModes:
      - ReadWriteOnce
    capacity:
      storage: 1Gi
    awsElasticBlockStore:
      volumeId: (volumeId)
      fsType: ext4
  ```

- to use a persistent volume, a PersistentVolumeClaim needs to be created:
  ```
  apiVersion: v1
  kind: PersistentVolumeClaim
  metadata:
    name: myclaim
  spec:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 500Mi
  ```

- claims are assigned to volumes when requirements match
  - matching can be made explicit by using labels and selectors
  - if claim requests less storage then volume offers, they will still be matched if no other volumes are available
  - if no volume matches the requirements, the claim remains in PENDING started
