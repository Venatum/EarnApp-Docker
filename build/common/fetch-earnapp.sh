#!/usr/bin/env bash
# Installs /usr/bin/earnapp with BrightData's official script, checks its version and leaves
# no device state in the image (the uuid must be created or provided at runtime).
# Usage: fetch-earnapp.sh [expected-version]
set -euo pipefail

EXPECTED_VERSION="${1:-}"

curl -sfL https://brightdata.com/static/earnapp/install.sh -o /tmp/install.sh
# The script ends with `earnapp install`, which may fail in a build (no running systemd):
# its exit code is only reported, the installed binary is what gets verified below.
bash /tmp/install.sh -y || echo "[fetch-earnapp] install.sh exited with $? (ignored, checking the binary instead)"

version=$(/usr/bin/earnapp --version)
echo "[fetch-earnapp] Installed: $version"
if [[ -n "$EXPECTED_VERSION" && "$version" != *" $EXPECTED_VERSION" ]]; then
    echo "[fetch-earnapp] Expected EarnApp $EXPECTED_VERSION, got '$version'" >&2
    exit 1
fi

find /etc/earnapp -mindepth 1 -delete
rm -rf /tmp/* /tmp/.[!.]*
