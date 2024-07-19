#!/bin/bash

set -e

# level66
nameservers=(
2001:67c:2960::64
2001:67c:2960::6464
)

# # nat64.net
# # Note: ping does not work with these DNS servers
# nameservers=(
# 2a01:4ff:f0:9876::1
# 2a00:1098:2c::1
# 2a00:1098:2b::1
# )

# https://stackoverflow.com/a/30201105/5799651
nic=$(ip -o route show to default | awk '{print $5}')

current_dns_servers=($(resolvectl status "$nic" | awk -F: '/DNS Servers/ { print $2 }'))

previous_dns_servers="${0%/*}"/previous-dns-servers.txt

echo "${current_dns_servers[@]}" >> "$previous_dns_servers"

sudo resolvectl dns "$nic" "${nameservers[@]}"

printf "DNS Servers have been updated.\n\n"
resolvectl status "$nic"
