# Introduction



````
mkdir ~/dockersock
cd ~/dockersock
curl -O https://raw.githubusercontent.com/dpw/selinux-dockersock/master/Makefile
curl -O https://raw.githubusercontent.com/dpw/selinux-dockersock/master/dockersock.te
make && semodule -i dockersock.pp
````
