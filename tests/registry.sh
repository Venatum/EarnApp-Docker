#!/usr/bin/env bash
# Dry run of the CI `build` job against a private registry: builds every variant for all its
# platforms, pushes it to $REGISTRY, checks the pushed manifests, then pulls the images back
# and runs tests/smoke.sh on them.
# Usage: REGISTRY=host:port BUILDER=name tests/registry.sh [variant...]   (default: app debian lite)
# Env:   REGISTRY           plain-HTTP registry to push to, e.g. myhost.local:5000
#        BUILDER            buildx builder able to build every platform and allowed to push to $REGISTRY
#        PLATFORMS          override the matrix platforms, e.g. linux/arm64
#        SMOKE_PLATFORMS    platforms to smoke test after pull, default: the host platform
set -euo pipefail

cd "$(dirname "$0")/.."

REGISTRY="${REGISTRY:?Set REGISTRY, e.g. REGISTRY=myhost.local:5000}"
BUILDER="${BUILDER:?Set BUILDER to a buildx builder that can push to $REGISTRY}"
REPO="$REGISTRY/earnapp"
HOST_PLATFORM="linux/$(docker version -f '{{.Server.Arch}}')"
SMOKE_PLATFORMS="${SMOKE_PLATFORMS:-$HOST_PLATFORM}"

# Keep in sync with the `build` matrix of .github/workflows/build.yml
# variant|dockerfile|build-arg|tag|version tag prefix|platforms
MATRIX=(
    "app|app||latest||linux/amd64,linux/arm/v7,linux/arm64"
    "debian|app|BASE_IMAGE=debian:trixie-slim|debian|debian-|linux/amd64,linux/arm/v7,linux/arm64"
    "lite|lite||lite|lite-|linux/amd64,linux/arm/v7,linux/arm64"
)

VARIANTS=("$@")
[[ ${#VARIANTS[@]} -eq 0 ]] && VARIANTS=(app debian lite)

VERSION=$(curl -sfL https://brightdata.com/static/earnapp/install.sh | grep -oE '^VERSION="[^"]+' | cut -d'"' -f2)
test -n "$VERSION"
echo "== EarnApp version: $VERSION"

# Platforms listed in the pushed manifest list, one per line (attestations excluded)
manifest_platforms() {
    curl -sf -H 'Accept: application/vnd.oci.image.index.v1+json' \
        -H 'Accept: application/vnd.docker.distribution.manifest.list.v2+json' \
        "http://$REGISTRY/v2/earnapp/manifests/$1" |
        python3 -c '
import json, sys
for m in json.load(sys.stdin).get("manifests", []):
    p = m.get("platform", {})
    if p.get("os") != "unknown":
        variant = None if p.get("variant") == "v8" else p.get("variant")
        print("/".join(filter(None, [p.get("os"), p.get("architecture"), variant])))
'
}

FAILED=()
for entry in "${MATRIX[@]}"; do
    IFS='|' read -r variant dockerfile build_arg tag version_prefix platforms <<< "$entry"
    [[ " ${VARIANTS[*]} " == *" $variant "* ]] || continue
    platforms="${PLATFORMS:-$platforms}"

    echo
    echo "######## $variant → $REPO:$tag ($platforms)"
    build_args=(--build-arg "EARNAPP_VERSION=$VERSION")
    [[ -n "$build_arg" ]] && build_args+=(--build-arg "$build_arg")
    if ! docker buildx build --builder "$BUILDER" --platform "$platforms" \
        -f "build/$dockerfile/Dockerfile" "${build_args[@]}" \
        -t "$REPO:$tag" -t "$REPO:$version_prefix$VERSION" --push build; then
        FAILED+=("$variant: build")
        continue
    fi

    pushed=$(manifest_platforms "$tag" | sort | tr '\n' ' ') || true
    echo "== Pushed platforms: $pushed"
    for p in ${platforms//,/ }; do
        [[ " $pushed " == *" $p "* ]] || FAILED+=("$variant: $p missing from manifest")
    done

    for p in ${SMOKE_PLATFORMS//,/ }; do
        echo "== Smoke test $REPO:$tag on $p"
        if ! docker pull -q --platform "$p" "$REPO:$tag" > /dev/null; then
            FAILED+=("$variant: pull on $p")
            continue
        fi
        DOCKER_DEFAULT_PLATFORM="$p" EXPECTED_VERSION="$VERSION" tests/smoke.sh "$variant" "$REPO:$tag" ||
            FAILED+=("$variant: smoke test on $p")
    done
done

echo
if ((${#FAILED[@]})); then
    printf '✘ %s\n' "${FAILED[@]}"
    exit 1
fi
echo "✔ All variants built, pushed to $REGISTRY and smoke tested (${SMOKE_PLATFORMS})"
