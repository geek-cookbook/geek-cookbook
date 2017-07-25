# Introduction

Our HA platform design relies on Atomic OS, which only contains bare minimum elements to run containers.

So how can we use git on this system, to push/pull the changes we make to config files?

docker run -v /var/data/git-docker/data:/root funkypenguin/git-docker ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519
Generating public/private ed25519 key pair.
Enter passphrase (empty for no passphrase): Enter same passphrase again: Created directory '/root/.ssh'.
Your identification has been saved in /root/.ssh/id_ed25519.
Your public key has been saved in /root/.ssh/id_ed25519.pub.
The key fingerprint is:
SHA256:uZtriS7ypx7Q4kr+w++nHhHpcRfpf5MhxP3Wpx3H3hk root@a230749d8d8a
The key's randomart image is:
+--[ED25519 256]--+
|         .o .    |
|      .  ..o .   |
|     + ....   ...|
|   .. + .o . . E=|
|  o .o  S . . ++B|
| . o  .  . . +..+|
| .o .. ...  . .  |
|o..o..+.oo       |
|...=OX+.+.       |
+----[SHA256]-----+
[root@ds3 data]#


alias git='docker run -v $PWD:/var/data -v /var/data/git-docker/data:/root funkypenguin/git-docker git'
