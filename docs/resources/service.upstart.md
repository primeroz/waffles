# service.upstart

## Description

Manages upstart services

## Parameters

* state: The state of the service. Required. Default: running.
* name: The name of the service. Required. namevar.

## Example

```shell
service.upstart --name memcached
```

