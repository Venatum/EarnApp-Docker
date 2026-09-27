#!/usr/bin/env bash
# Smoke tests for an EarnApp image variant.
# Usage: tests/smoke.sh <app|debian|lite> [image]
# Env:   EXPECTED_VERSION  fail if `earnapp --version` does not contain it
set -uo pipefail

VARIANT="${1:?Usage: $0 <app|debian|lite> [image]}"
IMAGE="${2:-venatum/earnapp:${VARIANT/app/latest}}"
PREFIX="earnapp-smoke-$$"
FAILURES=0

pass() { echo "  ✔ $1"; }
fail() { echo "  ✘ $1"; FAILURES=$((FAILURES + 1)); }
check() {
    local name=$1; shift
    if "$@"; then pass "$name"; else fail "$name"; fi
}

cleanup() {
    docker ps -aq --filter "name=^${PREFIX}" | xargs -r docker rm -f > /dev/null
    docker volume ls -q --filter "name=^${PREFIX}" | xargs -r docker volume rm > /dev/null
}
trap cleanup EXIT

in_image() { docker run --rm --entrypoint sh "$IMAGE" -c "$1"; }

# Retry "$@" every second for up to $1 seconds.
wait_for() {
    local timeout=$1; shift
    for ((i = 0; i < timeout; i++)); do
        "$@" > /dev/null 2>&1 && return 0
        sleep 1
    done
    return 1
}

echo "== Image checks ($IMAGE)"

check "earnapp binary is installed" in_image 'test -x /usr/bin/earnapp'
version=$(in_image 'earnapp --version' 2> /dev/null)
check "earnapp --version runs (got '${version}')" test -n "$version"
if [[ -n "${EXPECTED_VERSION:-}" ]]; then
    check "version matches ${EXPECTED_VERSION}" grep -qF "$EXPECTED_VERSION" <<< "$version"
fi
check "no uuid baked into the image" in_image 'test ! -e /etc/earnapp/uuid'
check "no registration state baked into the image" \
    in_image 'test ! -e /etc/earnapp/registered && test ! -e /etc/earnapp/status'
check "coreutils install is untouched" in_image 'install --version | grep -q coreutils'

if [[ "$VARIANT" == "lite" ]]; then
    echo "== Runtime checks (lite)"

    docker run --name "${PREFIX}-nouuid" "$IMAGE" > /dev/null 2>&1
    check "exits with code 1 without EARNAPP_UUID" \
        test "$(docker inspect -f '{{.State.ExitCode}}' "${PREFIX}-nouuid")" = 1
    check "explains that EARNAPP_UUID is missing" \
        bash -c "docker logs ${PREFIX}-nouuid 2>&1 | grep -q 'EARNAPP_UUID not set'"

    uuid="sdk-node-$(openssl rand -hex 16)"
    docker run -d --name "${PREFIX}-run" -e EARNAPP_UUID="$uuid" "$IMAGE" > /dev/null
    sleep 15
    check "keeps running with EARNAPP_UUID" \
        test "$(docker inspect -f '{{.State.Running}}' "${PREFIX}-run")" = true
    check "uses the provided uuid" \
        test "$(docker exec "${PREFIX}-run" cat /etc/earnapp/uuid)" = "$uuid"

    start=$(date +%s)
    docker stop "${PREFIX}-run" > /dev/null
    stop_duration=$(($(date +%s) - start))
    check "stops on SIGTERM without waiting for SIGKILL (${stop_duration}s)" test "$stop_duration" -lt 5

    # Replace the binary with one whose `run` crashes: the entrypoint must back off, not exit.
    crashing_bin=$(mktemp)
    # shellcheck disable=SC2016  # $1 belongs to the fake binary, not to this script
    printf '#!/bin/sh\n[ "$1" = run ] && exit 1\nexit 0\n' > "$crashing_bin"
    chmod a+rx "$crashing_bin"
    docker run -d --name "${PREFIX}-crash" -e EARNAPP_UUID="$uuid" \
        -v "$crashing_bin:/usr/bin/earnapp:ro" "$IMAGE" > /dev/null
    sleep 8
    check "keeps retrying when earnapp run crashes" \
        test "$(docker inspect -f '{{.State.Running}}' "${PREFIX}-crash")" = true
    check "backs off between crashes" \
        bash -c "docker logs ${PREFIX}-crash 2>&1 | grep -q 'backing off'"
    rm -f "$crashing_bin"
else
    echo "== Runtime checks ($VARIANT, systemd)"

    start_systemd() {
        docker run -d --name "${PREFIX}-run" --privileged --cgroupns=host \
            -v /sys/fs/cgroup:/sys/fs/cgroup:rw -v "${PREFIX}-data:/etc/earnapp" "$IMAGE" > /dev/null
    }
    showid() { docker exec "${PREFIX}-run" earnapp showid 2> /dev/null | grep -oE 'sdk-node-[0-9a-f]{32}'; }

    start_systemd
    check "systemd boots" wait_for 60 bash -c \
        "docker exec ${PREFIX}-run systemctl is-system-running | grep -qE '^(running|degraded)$'"
    check "earnapp service is active" wait_for 60 \
        docker exec "${PREFIX}-run" systemctl is-active --quiet earnapp
    check "a uuid is generated at first start" wait_for 30 showid
    first_uuid=$(showid)

    # Recreating the container on the same volume must keep the device id (otherwise it must be re-registered).
    docker rm -f "${PREFIX}-run" > /dev/null
    start_systemd
    check "earnapp service is active after recreation" wait_for 60 \
        docker exec "${PREFIX}-run" systemctl is-active --quiet earnapp
    wait_for 30 showid
    check "uuid survives container recreation" test -n "$first_uuid" -a "$(showid)" = "$first_uuid"

    if ((FAILURES)); then
        echo "-- container logs (tail)"
        docker exec "${PREFIX}-run" journalctl --no-pager -n 30 2> /dev/null || docker logs --tail 30 "${PREFIX}-run"
    fi
fi

echo
if ((FAILURES)); then
    echo "✘ $FAILURES check(s) failed for $IMAGE"
    exit 1
fi
echo "✔ All checks passed for $IMAGE"
