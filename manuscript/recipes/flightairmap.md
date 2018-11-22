version: '3'
services:
  flightairmap:
    image: richarvey/nginx-php-fpm
    volumes:
        - "/var/data/flightairmap/conf:/var/www/html/conf"
        - "/var/data/flightairmap/scripts:/var/www/html/scripts"
        - "/var/data/flightairmap/html:/var/www/flightairmap/"
    env_file:
        - "/var/data/config/flightairmap/flightairmap.env"
    environment:
        - PHP_MEM_LIMIT=256
        - RUN_SCRIPTS=1
        - MYSQL_HOST=${MYSQL_HOST}
        - MYSQL_DATABASE=${MYSQL_DATABASE}
        - MYSQL_USER=${MYSQL_USER}
        - MYSQL_PASSWORD=${MYSQL_PASSWORD}
    networks:
        - internal
        - traefik_public
    deploy:
        labels:
          - traefik.frontend.rule=Host:www.observe.global
          - traefik.docker.network=traefik_public
          - traefik.port=80

  db:
    image: mariadb:10
    env_file: /var/data/config/flightairmap/flightairmap.env
    networks:
      - internal
    volumes:
      - /var/data/runtime/flightairmap/db:/var/lib/mysql

  db-backup:
    image: mariadb:10
    env_file: /var/data/config/flightairmap/flightairmap.env
    volumes:
      - /var/data/flightairmap/database-dump:/dump
    entrypoint: |
      bash -c 'bash -s <<EOF
      trap "break;exit" SIGHUP SIGINT SIGTERM
      sleep 2m
      while /bin/true; do
        mysqldump -h db --all-databases | gzip -c > /dump/dump_\`date +%d-%m-%Y"_"%H_%M_%S\`.sql.gz
        (ls -t /dump/dump*.sql.gz|head -n $$BACKUP_NUM_KEEP;ls /dump/dump*.sql.gz)|sort|uniq -u|xargs rm -- {}
        sleep $$BACKUP_FREQUENCY
      done
      EOF'
    networks:
    - internal

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.44.0/24
