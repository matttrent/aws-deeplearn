# AWS instance setup scripts

## Create a new AWS p2 instance

```
$ ./setup-p2.ssh deeplearn
```

This instance is based on the the Fast.ai AMIs.

1. Add the SSH configuration to your `~/.ssh/config`.
2. Source the environment variables in your environment.  In my case, move the file created to `~/dotfiles/aws-instance-vars` and ZSH will pick them up automatically.

## Instance setup

On the instance, to configure ZSH and my config:

```
$ git clone https://github.com/matttrent/aws-deeplearn.git
$ cd aws-deeplearn
$ bash setup-system.sh
```

Log out and log back in, then:

```
$ cd aws-deeplearn
$ bash setup-deeplearn.sh
```
