#!/bin/bash

if [ "$(which pkexec)" ]; then
	pkexec "@LET-ME-DO_PATH@" "$@"
else
	@LET-ME-DO_PATH@ "$@"
fi
