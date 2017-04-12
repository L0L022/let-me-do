#!/bin/bash

if [ "$(which pkexec)" ]; then
	pkexec "@LET_ME_DO_PATH@" "$@"
else
	@LET_ME_DO_PATH@ "$@"
fi
