#!/bin/bash

mkdir -p whois

next_ip() {
  arg2="$2"
  python3 -c "import ipaddress; print(str(ipaddress.ip_address('$1')+${arg2:=1}))"
}

ip_range_to_cidr() {
  read -r -d '' python_script << EOT
from ipaddress import IPv4Address, summarize_address_range

print(str(list(
  summarize_address_range(IPv4Address('$1'.strip()), IPv4Address('$2'.strip()))
)[0]))
EOT
  python3 -c "$python_script"
}

ip_test="0.0.0.2"
# ip_test="1.10.10.2"

echo "Processing ..."

# next_ip '255.255.255.255' makes ip_test an empty string
while [[ -n $ip_test ]]; do
  printf "\r$ip_test "
  echo "$ip_test" >> ip_list.txt
  output_txt="whois/$ip_test.json"

  sleep 5
  curl -sL https://rdap.arin.net/registry/ip/$ip_test > "$output_txt"

  read start_ip end_ip <<< $(
    cat "$output_txt" \
      | jq -r '[ .startAddress, .endAddress ] | join(" ")'
  )

  is_arin="$(
    cat "$output_txt" \
      | jq -r '.port43 // "" | match(".*arin.net").string?'
  )"

  if [[ -z $is_arin ]]; then
    cidr="$(ip_range_to_cidr "$start_ip" "$end_ip")"
    echo "$start_ip - $end_ip : $cidr" >> need_to_block.txt
  fi

  if [[ -z $end_ip ]]; then
    end_ip=$(next_ip "$ip_test" 256)
  fi

  ip_test=$(next_ip "$end_ip" 3)
done
