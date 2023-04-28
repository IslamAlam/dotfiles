#!/bin/bash
# gpg --keyserver hkps://keys.openpgp.org --recv-keys 712B106A06F5ACEC

# $ gpg --import <key.asc
# $ (echo 5; echo y; echo save) |
#   gpg --command-fd 0 --no-tty --no-greeting -q --edit-key "$(
#   curl https://keybase.io/imansour/pgp_keys.asc | gpg --list-packets |
#   awk '$1=="keyid:"{print$2;exit}')" trust 

# To import keybase gpg keys
# keybase pgp pull-private
# keybase pgp push-private
### Import public keys from keybase
curl https://keybase.io/imansour/pgp_keys.asc | gpg --import

### Trust all import keys from keybase
curl https://keybase.io/imansour/pgp_keys.asc | gpg --list-packets | grep -oP '(?<=keyid )(\w+)' | while read -r line ; do
    echo "Trusting $line"
    # your code goes here
    (echo 5; echo y; echo save) |
  gpg --command-fd 0 --no-tty --no-greeting -q --edit-key "$line" trust 
done
