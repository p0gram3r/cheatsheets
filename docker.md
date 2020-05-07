### Images
```
# fetch images
docker pull %image_name%
docker pull %image_name%:%version%

# list images
docker images
docker image ls

# remove image
docker rmi %image_name%
```


### Containers
```
# list containers
docker container ls -a
docker ps -a

# quick start using random ports
docker run -d -P --name %ALIAS% %IMAGE_NAME%

# quick start with custom port forwarding
docker run -d -p 8080:80 --name %ALIAS% %IMAGE_NAME%

# stopping containers
docker stop %custom_container_name%
docker stop %containerID%

# removing containers
docker rm %containerID%

# remove all containers in status=EXIT
docker rm $(docker ps -a -q -f status=exited)
docker container prune
```

- other options to start a container
```
# starting a container
docker run %image_name$
docker run %image_name$ %command_to_execute%

# open interactive session in container
docker run -it %image_name% sh

# auto-remove container after it has been shut down
docker run --rm %image_name%

# assigning custom container name
docker run --name %custom_container_name% %image_name%

# forwarding to custom ports (8888 outside of container --> 80 in container)
docker run -p 8888:80 %image_name%

# forwarding container ports to random host ports. Use 'docker port %image_name%' to identify used ports
docker run -P %image_name%

# run container in background (detach from current session)
docker run -d %image_name%
```


### Creating custom images
```
# create an image using a Dockerfile
docker build -t p0gram3r/%image_name% .

# check result
docker images

# optional - only required if not already logged in
docker login

# upload to Docker hub
docker push p0gram3r/%image_name%
```


### Docker networks
```
# list networks
docker network ls

# inspect a network
docker network inspect %network_name%

# create a custom (bridge) network
docker network create %network_name%

# attach containers to custom network during startup
docker run --net %network_name% %image_name%
```


### Docker Compose
```
# start containers based on docker-compose.yml
docker-compose up -d

# start in detached mode
docker-compose up -d

# check running containers
docker-compose ps

# log into running container started by compose
docker-compose run %container_name_defined_in_compose.yml% bash

# destroy containers and volumes
docker-compose down -v
```


### Volumes
- https://docs.docker.com/storage/volumes/
- preferred mechanism for persisting data
- completely managed by Docker
- a volume does not increase the size of the containers using it
- the volume’s contents exist outside the lifecycle of a given container.

```
# create and remove volumes
docker volume create %volume_name%
docker volume rm %volume_name%

# list all existing volumes
docker volume ls

# inspect a volume
docker volume inspect %volume_name%

# run container with volume
docker run -d -p 8081:8081 -p 8082:8082 --name nexus -v nexus-data:/target/path/nexus-data sonatype/nexus3
```
