# EarnApp Docker

### Unofficial Docker Image for [EarnApp](https://earnapp.com)

> **Note:** This is an unofficial build and comes with no warranty of any kind.
> By using this image you also agree to BrightData's terms and conditions.

Supports **amd64**, **ARM64** and **ARMv7** (including Docker on Windows/WSL).

## Support

If you don't have an EarnApp account yet, you can support this project by signing up through my [referral link](https://earnapp.com/i/r23y2mk). It doesn't change anything for you but it helps me earn a small percentage. [How does the referral program work?](https://help.earnapp.com/hc/en-us/articles/10232037405073-How-does-the-referral-program-work)

## Available Tags

| Tag | Description | Update frequency |
|-----|-------------|-----------------|
| `latest` | Standard image (systemd) | Daily |
| `hourly-latest` | Same as latest | Hourly |
| `lite` | Non-systemd, requires an existing UUID | Daily |

## Quick Start

### Docker Run

```bash
mkdir $HOME/earnapp-data

docker run -d --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -v $HOME/earnapp-data:/etc/earnapp \
  --name earnapp venatum/earnapp
```

Get your UUID and register it on the [EarnApp Dashboard](https://earnapp.com/dashboard):

```bash
docker exec -it earnapp earnapp showid
```

### Docker Compose

```yml
version: "3.3"
services:
  app:
    image: venatum/earnapp
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
      - ./etc:/etc/earnapp
```

```bash
docker-compose up -d
docker-compose exec app earnapp showid
```

### Lite Version

Use `lite` if you don't want to run the container privileged or encounter [systemd issues](https://github.com/venatum/EarnApp-Docker/issues/2). You must provide your own UUID.

**Docker Run:**

```bash
docker run -d -e EARNAPP_UUID='sdk-node-XXXXXXXXXXXXXXXXXXX' \
  --name earnapp venatum/earnapp:lite
```

**Docker Compose:**

```yml
version: "3.3"
services:
  app:
    image: venatum/earnapp:lite
    environment:
      EARNAPP_UUID: YOUR_NODE_ID_HERE
```
