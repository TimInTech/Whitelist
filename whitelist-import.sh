#!/bin/bash
# Whitelist Import Script for Pi-hole
# Usage: sudo ./whitelist-import.sh

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (sudo)" 
   exit 1
fi

FILE="Whitelist.combined.txt"
if [ ! -f "$FILE" ]; then
    echo "File $FILE not found!"
    exit 1
fi

while IFS= read -r domain
do
    if [[ "$domain" =~ ^#.*$ || -z "$domain" ]]; then
        continue
    fi
    pihole -w "$domain"
done < "$FILE"
