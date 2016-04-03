# == Name
#
# iptables.rule
#
# === Description
#
# Manages iptables rules
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: An arbitrary name for the rule. Required. namevar.
# * priority: An arbitrary number to give the rule priority. Required. Default 100.
# * table: The table to add the rule to.. Required. Default: filter.
# * chain: The chain to add the rule to. Required. Default: INPUT.
# * rule: The rule. Required.
# * action: The action to take on the rule. Required. Default: ACCEPT.
#
# === Example
#
# ```shell
# iptables.rule --priority 100 --name "allow all from 192.168.1.0/24" --rule "-m tcp -s 192.168.1.0/24" --action ACCEPT
# ```
#
function iptables.rule {
  waffles.subtitle "iptables.rule"

  # Resource Options
  local -A options
  waffles.options.create_option state    "present"
  waffles.options.create_option name     "__required__"
  waffles.options.create_option priority "100"
  waffles.options.create_option table    "filter"
  waffles.options.create_option chain    "INPUT"
  waffles.options.create_option rule     "__required__"
  waffles.options.create_option action   "ACCEPT"
  waffles.options.parse_options "$@"

  # Local Variables
  local rule="${options[chain]} ${options[rule]} -m comment --comment \"${options[priority]} ${options[name]}\" -j ${options[action]}"

  # Process the resource
  waffles.resource.process "iptables.rule" "$rule"
}

function iptables.rule.read {
  iptables -t "${options[table]}" -S "${options[chain]}" | grep -q "comment \"${options[priority]} ${options[name]}\""
  if [[ $? != 0 ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  iptables -t "${options[table]}" -C "${options[chain]}" $rule 2>/dev/null
  if [[ $? == 1 ]]; then
    waffles_resource_current_state="update"
    return
  fi

  waffles_resource_current_state="present"
}

function iptables.rule.create {
  local rulenum=0
  local added="false"

  local -a oldrules
  mapfile -t oldrules < <(iptables -t ${options[table]} -S "${options[chain]}" | grep -v ^-P)
  if [[ ${#oldrules[@]} == 0 ]]; then
    exec.capture_error "iptables -t ${options[table]} -I $rule"
    added="true"
  else
    for oldrule in "${oldrules[@]}"; do
      rulenum=$((rulenum+1))
      local oldcomment=$(echo $oldrule | sed -e 's/.*--comment "\(.*\)".*/\1/')
      if [[ ! $oldcomment =~ ^- ]]; then
        local priority=$(echo $oldcomment | cut -d' ' -f1)
        if [[ $priority > ${options[priority]} ]]; then
          exec.capture_error "iptables -t ${options[table]} -I $rulenum $oldrule"
          added="true"
          break
        fi
      fi
    done
  fi

  if [[ $added == "false" ]]; then
    exec.capture_error "iptables -t ${options[table]} -A $rule"
  fi
}

function iptables.rule.update {
  local _rule=$(iptables -S -t ${options[table]} "${options[chain]}" | grep "comment \"${options[priority]} ${options[name]}\"" | sed -e 's/^-A/-D/')
  exec.capture_error "iptables -t ${options[table]} $_rule"
  exec.capture_error "iptables -t ${options[table]} $rule"
}

function iptables.rule.delete {
  local _rule=$(iptables -S -t ${options[table]} "${options[chain]}" | grep "comment \"${options[priority]} ${options[name]}\"" | sed -e 's/^-A/-D/')
  exec.capture_error "iptables -t ${options[table]} $_rule"
}
