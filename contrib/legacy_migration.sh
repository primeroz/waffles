declare -Ag legacy
legacy[stdlib.apt_key]="apt.key"
legacy[stdlib.apt_ppa]="apt.ppa"
legacy[stdlib.apt]="apt.pkg"
legacy[stdlib.apt_source]="apt.source"
legacy[stdlib.cron]="cron.entry"
legacy[stdlib.debconf]="dpkg.debconf"
legacy[stdlib.directory]="os.directory"
legacy[stdlib.file]="os.file"
legacy[os.file_line]="file.line"
legacy[stdlib.git]="git.repo"
legacy[stdlib.groupadd]="os.groupadd"
legacy[stdlib.ini]="file.ini"
legacy[stdlib.ip6tables_rule]="ip6tables.rule"
legacy[stdlib.ip6tables_rule]="iptables.rule"
legacy[stdlib.sudo_cmd]="sudo.cmd"
legacy[stdlib.symlink]="os.symlink"
legacy[stdlib.sysvinit]="service.sysvinit"
legacy[stdlib.upstart]="service.upstart"
legacy[stdlib.useradd]="os.useradd"
legacy[stdlib.color\?]="waffles.color"
legacy[stdlib.debug]="log.debug"
legacy[stdlib.warn]="log.warn"
legacy[stdlib.error]="log.error"
legacy[stdlib.info]="log.info"
legacy[stdlib.noop\?]="waffles.noop"
legacy[stdlib.debug\?]="waffles.debug"
legacy[stdlib.title]="waffles.title"
legacy[stdlib.subtitle]="waffles.subtitle"
legacy[stdlib.mute]="exec.mute"
legacy[stdlib.debug_mute]="exec.debug_mute"
legacy[stdlib.exec]="exec.run"
legacy[stdlib.capture_error]="exec.capture_error"
legacy[stdlib.dir]="waffles.dir"
legacy[stdlib.include]="waffles.include"
legacy[stdlib.git_profile]="git.profile"
legacy[stdlib.data]="waffles.data"
legacy[stdlib.command_exists]="waffles.command_exists"
legacy[stdlib.sudo_exec]="exec.sudo"
legacy[stdlib.split]="string.split"
legacy[stdlib.trim]="string.trim"
legacy[stdlib.array_length]="array.length"
legacy[stdlib.array_push]="array.push"
legacy[stdlib.array_pop]="array.pop"
legacy[stdlib.array_shift]="array.shift"
legacy[stdlib.array_unshift]="array.unshift"
legacy[stdlib.array_join]="array.join"
legacy[stdlib.array_contains]="array.contains"
legacy[stdlib.hash_keys]="hash.keys"
legacy[stdlib.build_ini_file]="waffles.build_ini_file"

for key in "${!legacy[@]}"; do
  value="${legacy[$key]}"
  find . -type f -print0 | xargs -0 sed -i "s/$key/$value/g"
done
