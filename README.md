# EarnApp Docker

### Unofficial Docker Image for [EarnApp](https://earnapp.com)

> **Note:** This is an unofficial build and comes with no warranty of any kind.
> By using this image you also agree to BrightData's terms and conditions.

Supports **amd64**, **ARM64** and **ARMv7** (including Docker on Windows/WSL).

## Support

If you don't have an EarnApp account yet, you can support this project by signing up through my [referral link](https://earnapp.com/i/r23y2mk). It doesn't change anything for you but it helps me earn a small percentage. [How does the referral program work?](https://help.earnapp.com/hc/en-us/articles/10232037405073-How-does-the-referral-program-work)

## Available Tags

| Tag      | Description                            | Update frequency |
|----------|----------------------------------------|------------------|
| `latest` | Standard image (systemd, Ubuntu)       | Weekly           |
| `debian` | Standard image (systemd, Debian)       | Weekly           |
| `lite`   | Non-systemd, requires an existing UUID | Weekly           |

## Quick Start

### Docker Run

```bash
mkdir $HOME/earnapp-data

docker run -d --privileged --cgroupns=host \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  -v $HOME/earnapp-data:/etc/earnapp \
  --name earnapp venatum/earnapp
```

The UUID is generated on first start and stored in the `/etc/earnapp` volume, so it survives restarts and container recreation as long as you keep that volume. Get it and link the device to your account by opening `https://earnapp.com/r/<your-uuid>` while logged in:

```bash
docker exec -it earnapp earnapp showid
```

### Docker Compose

```yml
services:
  app:
    image: venatum/earnapp
    privileged: true
    cgroup: host
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
      - ./etc:/etc/earnapp
```

```bash
docker-compose up -d
docker-compose exec app earnapp showid
```

### Lite Version

Use `lite` if you don't want to run the container privileged or encounter [systemd issues](https://github.com/venatum/EarnApp-Docker/issues/2). You must provide your own UUID.

**Get a UUID** — either reuse the full id of an existing device (`earnapp showid`; the dashboard only shows a shortened one), or generate a new one:

```bash
echo "sdk-node-$(openssl rand -hex 16)"
```

Use one UUID per container: two devices sharing an id are seen as a single one. Once the container is running, link it to your account by opening `https://earnapp.com/r/<your-uuid>` while logged in.

**Docker Run:**

```bash
docker run -d -e EARNAPP_UUID='sdk-node-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' \
  --name earnapp venatum/earnapp:lite
```

**Docker Compose:**

```yml
services:
  app:
    image: venatum/earnapp:lite
    environment:
      EARNAPP_UUID: sdk-node-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```
