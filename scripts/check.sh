#!/bin/sh
# TLS behavior is checked through its real HTTP consumers, including UBSan.
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
http=${HTTP_PACKAGE:-"$root/../zen-http"}
test -f "$http/scripts/check.sh" || {
    echo 'Clone zen-http beside zen-openssl and prepare its dependencies; see README.md.' >&2
    exit 1
}
cd "$http"
sh scripts/check.sh
