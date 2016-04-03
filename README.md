# Waffles!

Waffles is a simple configuration management and deployment system written in Bash.

```shell
#!/usr/local/bin/wafflescript

# Install memcached
apt.pkg --package memcached --version latest

# Set the listen option
file.line --file /etc/memcached.conf --line "-l 0.0.0.0" --match "^-l"

# Determine the amount of memory available and use half of that for memcached
memory_bytes=$(terminus System.Memory.Total 2>/dev/null)
memory=$(( $memory_bytes / 1024 / 1024 / 2 ))

# Set the memory available to memcached
file.line --file /etc/memcached.conf --line "-m $memory" --match "^-m"

# Manage the memcached service
service.sysv --name memcached

if [[ $waffles_state_changed == true ]]; then
  exec.mute /etc/init.d/memcached restart
fi
```

See [waffles.terrarum.net](http://waffles.terrarum.net) for more information.

(See [terminus](https://github.com/jtopjian/terminus) for terminus.)
