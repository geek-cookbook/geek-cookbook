# Troubleshooting

Having difficulty with a recipe? Here are some tips..

## Why is my stack not launching?

Run ```docker stack ps <stack name> --no-trunc``` for more details on why individual containers failed to launching

## Attaching to running container

Need to debug **why** your oauth2_proxy container can't talk to its upstream app? Start by identifying which node the proxy container is running on, using ```docker ps <stack name>```.

SSH to the host node, and attach to the container using ```docker exec -it <continer id> /bin/bash``` (_substitute ```/bin/ash``` for ```/bin/bash```, in the case of an Alpine container_), and then try to telnet to your upstream host.

## Watching logs of container

Need to see what a particular container is doing? Run ```docker service logs -f <stack name>_<container name>``` to watch a particular service. As the service dies and is recreated, the logs will continue to be displayed.


## Chef's Notes

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
