#!/bin/bash

SCRIPTS_ROOT="${0%/*}/.."
SCRIPTS_ROOT="$(perl -MCwd -e 'print Cwd::abs_path shift' "$SCRIPTS_ROOT")"

# Must be in PATH -- https://github.com/maneyko/argparse.sh
source "argparse.sh"

ARG_TYPE='TXT'
ARG_DOMAIN='maneyko.com'
: ${ARG_NAME:="_acme-challenge.$ARG_DOMAIN"}
ARG_TTL='1'

arg_optional "[domain]     [Domain name for which we are updating DNS records. Default: '$ARG_DOMAIN']"
arg_optional '[env]    [e] [Source the specified file which defines environment variables.
Should define:
    $GODADDY_API_KEY
    $GODADDY_API_SECRET
    $GODADDY_SHOPPER_ID]'
arg_optional "[type]   [t] [DNS type of record that will be updated. Default: '$ARG_TYPE']"
arg_optional "[name]   [n] [DNS record name that will be updated. Default: '$ARG_NAME']"
arg_optional "[data]   [d] [Data to store in the DNS record. Required if not using '-d' flag.]"
arg_optional "[ttl]        [TTL for DNS new record. Default: '$ARG_TTL']"
arg_boolean  "[read]   [r] [Just return DNS records for maneyko.com]"

arg_help "[
Update DNS $ARG_TYPE record '$ARG_NAME' for '$ARG_DOMAIN' in GoDaddy.
API documentation: https://developer.godaddy.com/doc/endpoint/domains#/v1/recordAdd]"
parse_args

if [[ -f "$__DIR__/.env.local" ]]; then
  source "$__DIR__/.env.local"
fi

if [[ -f "$SCRIPTS_ROOT/.env.local" ]]; then
  source "$SCRIPTS_ROOT/.env.local"
fi

if [[ -f "$ARG_ENV" ]]; then
  source "$ARG_ENV"
fi

mkdir -p "$HOME/log"
log() {
  echo "I, [$(date +'%Y-%m-%dT%H:%M:%S%z') #$$]  INFO -- : $@" >> $HOME/log/cron.log
}

: ${ARG_DATA:="$CERTBOT_VALIDATION"}

api_base="https://api.cloudflare.com/client/v4"

make_request() {
  curl -sL \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  "$@" \
  | jq .
}

if [[ -n $ARG_READ ]]; then
  make_request "$api_base/zones/$ZONE_ID/dns_records"
  exit 0
fi

read -r -d '' call_info << EOT
CERTBOT_DOMAIN:               $CERTBOT_DOMAIN
CERTBOT_VALIDATION:           $CERTBOT_VALIDATION
CERTBOT_TOKEN:                $CERTBOT_TOKEN
CERTBOT_REMAINING_CHALLENGES: $CERTBOT_REMAINING_CHALLENGES
CERTBOT_ALL_DOMAINS:          $CERTBOT_ALL_DOMAINS
EOT

log "$call_info"

time_now=$(date +%s)
last_updated_file="$__DIR__/certbot-last-ran.txt"
if [[ -f $last_updated_file ]]; then
  last_updated="$(perl -e "print ((stat('$last_updated_file'))[9])")"
else
  last_updated=$(( $time_now - 600 ))
fi
seconds_since_update=$(( $time_now - $last_updated ))

SHOULD_DELETE=true

if [[ $seconds_since_update -lt 300 ]]; then
  log "INFO: Updated less than 5 minutes ago"
  SHOULD_DELETE=
fi
date > "$last_updated_file"

if [[ -z $ARG_DATA ]]; then
  log 'ERROR: $ARG_DATA is empty.'
  exit 1
fi

if [[ -n $SHOULD_DELETE ]]; then
  existing_record_ids=($(
    make_request "$api_base/zones/$ZONE_ID/dns_records?name=$ARG_NAME" \
      | jq -r '.result[].id'
  ))

  for record_id in ${existing_record_ids[@]}; do
    res=$(make_request -XDELETE "$api_base/zones/$ZONE_ID/dns_records/$record_id")
    log "$res"
    sleep 1
  done
fi

read -r -d '' post_data << EOT
  {
    "type": "$ARG_TYPE",
    "name": "$ARG_NAME",
    "content": "$ARG_DATA",
    "ttl":  $ARG_TTL,
    "zone_id": "$ZONE_ID",
    "id": "$(openssl rand -hex 16)",
    "proxied": false
  }
EOT

res=$(
  make_request -XPOST "$api_base/zones/$ZONE_ID/dns_records" -d "$post_data"
)
log "$res"
sleep 20
