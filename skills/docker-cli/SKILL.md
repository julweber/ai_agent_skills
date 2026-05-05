---
name: docker-cli
description: |
  Expert Docker CLI reference — containers, images, buildx, compose, networking, volumes, security, multi-platform builds, and troubleshooting. Use this when working with docker containers. Triggers on: docker, container, image, volume, network, compose, Dockerfile, build, pull, push, registry, docker-compose, K8s migration, k3d, kind.
---

# Docker CLI Skill

You are an expert at the `docker` and `docker-compose` CLIs — including modern BuildKit features via `buildx`. Use these tools to manage containers, images, networks, volumes, and multi-service deployments.

## Reference Documents

- **Full CLI cheat sheet** — `references/cheat-sheet.md` . Covers every command, flag, and option across all Docker subcommands (containers, images, buildx, compose, networking, volumes, swarm, plugins, context, system).

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

## Dockerfile Best Practices

### Writing efficient Dockerfiles

**Multi-stage builds** — separate build environment from runtime to reduce image size:
```dockerfile
# Build stage
FROM golang:1.22-bookworm AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 go build -o myapp .

# Runtime stage
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/myapp /usr/local/bin/myapp
USER 1000:1000
ENTRYPOINT ["myapp"]
```

**Layer caching strategy** — order instructions to maximize cache hits:
- Copy `go.mod` / `package.json` / `requirements.txt` first, then `RUN install`
- Copy application source code last (changes most frequently)
- Use `.dockerignore` to exclude unnecessary files from the build context

**.dockerignore essentials:**
```
.git
.gitignore
node_modules
__pycache__
*.md
.env
.dockerignore
Dockerfile
dist
build
```

## Build & Images: `buildx` / `image`

### Building images — modern build pipeline via `docker buildx`

BuildKit offers parallel stages, cache management, multi-platform builds, and security attestations.

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

# Security attestations (SLSA compliance)
--attest type=provenance,mode=max,version=v1          # build provenance metadata
--attest type=sbom                                      # software bill of materials
--provenance=mode=max                                   # shorthand for provenance
--sbom                                                  # shorthand for SBOM

# BuildKit advanced options
--build-context name=base,src=../shared-library         # additional build contexts
--target builder                                        # build to a specific stage
--iidfile image-id.txt                                  # write image ID to file
--metadata-file build-meta.json                         # write build metadata
```

### Image management: `pull` / `push` / `inspect` / `prune` / `tag`

```bash
docker image inspect --format='{{json .Config.Env}}' myimage    # query metadata
docker history myimage -v                                          # layer sizes & diff
docker save myimage:tag -o ./myimage.tar                         # export for offline use
docker load -i myimage.tar                                       # import from archive

# Tagging & pushing to registries
docker tag myapp:latest registry.example.com/myapp:v1.2.3         # tag for registry
docker push registry.example.com/myapp:v1.2.3                     # push specific tag
docker push registry.example.com/myapp:v1.2.3 --all-tags          # push all tags
docker pull registry.example.com/myapp:v1.2.3 --platform linux/amd64  # pull for specific arch
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
docker compose up --scale web=3                    # scale a service
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

### Compose service configuration patterns

```yaml
# docker-compose.yml example
services:
  web:
    image: myapp:latest
    restart: unless-stopped                                    # restart policy
    ports:
      - "8080:80"
    environment:
      - NODE_ENV=production
    env_file: .env                                             # external env file
    depends_on:
      db:
        condition: service_healthy                             # wait for healthcheck
    volumes:
      - ./src:/app/src:ro                                      # bind mount
      - data:/data                                             # named volume
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
        reservations:
          cpus: '0.25'
          memory: 128M
      restart_policy:
        condition: on-failure
        max_attempts: 3
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    networks:
      - frontend

  db:
    image: postgres:16
    restart: always
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password         # secret file mount
    secrets:
      - db_password
    configs:
      - postgresql.conf
    networks:
      - frontend

volumes:
  data:
  pgdata:

secrets:
  db_password:
    file: ./secrets/db_password.txt

configs:
  postgresql.conf:
    file: ./configs/postgresql.conf

networks:
  frontend:
    driver: bridge
```

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

## Docker Exec & File Transfer

```bash
docker exec -it <container> sh                              # interactive shell
docker exec -it -u root <container> sh                      # run as root
docker exec -it -w /app <container> bash -c "ls -la"        # one-shot command in working dir
docker exec -d <container> <cmd>                            # detached exec (returns immediately)
docker exec -e MYVAR=value <container> cmd                  # pass env vars to exec
docker exec -i -t --privileged <container> cmd              # privileged exec

# Copy files to/from containers
docker cp <container>:/path/to/file ./local_file            # extract from container
docker cp ./local_file <container>:/path/to/dest            # inject into container
docker cp -a <container>:/path ./local_dir                  # preserve uid/gid info
docker cp -L ./src <container>:/dest                        # follow symlinks
```

## Docker Secrets & Configs

> **Note:** `docker secret` and `docker config` are Swarm cluster management commands — run on a manager node.

```bash
# Secrets (sensitive data: passwords, keys, certs)
docker secret create mydb-pass ./password.txt               # create from file
docker secret ls                                            # list secrets
docker secret inspect mydb-pass                             # inspect details
docker secret rm mydb-pass                                  # remove secret

# Configs (non-sensitive configuration: nginx.conf, app.yaml)
docker config create nginx-conf ./nginx.conf                # create from file
docker config ls                                            # list configs
docker config inspect nginx-conf                            # inspect details
docker config rm nginx-conf                                 # remove config

# In docker-compose.yml:
services:
  app:
    secrets:
      - mydb-pass
      source: mydb-pass                                    # map to container secret
    configs:
      - nginx-conf
```

## Common Patterns & Gotchas

1. **`--detach-keys`** — Override Ctrl+C escape sequence to avoid conflicting with your editor (e.g., `Ctrl+q q`)
2. **Named vs anonymous volumes** — Named (`-v data:/data`) persist after rm; anonymous do not unless you use `--rm`
3. **`docker exec -d`** runs detached and returns immediately, useful for background tasks in a running container
4. **Build cache sharing** via `buildx bake` is more efficient than repeated single-image builds
5. **Profile-based compose** (`--profile`) enables environment-specific service activation (dev/test/prod)
6. **Device I/O limits** (`--device-read-bps`, `--device-write-iops`) require host device access and may not work on all configurations (e.g., containers without direct device access)

## Troubleshooting

### Container OOM Killed
```bash
docker inspect --format='{{.State.OOMKilled}}' <container>   # check if OOM
docker logs --tail 50 <container>                            # check for OOM messages
# Fix: increase --memory limit or optimize container memory usage
```

### Port Already in Use
```bash
ss -tlnp | grep :80                                          # find what's using the port
# Fix: use a different host port (-p 8080:80) or stop the conflicting service
```

### Bind Mount Permission Denied
```bash
ls -la /host/path                                           # check host permissions
docker inspect --format='{{.Mounts}}' <container>           # verify mount config
# Fix: chown/chmod host path, or use :ro and verify user context
```

### Image Pull Rate Limited
```
Error: toomanyrequests: You have reached your pull rate limit.
```
```bash
# Fix: authenticate with Docker Hub
docker login                                                # or use a private registry
# Free accounts: 200 pulls/6h; Anonymous: 100 pulls/6h
```

### Container Won't Start — Check Why
```bash
docker ps -a | grep <name>                                  # see exit code
docker inspect --format='{{.State.ExitCode}}' <container>   # exit code
docker logs <container>                                     # container logs
docker events --filter 'container=<name>' --since 10m       # recent events
```

### Common Exit Codes
| Code | Meaning |
|------|---------|
| 1    | Application error |
| 125  | Docker daemon error |
| 126  | Command not executable |
| 127  | Command not found |
| 134  | Abnormal termination (e.g., SIGABRT) |
| 137  | SIGKILL (often OOM kill) |
| 139  | Segmentation fault |
| 143  | SIGTERM (graceful shutdown) |
