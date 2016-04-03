SHELL=/bin/bash

install:
	[[ -L /usr/local/bin/wafflescript ]] || ln -s waffles.sh /usr/local/bin/wafflescript

uninstall:
	[[ -L /usr/local/bin/wafflescript ]] && rm /usr/local/bin/wafflescript

.PHONY: docs
docs:
	cd docs/tools && bash mkdocs.sh
