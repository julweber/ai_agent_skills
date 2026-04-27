---
name: docker-cli
description: |
  Expert Docker CLI reference. Use when working with containers, images, builds, or compose — including resource limits (CPU/memory/bandwidth), security profiles, healthchecks, networking, volumes/bind-mounts, and multi-platform builds via buildx/BuildKit. Triggers on: docker, container, image, volume, network, compose, Dockerfile, build, pull, push, registry, K8s migration, k3d, kind.
---

# Docker CLI Skill

You are an expert at the `docker` and `docker-compose` CLIs — including modern BuildKit features via `buildx`. Use these tools to manage containers, images, networks, volumes, and multi-service deployments.

## Quick Reference: Most Common Commands

```bash
# Container lifecycle
docker run -d --name myapp nginx                          # detached container
docker ps                                                 # running only
docker ps -a                                              # all containers
docker logs -f <container>                                # follow logs
docker exec -it <container> sh                            # interactive shell
docker stop/start/rm <container>

# Build & Images
docker buildx build -t myapp:latest . --load             # modern build with cache
docker pull/push myimage                                  # registry operations
docker image prune -a -f                                  # clean unused images

# Compose (multi-service)
docker compose up -d                                      # start all services
docker compose down                                       # stop & remove everything
docker compose --profile dev up                           # profile-based startup
```

## Container Lifecycle: `run` / `start` / `stop` / `rm`

### Running a container — key options by use case

**Basic execution:** `-d -i -t -a/-A` (detach, interactive stdin, pseudo-TTY)

**Networking & ports:**
```bash
-p 80:80 -p 443:443                                   # host port mapping
--network mynet --name myapp                            # user-defined network + alias
```

**Volumes & filesystems:**
```bash
-v data:/data                                           # named volume
-v $(pwd)/src:/usr/src/app:ro                           # bind mount (read-only)
--mount type=bind,source=/host,target=/container        # extended syntax
```

**Resources — control CPU/memory/disk I/O and limits:**
```bash
-c 512                                                # relative CPU shares (0–default; higher = more CPU)
--cpus=4                                              # hard cap: number of CPUs
--memory=4g --memory-reservation=3g                   # memory limit + soft reservation
-m 4g                                                 # shorthand for memory

# Device I/O limits
--device-read-bps /dev/sda:10mb                       # read rate from device
--device-write-iops /dev/vdb:500                      # write IO/s limit on device
```

**Security & isolation:**
```bash
-u root                                              # run as specific user (uid:gid format)
--userns=host                                        # share host's user namespace
--security-opt=no-new-privileges:true                # prevent privilege escalation
--cap-add=NET_ADMIN                                  # add Linux capability
--privileged                                         # full access (avoid in prod)
--read-only                                          # read-only rootfs
--init                                               # init process for signal forwarding + zombie reaping
```

**Healthchecks (critical for reliability):**
```bash
--health-cmd="curl -f http://localhost/ || exit 1"    # check command
--health-interval=30s                                  # how often to run
--health-start-period=60s                              # grace period before retries count
--health-retries=3                                     # consecutive failures to declare unhealthy
```

**Restart policies:** `--restart=on-failure:5` | `always` | `unless-stopped` | `no` (default)

## Build & Images: `buildx` / `image`

### Building images — modern build pipeline via `docker buildx`

BuildKit offers parallel stages, cache management, multi-platform builds, and attestation.

```bash
# Standard build with cache
docker buildx build -t myapp:latest . --load          # load to local docker (default)
docker buildx build -t myapp:latest . --push           # push directly to registry
docker buildx build -t myapp:latest . --output=type=local,dest=.   # output as tarball

# Multi-platform
docker buildx build --platform linux/amd64,linux/arm64 -t myapp:multi . --push

# Caching strategies
--cache-from type=registry,ref=myapp:cache            # pull cache from registry
--cache-to type=local,dest=/tmp/build-cache           # export to directory
--cache-to type=inline                                  # inline cache (embedded in image)

# BuildKit features
--build-arg BUILDKIT_INLINE_CACHE=1                    # enable inline caching in Dockerfile
--secret id=mykey,src=./private_key                   # mount secrets at build time
--ssh default                                           # expose SSH agent for private deps
```

### Image management: `pull` / `push` / `inspect` / `prune`

```bash
docker image inspect --format='{{json .Config.Env}}' myimage    # query metadata
docker history myimage -v                                          # layer sizes & diff
docker save myimage:tag -o ./myimage.tar                         # export for offline use
docker load -i myimage.tar                                       # import from archive
```

### Bake mode (YAML-based batch builds) — `buildx bake`

```bash
# docker-bake.hcl
target "default" {
  context = "."
  output  = ["type=registry"]
}

# Run it
docker buildx bake -f docker-bake.hcl
docker buildx bake --no-cache --push            # rebuild without cache + push all targets
```

## Compose: multi-service orchestration

### Starting services — `docker compose up` / `down`

```bash
docker compose up -d                               # detached mode (default)
docker compose down -v                             # stop, remove containers + named volumes
docker compose --profile dev --profile test up     # activate only matching profiles
docker compose up --build                          # rebuild images before starting
docker compose up --force-recreate                 # recreate even if config unchanged

# Scale & manage services
docker compose scale web=3                         # (Compose V1 syntax, still works)
docker compose ps                                  # list running services
```

### Key options

| Option | Use case |
|--------|----------|
| `--dry-run` | Preview commands without executing |
| `--no-build` | Skip image building |
| `--remove-orphans` | Remove containers not in compose file |
| `--abort-on-container-exit` | Stop all if one exits |
| `--exit-code-from=web` | Return web service exit code on failure |

## Network & Volume Management

```bash
# Networks
docker network create --driver bridge mynet
docker network ls                                          # list networks
docker network inspect --format='{{json .IPAM.Config}}' mynet  # subnet info
docker network connect/disconnect <container> <network>    # hot-swap networking

# Volumes (persistent data)
docker volume create mydata                                # named volumes
docker volume ls -f 'dangling=true'                       # unused volumes
docker volume prune -a                                     # remove all unused
```

## System Commands: `info` / `events` / `df`

```bash
docker info                                                # daemon config, storage driver, runtime details
docker events --filter 'type=container'                   # real-time container events (for monitoring)
docker system df                                           # disk usage by images/containers/volumes
docker system prune -a --volumes                         # aggressive cleanup: remove unused + volumes
```

## Common Patterns & Gotchas

1. **`--detach-keys`** — Override Ctrl+C escape sequence to avoid conflicting with your editor (e.g., `Ctrl+q q`)
2. **Named vs anonymous volumes** — Named (`-v data:/data`) persist after rm; anonymous do not unless you use `--rm`
3. **`docker exec -d`** runs detached and returns immediately, useful for background tasks in a running container
4. **Build cache sharing** via `buildx bake` is more efficient than repeated single-image builds
5. **Profile-based compose** (`--profile`) enables environment-specific service activation (dev/test/prod)
