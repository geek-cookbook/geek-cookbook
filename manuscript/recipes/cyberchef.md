# CyberChef

Are you a [l33t h@x0r](https://en.wikipedia.org/wiki/Hackers_(film))? Do you need the right tools at your fingertips to support your [#masterhacker](https://reddit.com/r/masterhacker) skillz? Look no further than CyberChef, lovingly baked for you by your friends at GHCQ[^1]!

[^1]: [Government Communications Headquarters](https://en.wikipedia.org/wiki/GCHQ), commonly known as GCHQ, is an intelligence and security organisation responsible for providing signals intelligence and information assurance to the government and armed forces of the United Kingdom

![CyberChef Screenshot](../images/cyberchef.png)

[CyberChef](https://github.com/gchq/CyberChef) is a simple, intuitive web app for carrying out all manner of "cyber" operations within a web browser. These operations include simple encoding like XOR or Base64, more complex encryption like AES, DES and Blowfish, creating binary and hexdumps, compression and decompression of data, calculating hashes and checksums, IPv6 and X.509 parsing, changing character encodings, and much more.

Here are some examples of fancy hax0r tricks you can do with CyberChef:

 - [Decode a Base64-encoded string][2]
 - [Decrypt and disassemble shellcode][6]
 - [Perform AES decryption, extracting the IV from the beginning of the cipher stream][10]
 - [Automagically detect several layers of nested encoding][12]

Here's a [live demo](https://gchq.github.io/CyberChef)!

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup Docker Swarm

CyberChef doesn't require any persistent storage, or fancy configuration, so simply create a docker swarm config file in docker-compose syntax (v3), something like this:

--8<-- "premix-cta.md"

```yaml
version: "3.2" # https://docs.docker.com/compose/compose-file/compose-versioning/#version-3

services:
  cyberchef:
    image: mpepping/cyberchef
    deploy:
      labels:
        # traefik
        - traefik.enable=true
        - traefik.docker.network=traefik_public

        # traefikv1
        - traefik.frontend.rule=Host:cyberchef.example.com
        - traefik.port=8000     

        # traefikv2
        - "traefik.http.routers.cyberchef.rule=Host(`cyberchef.example.com`)"
        - "traefik.http.routers.cyberchef.entrypoints=https"
        - "traefik.http.services.cyberchef.loadbalancer.server.port=8000"           
    networks:
      - traefik_public

networks:
  traefik_public:
    external: true
```

## Serving

### Cyber the Chef!

Launch your CyberChef stack by running ```docker stack deploy cyberchef -c <path -to-docker-compose.yml>```, and then visit the URL you chose to begin the hackery!

--8<-- "recipe-footer.md"

  [2]: https://gchq.github.io/CyberChef/#recipe=From_Base64('A-Za-z0-9%2B/%3D',true)&input=VTI4Z2JHOXVaeUJoYm1RZ2RHaGhibXR6SUdadmNpQmhiR3dnZEdobElHWnBjMmd1
  [6]: https://gchq.github.io/CyberChef/#recipe=RC4(%7B'option':'UTF8','string':'secret'%7D,'Hex','Hex')Disassemble_x86('64','Full%20x86%20architecture',16,0,true,true)&input=MjFkZGQyNTQwMTYwZWU2NWZlMDc3NzEwM2YyYTM5ZmJlNWJjYjZhYTBhYWJkNDE0ZjkwYzZjYWY1MzEyNzU0YWY3NzRiNzZiM2JiY2QxOTNjYjNkZGZkYmM1YTI2NTMzYTY4NmI1OWI4ZmVkNGQzODBkNDc0NDIwMWFlYzIwNDA1MDcxMzhlMmZlMmIzOTUwNDQ2ZGIzMWQyYmM2MjliZTRkM2YyZWIwMDQzYzI5M2Q3YTVkMjk2MmMwMGZlNmRhMzAwNzJkOGM1YTZiNGZlN2Q4NTlhMDQwZWVhZjI5OTczMzYzMDJmNWEwZWMxOQ
  [10]: https://gchq.github.io/CyberChef/#recipe=Register('(.%7B32%7D)',true,false)Drop_bytes(0,32,false)AES_Decrypt(%7B'option':'Hex','string':'1748e7179bd56570d51fa4ba287cc3e5'%7D,%7B'option':'Hex','string':'$R0'%7D,'CTR','Hex','Raw',%7B'option':'Hex','string':''%7D)&input=NTFlMjAxZDQ2MzY5OGVmNWY3MTdmNzFmNWI0NzEyYWYyMGJlNjc0YjNiZmY1M2QzODU0NjM5NmVlNjFkYWFjNDkwOGUzMTljYTNmY2Y3MDg5YmZiNmIzOGVhOTllNzgxZDI2ZTU3N2JhOWRkNmYzMTFhMzk0MjBiODk3OGU5MzAxNGIwNDJkNDQ3MjZjYWVkZjU0MzZlYWY2NTI0MjljMGRmOTRiNTIxNjc2YzdjMmNlODEyMDk3YzI3NzI3M2M3YzcyY2Q4OWFlYzhkOWZiNGEyNzU4NmNjZjZhYTBhZWUyMjRjMzRiYTNiZmRmN2FlYjFkZGQ0Nzc2MjJiOTFlNzJjOWU3MDlhYjYwZjhkYWY3MzFlYzBjYzg1Y2UwZjc0NmZmMTU1NGE1YTNlYzI5MWNhNDBmOWU2MjlhODcyNTkyZDk4OGZkZDgzNDUzNGFiYTc5YzFhZDE2NzY3NjlhN2MwMTBiZjA0NzM5ZWNkYjY1ZDk1MzAyMzcxZDYyOWQ5ZTM3ZTdiNGEzNjFkYTQ2OGYxZWQ1MzU4OTIyZDJlYTc1MmRkMTFjMzY2ZjMwMTdiMTRhYTAxMWQyYWYwM2M0NGY5NTU3OTA5OGExNWUzY2Y5YjQ0ODZmOGZmZTljMjM5ZjM0ZGU3MTUxZjZjYTY1MDBmZTRiODUwYzNmMWMwMmU4MDFjYWYzYTI0NDY0NjE0ZTQyODAxNjE1YjhmZmFhMDdhYzgyNTE0OTNmZmRhN2RlNWRkZjMzNjg4ODBjMmI5NWIwMzBmNDFmOGYxNTA2NmFkZDA3MWE2NmNmNjBlNWY0NmYzYTIzMGQzOTdiNjUyOTYzYTIxYTUzZg
  [12]: https://gchq.github.io/CyberChef/#recipe=Magic(3,false,false)&input=V1VhZ3dzaWFlNm1QOGdOdENDTFVGcENwQ0IyNlJtQkRvREQ4UGFjZEFtekF6QlZqa0syUXN0RlhhS2hwQzZpVVM3UkhxWHJKdEZpc29SU2dvSjR3aGptMWFybTg2NHFhTnE0UmNmVW1MSHJjc0FhWmM1VFhDWWlmTmRnUzgzZ0RlZWpHWDQ2Z2FpTXl1QlY2RXNrSHQxc2NnSjg4eDJ0TlNvdFFEd2JHWTFtbUNvYjJBUkdGdkNLWU5xaU45aXBNcTFaVTFtZ2tkYk51R2NiNzZhUnRZV2hDR1VjOGc5M1VKdWRoYjhodHNoZVpud1RwZ3FoeDgzU1ZKU1pYTVhVakpUMnptcEM3dVhXdHVtcW9rYmRTaTg4WXRrV0RBYzFUb291aDJvSDRENGRkbU5LSldVRHBNd21uZ1VtSzE0eHdtb21jY1BRRTloTTE3MkFQblNxd3hkS1ExNzJSa2NBc3lzbm1qNWdHdFJtVk5OaDJzMzU5d3I2bVMyUVJQ