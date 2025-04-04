#!/bin/bash

source "argparse.sh"

# Crontab entry:
#  0  5    1   *   *   /bin/bash -l -c '/var/www/maneyko.com/scripts/cert-renewal/certbot-renew-wildcard.sh maneyko.com -w && service nginx restart'

arg_positional "[domain]       [The domain to renew.]"
arg_boolean    "[wildcard] [w] [Create a wildcard certificate.]"
arg_boolean    "[dry-run]      [Dry run attempt. Will add a '_acme-test' DNS record.]"
arg_help    "[
Renew LetsEncrypt wildcard certificate for a domain.
See '/var/log/letsencrypt/letsencrypt.log' for letsencrypt DEBUG logs.
See '/var/root/log/cron.log' for script logs.]"
parse_args

if [[ -n $ARG_DRY_RUN ]]; then
  options="--dry-run"
  export ARG_NAME='_acme-test'
fi

ARG_DOMAIN="${ARG_DOMAIN#www.}"

if [[ -z $ARG_DOMAIN ]]; then
  echo "A domain name must be specified"
  exit 1
fi

DOMAIN1=$ARG_DOMAIN

if [[ -n $ARG_WILDCARD ]]; then
  DOMAIN2="*.${ARG_DOMAIN}"
else
  DOMAIN2="www.${ARG_DOMAIN}"
fi


certbot certonly \
  $options \
  --server 'https://acme-v02.api.letsencrypt.org/directory' \
  --manual \
  --force-renewal \
  --manual-public-ip-logging-ok \
  --manual-auth-hook $__DIR__/dns-manager.sh \
  --preferred-challenges dns-01 \
  -d $DOMAIN1 \
  -d $DOMAIN2
