# apt.source

## Description

Manage /etc/apt/sources.list.d entries.

## Parameters

* state: The state of the resource. Required. Default: present.
* name: The name of the apt repo. Required.
* uri: The URI of the apt repo. Required.
* distribution: The distribution of the apt repo. Required.
* component: The component of the apt repo. Optional.
* include_src: Whether to include the source repo. Default: false.
* refresh: run apt-get update if the source was modified. Default: true.

## Example

```shell
apt.source --name lxc --uri http://ppa.launchpad.net/ubuntu-lxc/stable/ubuntu \
                  --distribution trusty --component main
```

