# Troubleshooting

Having difficulty with a recipe? Here are some tips..

## Why is my stack not launching?

Run ```docker stack ps <stack name> --no-trunc``` for more details on why individual containers failed to launching

## Attaching to running container

Need to debug **why** your oauth2_proxy container can't talk to its upstream app? Start by identifying which node the proxy container is running on, using ```docker ps <stack name>```.

SSH to the host node, and attach to the container using ```docker exec -it <continer id> /bin/bash``` (_substitute ```/bin/ash``` for ```/bin/bash```, in the case of an Alpine container_), and then try to telnet to your upstream host.

## Watching logs of container

Need to see what a particular container is doing? Run ```docker service logs -f <stack name>_<container name>``` to watch a particular service. As the service dies and is recreated, the logs will continue to be displayed.

## Visually monitoring containers with ctop

For a visual "top-like" display of your container's activity (_as well as a [detailed per-container view](https://github.com/bcicen/ctop/blob/master/_docs/single.md)_), try using [ctop](https://github.com/bcicen/ctop).

To execute, simply run `docker run --rm -ti --name ctop -v /var/run/docker.sock:/var/run/docker.sock quay.io/vektorlab/ctop:latest`

Example:
![ctop screenshot](https://github.com/bcicen/ctop/raw/master/_docs/img/grid.gif)
