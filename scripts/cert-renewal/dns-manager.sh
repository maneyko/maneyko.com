#!/bin/bash

SCRIPTS_ROOT="${0%/*}/.."
SCRIPTS_ROOT="$(perl -MCwd -e 'print Cwd::abs_path shift' "$SCRIPTS_ROOT")"

# Must be in PATH -- https://github.com/maneyko/argparse.sh
source "argparse.sh"

ARG_TYPE='TXT'
: ${ARG_DATA:="$CERTBOT_VALIDATION"}
: ${ARG_DOMAIN:=$CERTBOT_DOMAIN}
: ${ARG_NAME:="_acme-challenge"}
: ${ARG_TTL:="1"}

arg_optional "[domain]     [Domain name for which we are updating DNS records. Default: '$ARG_DOMAIN']"
arg_optional '[env]    [e] [Source the specified file which defines environment variables.
Should define:
    $CLOUDFLARE_API_TOKEN
    $CLOUDFLARE_ZONE_ID (optional)
'
arg_optional "[type]   [t] [DNS type of record that will be updated. Default: '$ARG_TYPE']"
arg_optional "[name]   [n] [DNS record name that will be updated. Default: '$ARG_NAME']"
arg_optional "[data]   [d] [Data to store in the DNS record. Required if not using '\$CERTBOT_VALIDATION' is not set.]"
arg_optional "[ttl]        [TTL for DNS new record. Default: '$ARG_TTL']"
arg_boolean  "[read]   [r] [Just return DNS records for maneyko.com]"

arg_help "[
Update DNS $ARG_TYPE record '$ARG_NAME' for '$ARG_DOMAIN' in Cloudflare.
API documentation: https://developers.cloudflare.com/api/resources/zones/]"
parse_args

main() {
  source_env_files
  set_globals

  if [[ -n $ARG_READ ]]; then
    make_request "$API_BASE/zones/$CLOUDFLARE_ZONE_ID/dns_records"
    exit 0
  fi

  log_certbot_env

  if [[ -z $ARG_DATA ]]; then
    log 'ERROR: $ARG_DATA is empty.'
    exit 1
  fi

  delete_existing_if_necessary
}

source_env_files() {
  files=(
"$__DIR__/.env.local"
"$SCRIPTS_ROOT/.env.local"
"$ARG_ENV"
)

  for f in ${files[@]}; do
    if [[ -f $f ]]; then
      source "$f"
    fi
  done
}

set_globals() {
  DNS_NAME="${ARG_NAME}.$ARG_DOMAIN"

  API_BASE="https://api.cloudflare.com/client/v4"

  : ${CLOUDFLARE_ZONE_ID:=$(find_zone_id)}
}

log() {
  mkdir -p "$HOME/log"
  echo "I, [$(date +'%Y-%m-%dT%H:%M:%S%z') #$$]  INFO -- : $@" >> $HOME/log/cron.log
}

make_request() {
  curl -sL \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  "$@" \
  | jq .
}

find_zone_id() {
  domain_name=$ARG_DOMAIN
  domain_name=${domain_name#www.}

  make_request "$API_BASE/zones" \
    | jq -r ".result | map(select(.name == \"$domain_name\")) | first | .id"
}

log_certbot_env() {
  read -r -d '' call_info << EOT
CERTBOT_DOMAIN:               $CERTBOT_DOMAIN
CERTBOT_VALIDATION:           $CERTBOT_VALIDATION
CERTBOT_TOKEN:                $CERTBOT_TOKEN
CERTBOT_REMAINING_CHALLENGES: $CERTBOT_REMAINING_CHALLENGES
CERTBOT_ALL_DOMAINS:          $CERTBOT_ALL_DOMAINS
EOT

  log "$call_info"
}

delete_existing_if_necessary() {
  IFS=$'\r\n' dns_records=($(
    make_request "$API_BASE/zones/$CLOUDFLARE_ZONE_ID/dns_records?name=$DNS_NAME" \
      | jq -c '.result[]'
    ))

  # Only delete records that are older than 5 minutes. If a record was created in the last 5 minutes, it means
  # it was created during the current cert creation run (for another domain under the same cert).
  for dns_record in ${dns_records[@]}; do
    last_modified_at=$(echo "$dns_record" | jq -r '.modified_on | sub("\\.[0-9]+"; "") | fromdateiso8601')

    if [[ $(( $EPOCHSECONDS - $last_modified_at )) -lt 300 ]]; then
      log "INFO: Updated less than 5 minutes ago, will not delete existing DNS entries"
    else
      record_id=$(echo "$dns_record" | jq -r .id)
      res=$(make_request -XDELETE "$API_BASE/zones/$CLOUDFLARE_ZONE_ID/dns_records/$record_id")
      log "$res"
      sleep 1
    fi
  done
}

create_new_dns_record() {
  read -r -d '' post_data << EOT
  {
    "type": "$ARG_TYPE",
    "name": "$DNS_NAME",
    "content": "$ARG_DATA",
    "ttl":  $ARG_TTL,
    "zone_id": "$CLOUDFLARE_ZONE_ID",
    "id": "$(openssl rand -hex 16)",
    "proxied": false
  }
EOT

  res=$(make_request -XPOST "$API_BASE/zones/$CLOUDFLARE_ZONE_ID/dns_records" -d "$post_data")
  log "$res"

  sleep 20
}

main
