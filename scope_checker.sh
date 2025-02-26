#!/bin/bash

if [[ -z "$1" ]]; then
    echo "[ERROR] Please specify a subnet list file!"
    echo "Usage: ./scope_checker.sh subnets.txt"
    exit 1
fi
subnet_file="$1"
if [[ ! -f "$subnet_file" ]]; then
    echo "[ERROR] The specified file does not exist: $subnet_file"
    exit 1
fi
results_file=$(mktemp)
warnings_file=$(mktemp)
scan_subnet() {
    local subnet=$1
    echo "[$subnet] Scanning for active hosts..." >> "$results_file"
    active_ips=$(nmap -sn --host-timeout 500ms --max-retries 2 -T5 "$subnet" | grep "Nmap scan report" | awk '{print $5}')
    if [[ -z "$active_ips" ]]; then
        echo "[WARNING] No active hosts found in $subnet!" >> "$warnings_file"
    else
        echo "[$subnet] Active hosts:" >> "$results_file"
        echo "$active_ips" >> "$results_file"
    fi
    echo "---------------------------" >> "$results_file"
}
main() {
    echo "Subnet list file: $subnet_file"
    echo "---------------------------"
    > "$results_file"
    > "$warnings_file"
    while IFS= read -r subnet; do
        [[ -z "$subnet" || "$subnet" == \#* ]] && continue
        scan_subnet "$subnet" &
    done < "$subnet_file"
    wait
    cat "$results_file"
    if [[ -s "$warnings_file" ]]; then
        echo "==========================="
        echo "🚨 Unreachable Subnets 🚨"
        cat "$warnings_file"
    fi
    rm -f "$results_file" "$warnings_file"
}
main
