# Github CI/CD

> Single workflow that builds and pushes all Docker image variants (app, lite, debian) using a matrix strategy.

## Workflow

### `build.yml`

Triggers: `push` on master, `pull_request` (test only, nothing is pushed), weekly cron (Monday `1:00 UTC`), manual dispatch.

| Job | Description |
|-----|-------------|
| `version` | Extracts the EarnApp version from BrightData's install script |
| `build` | Per variant (matrix): builds amd64 and runs `tests/smoke.sh` on it, then — except on PRs — builds all platforms from the same cache and pushes them |
| `update-readme` | Syncs `README.md` to Docker Hub description (currently disabled) |

The version is passed as the `EARNAPP_VERSION` build arg: `build/common/fetch-earnapp.sh` fails the build if BrightData serves another version, and it keys the layer cache (`type=gha`, one scope per variant) so a new release is never served from cache.

Run the same smoke tests locally with `make test-all` (or `make test-lite`, ...).
To dry-run the `build` job against a private registry: `make test-registry REGISTRY=host:5000 BUILDER=<buildx builder> [VARIANTS=lite] [PLATFORMS=linux/arm64]`.

### Build matrix

| Variant | Dockerfile | Tags | Platforms |
|---------|------------|------|-----------|
| `app` | `build/app` (ubuntu:24.04) | `latest`, `<version>` | amd64, arm/v7, arm64 |
| `lite` | `build/lite` (ubuntu:24.04) | `lite`, `lite-<version>` | amd64, arm/v7, arm64 |
| `debian` | `build/app` + `BASE_IMAGE=debian:trixie-slim` | `debian`, `debian-<version>` | amd64, arm/v7, arm64 |

## Dependencies

### Github

- [actions/checkout@v6](https://github.com/actions/checkout)

### Docker

- [docker/setup-qemu-action@v4](https://github.com/docker/setup-qemu-action)
- [docker/setup-buildx-action@v4](https://github.com/docker/setup-buildx-action)
- [docker/login-action@v4](https://github.com/docker/login-action)
- [docker/build-push-action@v7](https://github.com/docker/build-push-action)

### Others

- [peter-evans/dockerhub-description@v5](https://github.com/peter-evans/dockerhub-description)

## Secrets

| Secret | Usage |
|--------|-------|
| `DOCKERHUB_TOKEN` | Docker Hub PAT (Personal Access Token, Read & Write) of the `venatum` account |

## Runners

- `ubuntu-latest`
