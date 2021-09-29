#!/bin/bash

source "${0%/*}/../bin/argparse.sh"

arg_boolean "[dry-run] [Dry run attempt. Will add a '_acme-test' DNS record.]"
arg_help    "[
Renew LetsEncrypt wildcard certificate for maneyko.com.
See '/var/log/letsencrypt/letsencrypt.log' for letsencrypt DEBUG logs.
See '/var/root/log/cron.log' for script logs.]"
parse_args

if [[ -n $ARG_DRY_RUN ]]; then
  options="--dry-run"
  export ARG_NAME='_acme-test'
fi

certbot certonly \
  $options \
  --server 'https://acme-v02.api.letsencrypt.org/directory' \
  --manual \
  --force-renewal \
  --manual-public-ip-logging-ok \
  --manual-auth-hook $__DIR__/godaddy-dns-manager.sh \
  --preferred-challenges dns-01 \
  -d '*.maneyko.com' \
  -d 'maneyko.com'
