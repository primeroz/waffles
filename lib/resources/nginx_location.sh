# == Name
#
# nginx.location
#
# === Description
#
# Manages key/value settings in an nginx server location block
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name of the location block. Required. namevar.
# * server_name: The name of the nginx_server resource. Required.
# * key: The key. Required.
# * value: A value for the key. Required.
# * file: The file to add the variable to. Optional. Defaults to /etc/nginx/sites-enabled/server_name.
#
# === Example
#
# ```shell
# nginx.location --name '~ \.php$' --server_name example.com --key try_files --value '$uri $uri/ @dw'
# ```
#
function nginx.location {
  waffles.subtitle "nginx.location"

  if ! waffles.command_exists augtool ; then
    log.error "Cannot find augtool."
    if [[ -n $WAFFLES_EXIT_ON_ERROR ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Resource Options
  local -A options
  waffles.options.create_option state       "present"
  waffles.options.create_option name        "__required__"
  waffles.options.create_option server_name "__required__"
  waffles.options.create_option key         "__required__"
  waffles.options.create_option value       "__required__"
  waffles.options.create_option file
  waffles.options.parse_options "$@"

  # Local Variables
  local _name="${options[name]}.${options[key]}"
  local _dir="/etc/nginx/sites-enabled"
  local _server_name="${options[server_name]}"
  local _file
  local _comp _uri

  # Internal Resource Configuration
  if [[ -n ${options[file]} ]]; then
    _file="${options[file]}"
  else
    _file="${_dir}/${_server_name}"
  fi

  if [[ ${options[name]} =~ " " ]]; then
    string.split "${options[name]}" " "
    _comp="${__split[0]}"
    _uri="${__split[1]}"
  else
    _uri="${options[name]}"
  fi

  # Process the resource
  waffles.resource.process "nginx.location" "$_name"
}

function nginx.location.read {
  local _result

  if [[ ! -f $_file ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  # Check if the server_name exists
  waffles_resource_current_state=$(augeas.get --lens Nginx --file "$_file" --path "/server/server_name[. = '$_server_name']")
  if [[ "$waffles_resource_current_state" == "absent" ]]; then
    log.error "$_server_name does not exist. Run augeas.nginx_server first."
    waffles_resource_current_state="error"
    return
  fi

  # Check if the location exists
  local _path
  _path="/server/server_name[. = '$_server_name']/../location/#uri[. = '$_uri']"
  waffles_resource_current_state=$(augeas.get --lens Nginx --file "$_file" --path "$_path")
  if [[ $waffles_resource_current_state == "absent" ]]; then
    return
  fi

  # Check if comp exists
  if [[ -n $_comp ]]; then
    _path="/server/server_name[. = '$_server_name']/../location/#uri[. = '$_uri']"
    _result=$(augeas.get --lens Nginx --file "$_file" --path "$_path")
    if [[ $_result == "absent" ]]; then
      waffles_resource_current_state="update"
      return
    fi
  fi

  # Check if the key exists and the value matches
  _path="/server/server_name[. = '$_server_name']/../location/#uri[. = '$_uri']/../${options[key]}[. = '${options[value]}']"
  _result=$(augeas.get --lens Nginx --file "$_file" --path "$_path")
  if [[ $_result == "absent" ]]; then
    waffles_resource_current_state="update"
    return
  fi

  waffles_resource_current_state="present"
}

function nginx.location.create {
  local -a _augeas_commands=()
  if [[ -n $_comp ]]; then
    _augeas_commands+=("set /files$_file/server/server_name[. = '$_server_name']/../location[0]/#comp '$_comp'")
    _augeas_commands+=("set /files$_file/server/server_name[. = '$_server_name']/../location[last()]/#uri '$_uri'")
  else
    _augeas_commands+=("set /files$_file/server/server_name[. = '$_server_name']/../location[0]/#uri '$_uri'")
  fi

  _augeas_commands+=("set /files$_file/server/server_name[. = '$_server_name']/../location[last()]/${options[key]} '${options[value]}'")

  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    log.error "Error adding nginx_location $_name with augeas: $_result"
    return
  fi
}

function nginx.location.update {
  local -a _augeas_commands=()
  _augeas_commands+=("set /files$_file/server/server_name[. = '$_server_name']/../location/#uri[. = '$_uri']/../${options[key]} '${options[value]}'")

  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    log.error "Error adding nginx_location $_name with augeas: $_result"
    return
  fi
}

function nginx.location.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files$_file/server/server_name[. = '$_server_name']/../location/#uri[. = '$_uri']/../${options[key]}")

  local _result=$(augeas.run --lens Nginx --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    log.error "Error deleting nginx_location $_name with augeas: $_result"
    return
  fi
}
