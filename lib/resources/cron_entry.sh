# == Name
#
# cron.entry
#
# === Description
#
# Manages cron entries
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: A single-word name for the cron. Required. namevar.
# * user: The user to run the cron job as. Default: root.
# * cmd: The command to run. Required.
# * minute: The minute field of the cron. Default: *.
# * hour: The hour field of the cron. Default: *.
# * dom: The day of month field for the cron. Default: *.
# * month: The month field of the cron. Default: *.
# * dow: The day of week field of the cron. Default: *.
#
# === Example
#
# ```shell
# cron.entry --name foobar --cmd /path/to/some/report --minute "*/5"
# ```
#
# === TODO
#
# Add support for prefix info such as PATH, MAILTO.
#
function cron.entry {
  waffles.subtitle "cron.entry"

  # Resource Options
  local -A options
  waffles.options.create_option state  "present"
  waffles.options.create_option name   "__required__"
  waffles.options.create_option user   "root"
  waffles.options.create_option cmd    "__required__"
  waffles.options.create_option minute "*"
  waffles.options.create_option hour   "*"
  waffles.options.create_option dom    "*"
  waffles.options.create_option month  "*"
  waffles.options.create_option dow    "*"
  waffles.options.parse_options "$@"

  # Local Variables
  local entry="${options[minute]} ${options[hour]} ${options[dom]} ${options[month]} ${options[dow]} ${options[cmd]} # ${options[name]}"
  local _entry

  # Process the resource
  waffles.resource.process "cron.entry" "$entry"
}

function cron.entry.read {
  _entry=$(crontab -u "${options[user]}" -l 2> /dev/null | grep "# ${options[name]}$")
  if [[ -z $_entry ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  if [[ $entry != $_entry ]]; then
    waffles_resource_current_state="update"
    return
  fi

  waffles_resource_current_state="present"
}

function cron.entry.create {
  local _script
  read -r -d '' _script<<EOF
(
  crontab -u "${options[user]}" -l 2> /dev/null | grep -v "# ${options[name]}$" 2> /dev/null || true
  echo "$entry"
) | crontab -u "${options[user]}" -
EOF
  exec.capture_error "$_script"
}

function cron.entry.update {
  cron.entry.create
}

function cron.entry.delete {
  local _script
  read -r -d '' _script<<EOF
(
  crontab -u "${options[user]}" -l 2> /dev/null | grep -v "# ${options[name]}$" 2> /dev/null || true
) | crontab -u "${options[user]}" -
EOF
  exec.capture_error "$_script"
}
