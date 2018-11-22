don't use special characetrs in your password


perl -pi -e "s/<termination (.*)>.*<\/termination>/<termination \1>${termination}<\/termination>/" /etc/loolwsd/loolwsd.xml

Cretaed /var/data/collabora/loolwsd.xml and bind-mounted it for editing ssl bool = false

docker-compose.yml

```
version: "3.0"

services:
  local-collabora:
    image: funkypenguin/collabora
    # the funkypenguin version has a patch to include "termination" behind SSL-terminating reverse proxy (traefik)
    #image: collabora/code
    env_file: /var/data/config/collabora/collabora.env
    volumes:
      - /var/data/collabora/loolwsd.xml:/etc/loolwsd/loolwsd.xml
    cap_add:
      - MKNOD
    ports:
      - 9980:9980
```

nginx.conf

```
upstream collabora-upstream {
    # Run collabora under docker-compose, since it needs MKNOD cap, which can't be provided by Docker
    server 172.17.0.1:9980;
}

server {
    listen 80;
    server_name collabora.observe.global;

    # static files
    location ^~ /loleaflet {
        proxy_pass http://collabora-upstream;
        proxy_set_header Host $http_host;
    }

    # WOPI discovery URL
    location ^~ /hosting/discovery {
        proxy_pass http://collabora-upstream;
        proxy_set_header Host $http_host;
    }

    # Main websocket
    location ~ /lool/(.*)/ws$ {
        proxy_pass http://collabora-upstream;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $http_host;
        proxy_read_timeout 36000s;
    }

    # Admin Console websocket
    location ^~ /lool/adminws {
	proxy_buffering off;
        proxy_pass http://collabora-upstream;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $http_host;
        proxy_read_timeout 36000s;
    }

    # download, presentation and image upload
    location ~ /lool {
        proxy_pass https://collabora-upstream;
        proxy_set_header Host $http_host;
    }
}
```

collabora.yml
```
version: "3.0"

services:

  nginx:
    image: nginx:latest
    networks:
      - traefik_public
    deploy:
      labels:
        - traefik.frontend.rule=Host:collabora.observe.global
        - traefik.docker.network=traefik_public
        - traefik.port=80
        - traefik.frontend.passHostHeader=true
    volumes:
      - /var/data/collabora/nginx.conf:/etc/nginx/conf.d/default.conf:ro

networks:
  traefik_public:
    external: true
```
