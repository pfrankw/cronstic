#!/bin/sh

eval "$COMMANDS_PRE"

restic backup $@

if [ $? -eq 0 ]; then
  eval "$COMMANDS_SUCCESS"
else
  eval "$COMMANDS_FAIL"
fi

eval "$COMMANDS_POST"
