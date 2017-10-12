# Introduction

Our HA platform design relies on Atomic OS, which only contains bare minimum elements to run containers.

So how can we use git on this system, to push/pull the changes we make to config files? With a container, of course!

## git-docker

I [made a simple container](https://github.com/funkypenguin/git-docker/blob/master/Dockerfile) which just basically executes git in the CWD:

To use it transparently, add an alias for the "git" command, or just download it with the rest of the [handy aliases](https://raw.githubusercontent.com/funkypenguin/geek-cookbook/master/examples/scripts/gcb-aliases.sh):

```
alias git='docker run -v $PWD:/var/data -v \
/var/data/git-docker/data/.ssh:/root/.ssh funkypenguin/git-docker git'
```

## Setup SSH key

If you plan to actually _push_ using git, you'll need to setup an SSH keypair. You _could_ copy across whatever keypair you currently use, but it's probably more appropriate to generate a specific keypair for this purpose.

Generate your new SSH keypair by running:

```
mkdir -p /var/data/git-docker/data/.ssh
chmod 600 /var/data/git-docker/data/.ssh
docker run -v /var/data/git-docker/data/.ssh:/root/.ssh funkypenguin/git-docker ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519
```

The output will look something like this:
```
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
```

Now add the contents of /var/data/git-docker/data/.ssh/id_ed25519.pub to your git account, and off you go - just run "git" from your Atomic host as usual, and pretend that you have the client installed!
