#!/bin/bash

xgettext --package-name=let_me_do --package-version=1.0 \
--copyright-holder='Loïc Escales <L0L022@openmailbox.org>' \
--msgid-bugs-address='https://github.com/L0L022/let_me_do/issues' \
-o let_me_do.pot -L Shell ../let_me_do.bash
