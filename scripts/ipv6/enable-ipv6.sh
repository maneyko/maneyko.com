#!/bin/bash

set -e

# https://stackoverflow.com/a/30201105/5799651
nic=$(ip -o route show to default | awk '{print $5}')

previous_dns_servers="${0%/*}"/previous-dns-servers.txt

if [[ -f "$previous_dns_servers"  ]]; then
  previous_dns=$(tail -1 "$previous_dns_servers")

  if [[ -n $previous_dns ]]; then
    sudo resolvectl dns "$nic" "$previous_dns"
  fi
fi

sudo resolvectl revert "$nic"

printf "DNS Servers have been updated.\n\n"
resolvectl status "$nic"
