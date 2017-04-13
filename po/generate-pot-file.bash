#!/bin/bash

xgettext --package-name=let-me-do --package-version=1.0 \
--copyright-holder='Loïc Escales <L0L022@openmailbox.org>' \
--msgid-bugs-address='https://github.com/L0L022/let-me-do/issues' \
-o let-me-do.pot -L Shell ../let-me-do.bash
