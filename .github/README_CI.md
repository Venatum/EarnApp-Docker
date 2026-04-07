# Github CI/CD

> Single workflow that builds and pushes all Docker image variants (app, lite, debian) using a matrix strategy.

## Workflow

### `build.yml`

Triggers: `push` on master, daily cron (`3:10 UTC`), manual dispatch.

| Job | Description |
|-----|-------------|
| `version` | Downloads EarnApp binary and extracts the version string |
| `build` | Builds & pushes 3 variants in parallel via matrix |
| `update-readme` | Syncs `README.md` to Docker Hub description |

### Build matrix

| Variant | Tags | Platforms |
|---------|------|-----------|
| `app` | `latest`, `<version>` | amd64, arm/v7, arm64 |
| `lite` | `lite`, `lite-<version>` | amd64, arm/v7, arm64 |
| `debian` | `debian`, `debian-<version>` | amd64, arm/v7, arm/v6, arm64 |

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
| `DOCKER_USER` | Docker Hub username |
| `DOCKER_PASSWORD` | Docker Hub PAT (Personal Access Token) |

## Runners

- `ubuntu-latest`
