# == Name
#
# apt.pkg
#
# === Description
#
# Manage packages via apt.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * package: The name of the package. Required. namevar.
# * version: The version of the package. Leave empty for first version found. Set to "latest" to always update.
#
# === Example
#
# ```shell
# apt.pkg --package tmux --version latest
# ```
#
function apt.pkg {
  waffles.subtitle "apt.pkg"

  # Resource Options
  local -A options
  waffles.options.create_option state   "present"
  waffles.options.create_option package "__required__"
  waffles.options.create_option version
  waffles.options.parse_options "$@"

  # Local Variables
  local _installed
  local _candidate
  local _version

  # Internal Resource Configuration
  if [[ -z ${options[version]} ]]; then
    _version=""
  elif [[ ${options[version]} == "latest" ]]; then
    _version=""
  else
    _version="=${options[version]}"
  fi

  # Process the resource
  waffles.resource.process "apt.pkg" "${options[package]}"
}

function apt.pkg.read {
  # check to see if it's a valid package
  # apt-cache is handling stderr weird
  # return 1 so installation attempt does not happen
  exist=$(apt-cache policy ${options[package]})
  if [[ -z $exist ]]; then
    log.error "No such package: ${options[package]}"
    waffles_resource_current_state="error"
    return
  fi

  # check to see if it's installed at all
  exec.debug_mute dpkg -s ${options[package]}
  if [[ $? == 1 ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  _installed=$(/usr/bin/apt-cache policy ${options[package]} | grep Installed | cut -d: -f2- | sed -e 's/^[[:space:]]//g')
  _candidate=$(/usr/bin/apt-cache policy ${options[package]} | grep Candidate | cut -d: -f2- | sed -e 's/^[[:space:]]//g')

  # If the package is installed, but version is set to "", then the requirement is satisfied
  if [[ -n $_installed && -z ${options[version]} ]]; then
    waffles_resource_current_state="present"
    return
  fi

  # if version == latest, install if there's a newer version available
  if [[ ${options[version]} == "latest" && $_installed != $_candidate ]]; then
    waffles_resource_current_state="update"
    _version="=$_candidate"
    return
  fi

  # if installed != version, install the package
  if [[ ${options[version]} != "latest" && $_installed != ${options[version]} ]]; then
    waffles_resource_current_state="update"
    return
  fi

  # if installed and candidate differ, report a new version available.
  if [[ $_installed != $_candidate ]]; then
    log.debug "New version available: $_candidate"
  fi

  waffles_resource_current_state="present"
}

function apt.pkg.create {
  export DEBIAN_FRONTEND=noninteractive
  export APT_LISTBUGS_FRONTEND=none
  export APT_LISTCHANGES_FRONTEND=none
  exec.capture_error "/usr/bin/apt-get install -y --force-yes -o DPkg::Options::=--force-confold ${options[package]}${_version}"
  unset DEBIAN_FRONTEND
  unset APT_LISTBUGS_FRONTEND
  unset APT_LISTCHANGES_FRONTEND
}

function apt.pkg.update {
  apt.pkg.create
}

function apt.pkg.delete {
  export DEBIAN_FRONTEND=noninteractive
  export APT_LISTBUGS_FRONTEND=none
  export APT_LISTCHANGES_FRONTEND=none
  exec.capture_error "/usr/bin/apt-get purge -q -y ${options[package]}"
  unset DEBIAN_FRONTEND
  unset APT_LISTBUGS_FRONTEND
  unset APT_LISTCHANGES_FRONTEND
}
