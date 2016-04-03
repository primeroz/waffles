# == Name
#
# augeas.mail_alias
#
# === Description
#
# Manages aliases in /etc/aliases
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * account: The mail account. Required. namevar.
# * destination: The destination for the account. Required.
# * alias: Additional aliases for the account. Optional. Multi-value.
# * file: The aliases file. Default: /etc/aliases.
#
# === Example
#
# ```shell
# augeas.mail_alias --account root --destination /dev/null
# ```
#
function augeas.mail_alias {
  waffles.subtitle "augeas.mail_alias"

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
  local -a alias
  waffles.options.create_option    state       "present"
  waffles.options.create_option    account     "__required__"
  waffles.options.create_option    destination "__required__"
  waffles.options.create_mv_option alias
  waffles.options.create_option    file        "/etc/aliases"
  waffles.options.parse_options    "$@"

  # Convert to an `augeas.generic` resource
  augeas.generic --name "augeas.mail_alias.${options[account]}" \
                 --lens Aliases \
                 --file "${options[file]}" \
                 --command "set 01/name '${options[account]}'" \
                 --command "set 01/value '${options[destination]}'" \
                 --notif "*/name[. = '${options[account]}']/../value[. = '${options[destination]}']"

  for a in "${alias[@]}"; do
    augeas.generic --name "augeas.mail_alias.${options[account]}.$a" \
                   --lens Aliases \
                   --file "${options[file]}" \
                   --command "set */name[. = '${options[account]}']/../value[. = '$a'] '$a'"
  done
}
