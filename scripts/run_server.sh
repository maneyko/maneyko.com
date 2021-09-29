#!/usr/bin/env bash

source "$(dirname "$0")/bin/argparse.sh"

ARG_PORT=8089

arg_optional '[port] [p] [The port on which to run the PHP server.]'
arg_boolean  '[open] [o] [Automatically open a web browser.]'
arg_help     '[Run the PHP server locally.]'
parse_args

cd "$__DIR__"/../

if [[ $(uname) = Darwin && -n $ARG_OPEN ]]; then
  open http://127.0.0.1:$ARG_PORT
fi

php -S 127.0.0.1:$ARG_PORT -c ./config/
