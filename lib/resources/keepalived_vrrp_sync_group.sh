# == Name
#
# keepalived.vrrp_sync_group
#
# === Description
#
# Manages vrrp_sync_group section in keepalived.conf
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name of the VRRP instance. Required. namevar.
# * group: The name of a VRRP instance. Required. Multi-var.
# * file: The file to store the settings in. Required. Defaults to /etc/keepalived/keepalived.conf.
#
# === Example
#
# ```shell
# keepalived.vrrp_sync_group --name VSG_1 \
#                            --group VI_1 \
#                            --group VI_2 \
# ```
#
function keepalived.vrrp_sync_group {
  waffles.subtitle "keepalived.vrrp_sync_group"

  if ! waffles.command_exists augtool ; then
    log.error "Cannot find augtool."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Resource Options
  local -A options
  local -a group
  waffles.options.create_option state    "present"
  waffles.options.create_option name     "__required__"
  waffles.options.create_option file     "/etc/keepalived/keepalived.conf"
  waffles.options.create_mv_option group "__required__"
  waffles.options.parse_options    "$@"

  # Local Variables
  local _name="${options[name]}"
  local _dir=$(dirname "${options[file]}")
  local _file="${options[file]}"
  local -A options_to_update
  local -a simple_options=("notify_master" "notify_backup" "notify_fault" "notify")
  local -a boolean_options=("smtp_alert")

  # Process the resource
  waffles.resource.process "keepalived.vrrp_sync_group" "$_name"
}

function keepalived.vrrp_sync_group.read {
  if [[ ! -f $_file ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  # Check if the vrrp_sync_group exists
  waffles_resource_current_state=$(augeas.get --lens Keepalived --file "$_file" --path "/vrrp_sync_group[. = '${options[name]}']")
  if [[ $waffles_resource_current_state == "absent" ]]; then
    return
  fi

  # Check if the groups exist
  for g in "${group[@]}"; do
    _result=$(augeas.get --lens Keepalived --file "$_file" --path "/vrrp_sync_group[. = '${options[name]}']/group/$g")
    if [[ $_result == "absent" ]]; then
      options_to_update["group"]=1
      waffles_resource_current_state="update"
    fi
  done

  if [[ $waffles_resource_current_state == "update" ]]; then
    return
  else
    waffles_resource_current_state="present"
  fi

}

function keepalived.vrrp_sync_group.create {
  local _result
  local -a _augeas_commands=()

  if [[ ! -d $_dir ]]; then
    exec.capture_error mkdir -p "$_dir"
  fi

  # Create the vrrp_sync_group
  if [[ $waffles_resource_current_state == "absent" ]]; then
    _augeas_commands+=("set /files/${_file}/vrrp_sync_group[0] '${options[name]}'")
  fi

  # Set groups
  if [[ ${options_to_update[group]+isset} || $waffles_resource_current_state == "absent" ]]; then
    for g in "${group[@]}"; do
      _augeas_commands+=("touch /files/${_file}/vrrp_sync_group[. = '${options[name]}']/group/$g")
    done
  fi

  _result=$(augeas.run --lens Keepalived --file "$_file" "${_augeas_commands[@]}")
  if [[ $_result =~ ^error ]]; then
    log.error "Error adding $_name with augeas: $_result"
  fi
}

function keepalived.vrrp_sync_group.update {
  keepalived.vrrp_sync_group.delete
  keepalived.vrrp_sync_group.create
}
function keepalived.vrrp_sync_group.delete {
  local _result
  local -a _augeas_commands=()

  # Delete groups
  if [[ ${options_to_update[virtual_ipaddress]+isset} ]]; then
    for n in "${virtual_ipaddress[@]}"; do
      _augeas_commands+=("rm /files/${_file}/vrrp_sync_group[. = '${options[name]}']/group")
    done
  fi

  _result=$(augeas.run --lens Keepalived --file "$_file" "${_augeas_commands[@]}")
  if [[ $_result =~ ^error ]]; then
    log.error "Error adding $_name with augeas: $_result"
  fi
}
