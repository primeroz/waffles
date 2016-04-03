# == Name
#
# apt.key
#
# === Description
#
# Manages apt keys
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: An arbitrary name. Required. namevar.
# * key: The key to import. Required if no remote_keyfile.
# * keyserver: The key server. Required if no remote_keyfile.
# * remote_keyfile: A remote key to import. Required if no key or keyserver.
#
# === Example
#
# ```shell
# apt.key --name "foobar" --key 1C4CBDCDCD2EFD2A
# ```
#
function apt.key {
  waffles.subtitle "apt.key"

  # Resource Options
  local -A options
  waffles.options.create_option state "present"
  waffles.options.create_option name  "__required__"
  waffles.options.create_option key
  waffles.options.create_option keyserver
  waffles.options.create_option remote_keyfile
  waffles.options.parse_options "$@"

  # Process the resource
  waffles.resource.process "apt.key" "${options[name]}"
}

function apt.key.read {
  apt-key export ${options[key]} 2>/dev/null | grep -q "BEGIN PGP"
  if [[ $? == 0 ]]; then
    waffles_resource_current_state="present"
    return
  fi
  waffles_resource_current_state="absent"
}

function apt.key.create {
  if [[ -n ${options[remote_keyfile]} ]]; then
    if ! waffles.command_exists wget ; then
      log.error "wget not installed. Unable to obtain remote keyfile."
      if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
        exit 1
      else
        return 1
      fi
    else
      local _remote_file="${options[remote_keyfile]}"
      local _local_file=${_remote_file##*/}
      exec.mute pushd /tmp
      exec.capture_error wget "$_remote_file"
      exec.capture_error apt-key add "$_local_file"
      exec.mute rm "$_remote_file"
      exec.mute popd
    fi
  else
    exec.capture_error apt-key adv --keyserver ${options[keyserver]} --recv-keys ${options[key]}
  fi
}

function apt.key.delete {
  exec.capture_error apt-key del ${options[key]}
}
