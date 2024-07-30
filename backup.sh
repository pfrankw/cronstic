#!/bin/sh

$COMMANDS_PRE

restic backup $@

if [ $? -eq 0 ]; then
  $COMMANDS_SUCCESS
else
  $COMMANDS_FAIL
fi

$COMMANDS_POST
