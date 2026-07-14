#!/bin/bash

source "/home/maneyko/secrets/cloudflare.env"

make_request() {
  curl -sL \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  "$@" |
  jq .
}

API_BASE="https://api.cloudflare.com/client/v4"

zone_id=$(make_request "$API_BASE/zones" | jq -r '.result | map(select(.name == "maneyko.com"))[0].id')

make_request -XPOST "$API_BASE/zones/$zone_id/purge_cache"
