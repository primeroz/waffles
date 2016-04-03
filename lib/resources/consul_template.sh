# == Name
#
# consul.template
#
# === Description
#
# Manages a consul.template.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name of the template. Required. namevar.
# * source: The source of the template. Optional. Defaults to /etc/consul/template/ctmpl/name.ctmpl
# * destination: The destination of the rendered template. Required.
# * command: An optional command to run after the template is rendered. Optional.
# * file: The file to store the template in. Required. Defaults to /etc/consul/template/conf.d/name.json
# * file_owner: The owner of the service file. Optional. Defaults to root.
# * file_group: The group of the service file. Optional. Defaults to root.
# * file_mode: The mode of the service file. Optional. Defaults to 0640
#
# === Example
#
# ```shell
# consul.template --name hosts \
#                 --destination /etc/hosts
# ```
#
function consul.template {
  waffles.subtitle "consul.template"

  if ! waffles.command_exists jsed ; then
    log.error "Cannot find jsed"
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  if ! waffles.command_exists consul ; then
    log.error "Cannot find consul"
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Resource Options
  local -A options
  waffles.options.create_option state       "present"
  waffles.options.create_option name        "__required__"
  waffles.options.create_option destination "__required__"
  waffles.options.create_option source
  waffles.options.create_option command
  waffles.options.create_option file
  waffles.options.create_option file_owner "root"
  waffles.options.create_option file_group "root"
  waffles.options.create_option file_mode  "640"
  waffles.options.parse_options "$@"

  # Local Variables
  local _file _source
  local _name="${options[name]}"
  local _simple_options=(destination source command)

  # Internal Resource configuration
  if [[ -z ${options[file]} ]]; then
    _file="/etc/consul/template/conf.d/${options[name]}.json"
  else
    _file="${options[file]}"
  fi

  if [[ -z ${options[source]} ]]; then
    options[source]="/etc/consul/template/ctmpl/${options[name]}.ctmpl"
  fi

  # Process the resource
  waffles.resource.process "consul.template" "$_name"
}

function consul.template.read {
  if [[ ! -f $_file ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  _template=$(consul.template.build_template)
  _existing_md5=$(md5sum "$_file" | cut -d' ' -f1)
  _new_md5=$(echo $_template | md5sum | cut -d' ' -f1)

  if [[ "$_existing_md5" != "$_new_md5" ]]; then
    waffles_resource_current_state="update"
    return
  fi

  waffles_resource_current_state="present"
}

function consul.template.create {
  _template=$(consul.template.build_template)
  os.file --name "$_file" --content "$_template" --owner "${options[file_owner]}" --group "${options[file_group]}" --mode "${options[file_mode]}"
}

function consul.template.update {
  consul.template.delete
  consul.template.create
}

function consul.template.delete {
  exec.capture_error rm "$_file"
}

function consul.template.build_template {
  _template="{}"

  for _o in "${_simple_options[@]}"; do
    if [[ -n ${options[$_o]} ]]; then
      _template=$(echo "$_template" | jsed add object --path template --key "$_o" --value "${options[$_o]}")
    fi
  done

  echo "$_template"
}
