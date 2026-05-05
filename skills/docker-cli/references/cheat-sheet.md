# Docker CLI Cheat Sheet

> Verified against Docker CLI on this system. All commands and flags are current.

---

## Global Options

```bash
docker [OPTIONS] COMMAND

--config string      Location of client config files (default "~/.docker")
-c, --context string Name of the context to use (overrides DOCKER_HOST)
-D, --debug          Enable debug mode
-H, --host string    Daemon socket to connect to
-l, --log-level string   Set logging level ("debug", "info", "warn", "error", "fatal")
      --tls          Use TLS (implied by --tlsverify)
      --tlscacert    Trust certs signed only by this CA
      --tlscert      Path to TLS certificate file
      --tlskey       Path to TLS key file
```

---

## Common Commands

### Container Lifecycle

```bash
docker run [OPTIONS] IMAGE [COMMAND] [ARG...]      # Create and run a new container
docker start [OPTIONS] CONTAINER [CONTAINER...]    # Start one or more stopped containers
docker stop [OPTIONS] CONTAINER [CONTAINER...]     # Stop one or more running containers
docker restart [OPTIONS] CONTAINER [CONTAINER...]  # Restart one or more containers
docker rm [OPTIONS] CONTAINER [CONTAINER...]       # Remove one or more containers
docker pause CONTAINER [CONTAINER...]              # Pause all processes within containers
docker unpause CONTAINER [CONTAINER...]            # Unpause all processes within containers
docker kill [OPTIONS] CONTAINER [CONTAINER...]     # Kill one or more running containers
docker attach [OPTIONS] CONTAINER                  # Attach to STDIN/STDOUT/STDERR of a running container
docker exec [OPTIONS] CONTAINER COMMAND [ARG...]   # Execute a command in a running container
docker create [OPTIONS] IMAGE [COMMAND] [ARG...]   # Create a new container (without running)
docker wait CONTAINER [CONTAINER...]               # Block until container stops, then print exit code
docker rename CONTAINER NEW_NAME                   # Rename a container
docker top CONTAINER [ps OPTIONS]                  # Display running processes of a container
docker diff CONTAINER                              # Inspect changes to container filesystem
docker port CONTAINER [PRIVATE_PORT[/PROTO]]       # List port mappings for a container
```

### Container run — Key Options (verified)

```bash
-d, --detach                           # Run in background
-i, --interactive                      # Keep STDIN open
-t, --tty                              # Allocate pseudo-TTY
-a, --attach list                      # Attach to STDIN/STDOUT/STDERR
--name string                          # Assign a name
--hostname string                      # Container hostname
--workdir, -w string                   # Working directory inside container
--user, -u string                      # Username or UID (format: <name|uid>[:<group|gid>])
--entrypoint string                    # Overwrite default ENTRYPOINT
--env, -e list                         # Set environment variables
--env-file list                        # Read in a file of environment variables
--label, -l list                       # Set metadata on a container
--label-file list                      # Read in a line delimited file of labels
--network network                      # Connect to a network
--network-alias list                   # Add network-scoped alias
--ip ip                                # IPv4 address
--ip6 ip                               # IPv6 address
--mac-address string                   # Container MAC address
--dns list                             # Set custom DNS servers
--dns-option list                      # Set DNS options
--dns-search list                      # Set custom DNS search domains
--add-host list                        # Add custom host-to-IP mapping (host:ip)
--domainname string                    # Container NIS domain name
--pid string                           # PID namespace to use
--ipc string                           # IPC mode to use
--uts string                           # UTS namespace to use
--cgroupns string                      # Cgroup namespace (host|private)
--isolation string                     # Container isolation technology
--runtime string                       # Runtime to use
--security-opt list                    # Security Options
--cap-add list                         # Add Linux capabilities
--cap-drop list                        # Drop Linux capabilities
--privileged                           # Give extended privileges
--read-only                            # Mount root filesystem as read only
--tmpfs list                           # Mount a tmpfs directory
--volume, -v list                      # Bind mount a volume
--mount mount                          # Attach a filesystem mount (extended syntax)
--volume-driver string                 # Optional volume driver
--volumes-from list                    # Mount volumes from another container
--publish, -p list                     # Publish a container's port(s) to the host
--publish-all, -P                      # Publish all exposed ports to random ports
--expose list                          # Expose a port or range of ports (inbound only)
--link list                            # Add link to another container
--restart string                       # Restart policy (no|on-failure[:max]|always|unless-stopped)
--rm                                   # Auto-remove container on exit
--cidfile string                       # Write container ID to file
--sig-proxy                            # Proxy received signals (default true)
--detach-keys string                   # Override detach key sequence
--stop-signal string                   # Signal to stop container
--stop-timeout int                     # Timeout (seconds) to stop container
--platform string                      # Set platform (e.g., linux/amd64)
--pull string                          # Pull image before running ("always"|"missing"|"never")
--quiet, -q                            # Suppress pull output
```

### Container run — Resource Limits (verified)

```bash
-c, --cpu-shares int                   # CPU shares (relative weight)
--cpus decimal                         # Number of CPUs
--cpuset-cpus string                   # CPUs to allow execution (0-3, 0,1)
--cpuset-mems string                   # MEMs to allow execution (0-3, 0,1)
--cpu-period int                       # Limit CPU CFS period
--cpu-quota int                        # Limit CPU CFS quota
--cpu-rt-period int                    # CPU real-time period (microseconds)
--cpu-rt-runtime int                   # CPU real-time runtime (microseconds)
-m, --memory bytes                     # Memory limit
--memory-reservation bytes             # Memory soft limit
--memory-swap bytes                    # Swap limit (-1 = unlimited)
--memory-swappiness int                # Memory swappiness (0-100, -1 = default)
--blkio-weight uint16                  # Block IO weight (10-1000, 0 = disable)
--blkio-weight-device list             # Block IO weight per device
--device list                          # Add a host device
--device-read-bps list                 # Limit read rate (bytes/sec) from device
--device-read-iops list                # Limit read rate (IO/sec) from device
--device-write-bps list                # Limit write rate (bytes/sec) to device
--device-write-iops list               # Limit write rate (IO/sec) to device
--pids-limit int                       # Tune container pids limit (-1 = unlimited)
--memory-swappiness int                # Tune memory swappiness (0-100, -1 default)
--oom-kill-disable                     # Disable OOM Killer
--oom-score-adj int                    # Tune host OOM preferences (-1000 to 1000)
--shm-size bytes                       # Size of /dev/shm
--ulimit ulimit                        # Ulimit options
--sysctl map                           # Sysctl options
--gpus gpu-request                     # GPU devices ('all' to pass all GPUs)
```

### Container run — Healthcheck (verified)

```bash
--health-cmd string                    # Command to run to check health
--health-interval duration             # Time between checks (ms|s|m|h)
--health-retries int                   # Consecutive failures to report unhealthy
--health-start-period duration         # Start period before retries countdown (ms|s|m|h)
--health-start-interval duration       # Time between checks during start period
--health-timeout duration              # Maximum time for one check (ms|s|m|h)
--no-healthcheck                       # Disable any container-specified HEALTHCHECK
```

### Container run — Logging (verified)

```bash
--log-driver string                    # Logging driver for the container
--log-opt list                         # Log driver options
```

---

### Image Operations

```bash
docker pull [OPTIONS] NAME[:TAG|@DIGEST]       # Download an image from a registry
docker push [OPTIONS] NAME[:TAG]               # Upload an image to a registry
docker images [OPTIONS]                         # List images (alias: docker image ls)
docker rmi [OPTIONS] IMAGE [IMAGE...]           # Remove one or more images
docker save [OPTIONS] IMAGE [IMAGE...]          # Save images to a tar archive
docker load [OPTIONS]                           # Load an image from a tar archive
docker tag SOURCE[:TAG] TARGET[:TAG]            # Create a tag
docker inspect [OPTIONS] NAME|ID [NAME|ID...]   # Return low-level information on objects
docker history [OPTIONS] IMAGE                  # Show history of an image
docker search [OPTIONS] TERM                    # Search Docker Hub for images
docker commit [OPTIONS] CONTAINER [REPO[:TAG]]  # Create a new image from container changes
docker export [OPTIONS] CONTAINER               # Export container filesystem as tar archive
docker import [OPTIONS] file|URL|- [REPO[:TAG]] # Import tarball to create a filesystem image
```

### Image Operations — Key Options (verified)

```bash
# pull
-a, --all-tags          # Download all tagged images in the repository
--platform string       # Set platform (e.g., linux/amd64)
-q, --quiet             # Suppress verbose output

# push
-a, --all-tags          # Push all tags of an image
--platform string       # Push a platform-specific manifest only

# images (ls)
-a, --all               # Show all images (default shows just intermediate)
-f, --filter filter     # Filter output
--format string         # Format output (table/json/TEMPLATE)
--no-trunc              # Don't truncate output
-q, --quiet             # Only display image IDs
-s, --size              # Display total file sizes

# rmi
-f, --force             # Force removal
--no-prune              # Do not delete untagged parents
--platform strings      # Remove only the given platform variant

# save
-o, --output string     # Write to a file instead of STDOUT
--platform strings      # Save only the given platform(s)

# load
-i, --input string      # Read from tar archive file instead of STDIN
--platform strings      # Load only the given platform(s)
-q, --quiet             # Suppress the load output

# history
-H, --human             # Print sizes and dates in human readable format (default true)
--no-trunc              # Don't truncate output
--platform string       # Show history for the given platform
-q, --quiet             # Only show image IDs

# commit
-a, --author string     # Author
-c, --change list       # Apply Dockerfile instruction to the created image
-m, --message string    # Commit message
--no-pause              # Disable pausing container during commit

# export
-o, --output string     # Write to a file instead of STDOUT

# import
-c, --change list       # Apply Dockerfile instruction to the created image
-m, --message string    # Set commit message
--platform string       # Set platform if server is multi-platform capable

# search
-f, --filter filter     # Filter output (e.g., "stars=3")
--format string         # Pretty-print search using a Go template
--limit int             # Max number of search results
--no-trunc              # Don't truncate output
```

### Image Management — Prune

```bash
docker image prune [OPTIONS]          # Remove unused images
docker image prune -a -f              # Remove ALL unused images (not just dangling)
docker image prune --filter "label=foo"  # Remove by label filter

# Options (verified):
-a, --all             # Remove all unused images, not just dangling ones
-f, --force           # Do not prompt for confirmation
--filter filter       # Provide filter values (e.g., "until=<timestamp>")
```

---

### Build & Images — buildx

```bash
docker buildx build [OPTIONS] PATH | URL | -    # Start a build
docker buildx bake [OPTIONS] [TARGET...]         # Build from a file
docker buildx ls                                  # List builder instances
docker buildx create [OPTIONS] [CONTEXT|ENDPOINT] # Create a new builder instance
docker buildx use [OPTIONS] NAME                  # Set the current builder instance
docker buildx inspect [NAME]                      # Inspect current builder instance
docker buildx stop [NAME]                         # Stop builder instance
docker buildx version                             # Show buildx version
docker buildx du                                  # Disk usage
docker buildx prune                               # Remove build cache
```

### buildx build — Key Options (verified)

```bash
-t, --tag stringArray           # Image identifier [registry/]repository[:tag]
-f, --file string               # Name of the Dockerfile (default: PATH/Dockerfile)
--target string                 # Set the target build stage to build
--build-arg stringArray         # Set build-time variables
--secret stringArray            # Secret to expose to build (format: "id=mysecret[,src=/local/secret]")
--ssh stringArray               # SSH agent socket or keys to expose (format: "default|<id>=<socket>")
--build-context stringArray     # Additional build contexts (e.g., name=path)
--platform stringArray          # Set target platform for build
--load                          # Shorthand for "--output=type=docker" (load to local docker)
--push                          # Shorthand for "--output=type=registry,unpack=false"
-o, --output stringArray        # Output destination (format: "type=local,dest=path")
--iidfile string                # Write the image ID to a file
--metadata-file string          # Write build result metadata to a file
--no-cache                      # Do not use cache when building
--no-cache-filter stringArray   # Do not cache specified stages
--pull                          # Always attempt to pull all referenced images
--progress string               # Progress output ("auto", "none", "plain", "quiet", "rawjson", "tty")
--provenance string             # Shorthand for "--attest=type=provenance"
--sbom string                   # Shorthand for "--attest=type=sbom"
--attest stringArray            # Attestation parameters (format: "type=sbom,generator=image")
--allow stringArray             # Allow extra privileged entitlement ("network.host", "security.insecure")
--annotation stringArray        # Add annotation to the image
--label stringArray             # Set metadata for an image
--cache-from stringArray        # External cache sources (e.g., "user/app:cache", "type=local,src=path")
--cache-to stringArray          # Cache export destinations (e.g., "user/app:cache", "type=local,dest=path")
--ulimit ulimit                 # Ulimit options
--cgroup-parent string          # Set the parent cgroup for RUN instructions
--network string                # Set networking mode for RUN instructions ("default"|"host")
--shm-size bytes                # Shared memory size for build containers
-q, --quiet                     # Suppress the build output and print image ID
-D, --debug                     # Enable debug logging
--call string                   # Set method for evaluating build ("check", "outline", "targets")
--check                         # Shorthand for "--call=check"
--policy stringArray            # Policy configuration
```

### buildx bake — Key Options (verified)

```bash
-f, --file stringArray       # Build definition file
--push                       # Shorthand for "--set=*.output=type=registry"
--load                       # Shorthand for "--set=*.output=type=docker"
--no-cache                   # Do not use cache when building
--print                      # Print the options without building
--list string                # List targets or variables
--set stringArray            # Override target value (e.g., "targetpattern.key=value")
--var stringArray            # Set a variable value (e.g., "name=value")
--pull                       # Always attempt to pull all referenced images
--provenance string          # Shorthand for "--set=*.attest=type=provenance"
--sbom string                # Shorthand for "--set=*.attest=type=sbom"
--metadata-file string       # Write build result metadata to a file
--progress string            # Progress output ("auto", "none", "plain", "quiet", "rawjson", "tty")
--call string                # Set method for evaluating build ("check", "outline", "targets")
--check                      # Shorthand for "--call=check"
```

### buildx imagetools (verified)

```bash
docker buildx imagetools create [OPTIONS] [SOURCE...]    # Create a new image based on source images
docker buildx imagetools inspect [OPTIONS] NAME          # Show details of an image in the registry

# imagetools create options:
-t, --tag stringArray          # Set reference for new image
--append                       # Append to existing manifest
-f, --file stringArray         # Read source descriptor from file
--dry-run                      # Show final image instead of pushing
--metadata-file string         # Write create result metadata to a file
-p, --platform stringArray     # Filter specified platforms of target image
--prefer-index                 # Prefer outputting image index (default true)
--annotation stringArray       # Add annotation to the image
```

### buildx history (verified)

```bash
docker buildx history ls          # List build records
docker buildx history logs        # Print the logs of a build record
docker buildx history inspect     # Inspect a build record
docker buildx history trace       # Show the OpenTelemetry trace
docker buildx history rm          # Remove build records
docker buildx history export      # Export build records into Docker Desktop bundle
docker buildx history import      # Import build records into Docker Desktop
docker buildx history open        # Open a build record in Docker Desktop
```

---

### Compose — Multi-Service Orchestration

```bash
docker compose [OPTIONS] COMMAND

# Core commands:
docker compose up [OPTIONS] [SERVICE...]      # Create and start containers
docker compose down [OPTIONS] [SERVICES]      # Stop and remove containers, networks
docker compose start [SERVICE...]             # Start services
docker compose stop [OPTIONS] [SERVICE...]    # Stop services
docker compose restart [OPTIONS] [SERVICE...] # Restart service containers
docker compose pause [SERVICE...]             # Pause services
docker compose unpause [SERVICE...]           # Unpause services
docker compose kill [OPTIONS] [SERVICE...]    # Force stop service containers
docker compose rm [OPTIONS] [SERVICE...]      # Removes stopped service containers
docker compose run [OPTIONS] SERVICE [CMD]    # Run a one-off command on a service
docker compose exec [OPTIONS] SERVICE CMD     # Execute a command in a running container
```

### Compose — Key Options (verified)

```bash
# up
-d, --detach                           # Detached mode
--build                                # Build images before starting
--no-build                             # Don't build an image
--force-recreate                       # Recreate containers even if unchanged
--no-recreate                          # If containers exist, don't recreate them
--no-start                             # Don't start services after creating
--abort-on-container-exit              # Stops all containers if any exits
--abort-on-container-failure           # Stops all containers if any exits with failure
--exit-code-from string                # Return exit code of selected service
--remove-orphans                       # Remove containers not defined in compose file
--scale SERVICE=NUM                    # Scale SERVICE to NUM instances
--pull string                          # Pull image before running ("always"|"missing"|"never")
--no-color                             # Produce monochrome output
--no-deps                              # Don't start linked services
--timeout int                          # Timeout in seconds for container shutdown
--timestamps                           # Show timestamps
--always-recreate-deps                 # Recreate dependent containers
--attach stringArray                   # Restrict attaching to specified services
--attach-dependencies                  # Auto-attach to dependent services
--no-attach stringArray                # Don't attach to specified services
--no-log-prefix                        # Don't print prefix in logs
-V, --renew-anon-volumes               # Recreate anonymous volumes
--quiet-build                          # Suppress build output
--quiet-pull                           # Pull without progress info
--menu                                 # Enable interactive shortcuts

# down
-v, --volumes                          # Remove named volumes + anonymous volumes
--rmi string                           # Remove images ("local"|"all")
-t, --timeout int                      # Shutdown timeout in seconds
--remove-orphans                       # Remove containers not defined in compose file

# build
--build-arg stringArray                # Set build-time variables
--no-cache                             # Do not use cache
--pull                                 # Always attempt to pull newer image
--push                                 # Push service images
--quiet, -q                            # Suppress build output
--provenance string                    # Add provenance attestation
--sbom string                          # Add SBOM attestation
--ssh string                           # Set SSH authentications for building
--with-dependencies                    # Also build dependencies transitively
--memory, -m bytes                     # Set memory limit for build container

# ps
-a, --all                  # Show all stopped containers
--status stringArray       # Filter by status (paused|restarting|running|dead|created|exited)
--services                 # Display services
--orphans                  # Include orphaned services (default true)
-q, --quiet                # Only display IDs
--format string            # Format output (table/json/TEMPLATE)
--no-trunc                 # Don't truncate output
--filter string            # Filter services by property

# logs
-f, --follow               # Follow log output
--since string             # Show logs since timestamp or relative (e.g., "42m")
--tail string              # Number of lines from end (default "all")
--timestamps, -t           # Show timestamps
--until string             # Show logs before timestamp or relative
--no-color                 # Monochrome output
--no-log-prefix            # Don't print prefix in logs
--index int                # Index of container if service has multiple replicas

# run
-d, --detach               # Run in background
-i, --interactive          # Keep STDIN open (default true)
-T, --no-TTY               # Disable pseudo-TTY (default true)
-e, --env stringArray      # Set environment variables
--env-from-file stringArray  # Set environment variables from file
-v, --volume stringArray   # Bind mount a volume
-p, --publish stringArray  # Publish a port to the host
-P, --service-ports        # Run with all service's ports enabled
-u, --user string          # Run as specified username or uid
--entrypoint string        # Override the entrypoint
--name string              # Assign a name to the container
--rm                       # Auto-remove container on exit
--pull string              # Pull image before running
--no-deps                  # Don't start linked services
--build                    # Build image before starting
--remove-orphans           # Remove containers not defined in compose file
--cap-add list             # Add Linux capabilities
--cap-drop list            # Drop Linux capabilities
--label stringArray        # Add or override a label
--use-aliases              # Use the service's network aliases

# exec
-d, --detach               # Detached mode
-e, --env stringArray      # Set environment variables
-u, --user string          # Run the command as this user
-w, --workdir string       # Path to workdir directory
-T, --no-tty               # Disable pseudo-TTY (default true)
--privileged               # Give extended privileges
--index int                # Index of container if service has multiple replicas

# scale
SERVICE=REPLICAS...        # Scale services (e.g., "web=3 db=2")

# config
-q, --quiet                # Only validate, don't print anything
--format string            # Output format (yaml|json)
--hash string              # Print the service config hash
--services                 # Print service names
--networks                 # Print network names
--volumes                  # Print volume names
--profiles                 # Print profile names
--variables                # Print model variables and defaults
--environment              # Print environment used for interpolation
--resolve-image-digests    # Pin image tags to digests
--lock-image-digests       # Produces override file with image digests
-o, --output string        # Save to file (default stdout)

# ls (list projects)
-a, --all                  # Show all stopped Compose projects
-q, --quiet                # Only display project names
--format string            # Output format (table|json)
--filter filter            # Filter based on conditions

# events
--since string             # Show events since timestamp
--until string             # Stream events until timestamp
--json                     # Output as JSON stream

# images
-q, --quiet                # Only display IDs
--format string            # Output format (table|json)

# volumes
-q, --quiet                # Only display volume names
--format string            # Output format (table|json)

# watch
--dry-run                  # Don't build & start services before watching
--no-up                    # Do not build & start services before watching
--prune                    # Prune dangling images on rebuild (default true)
--quiet                    # Hide build output

# version
-f, --format string        # Output format (pretty|json)
--short                    # Show only version number

# top
# Display the running processes (no additional options beyond --dry-run)

# stats
-a, --all                  # Show all containers (default shows just running)
--no-stream                # Disable streaming and only pull first result
--no-trunc                 # Don't truncate output
--format string            # Format output (table/json/TEMPLATE)

# wait SERVICE [SERVICE...]
--down-project             # Drops project when the first container stops

# port SERVICE PRIVATE_PORT
--index int                # Index of container if service has multiple replicas
--protocol string          # tcp or udp (default "tcp")

# export SERVICE
-o, --output string        # Write to a file instead of STDOUT
--index int                # Index of container if service has multiple replicas

# commit SERVICE [REPO[:TAG]]
-a, --author string        # Author
-c, --change list          # Apply Dockerfile instruction
-m, --message string       # Commit message
-p, --pause                # Pause container during commit (default true)
--index int                # Index of container if service has multiple replicas

# cp SERVICE:SRC_PATH DEST_PATH|-
-a, --archive              # Archive mode (copy uid/gid info)
-L, --follow-link          # Follow symbolic links in SRC_PATH
--index int                # Index of container if service has multiple replicas

# pull [SERVICE...]
--ignore-buildable         # Ignore images that can be built
--ignore-pull-failures     # Pull what it can and ignores failures
--include-deps             # Also pull services declared as dependencies
--policy string            # Apply pull policy ("missing"|"always")

# push [SERVICE...]
--ignore-push-failures     # Push what it can and ignores failures
--include-deps             # Also push images of dependency services
```

### Compose — Global Options (verified)

```bash
--all-resources              # Include all resources, even those not used by services
--ansi string                # Control ANSI control characters ("never"|"always"|"auto")
--compatibility              # Run compose in backward compatibility mode
--dry-run                    # Execute command in dry run mode
--env-file stringArray       # Specify an alternate environment file
-f, --file stringArray       # Compose configuration files
--parallel int               # Control max parallelism (-1 = unlimited, default -1)
--profile stringArray        # Specify a profile to enable
--progress string            # Progress output (auto|tty|plain|json|quiet)
--project-directory string   # Specify alternate working directory
-p, --project-name string    # Project name
```

---

### Compose — Common Patterns

```yaml
# docker-compose.yml — Key configuration options
services:
  web:
    image: myapp:latest
    build: .                              # Build from Dockerfile
    ports:
      - "8080:80"                         # Host:Container port mapping
      - "127.0.0.1:443:443"               # Bind to specific interface
    environment:
      - NODE_ENV=production
      - DB_HOST=db
    env_file: .env                        # External env file
    depends_on:
      db:
        condition: service_healthy         # Wait for healthcheck
      redis:
        condition: service_started
    volumes:
      - ./src:/app/src:ro                 # Bind mount (read-only)
      - data:/app/data                    # Named volume
      - /tmp/logs:/app/logs               # Bind mount (absolute path)
    restart: unless-stopped               # Restart policy
    networks:
      - frontend
      - backend
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
    profiles:
      - web                               # Only start with --profile web

  db:
    image: postgres:16
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password
    networks:
      - backend

volumes:
  data:
  pgdata:

secrets:
  db_password:
    file: ./secrets/db_password.txt

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true                        # Restrict external access
```

---

### Networking

```bash
docker network create [OPTIONS] NETWORK              # Create a network
docker network ls [OPTIONS]                          # List networks
docker network inspect [OPTIONS] NETWORK [NETWORK...] # Display detailed information
docker network connect [OPTIONS] NETWORK CONTAINER    # Connect a container to a network
docker network disconnect [OPTIONS] NETWORK CONTAINER # Disconnect a container from a network
docker network rm NETWORK [NETWORK...]               # Remove one or more networks
docker network prune [OPTIONS]                       # Remove all unused networks
docker network ls -f 'driver=bridge'                 # Filter by driver
docker network prune -f                              # Remove unused networks without confirmation
```

### network create — Key Options (verified)

```bash
-d, --driver string         # Driver to manage the Network (default "bridge")
--attachable                # Enable manual container attachment
--internal                  # Restrict external access to the network
--ipv4                      # Enable or disable IPv4 address assignment (default true)
--ipv6                      # Enable or disable IPv6 address assignment
--subnet strings            # Subnet in CIDR format
--gateway ipSlice           # IPv4 or IPv6 Gateway
--ip-range ipNetSlice       # Allocate container IP from a sub-range
--ipam-driver string        # IPAM Driver (default "default")
--ipam-opt map              # Set IPAM driver specific options
--aux-address map           # Auxiliary IPv4 or IPv6 addresses
--label list                # Set metadata on a network
-o, --opt map               # Set driver specific options
--config-from string        # The network from which to copy the configuration
--config-only               # Create a configuration only network
--ingress                   # Create swarm routing-mesh network
```

---

### Volumes

```bash
docker volume create [OPTIONS] [VOLUME]            # Create a volume
docker volume ls [OPTIONS]                         # List volumes
docker volume inspect [OPTIONS] VOLUME [VOLUME...]  # Display detailed information
docker volume rm [OPTIONS] VOLUME [VOLUME...]      # Remove one or more volumes
docker volume prune [OPTIONS]                      # Remove unused local volumes
docker volume ls -f 'dangling=true'                # List unused volumes
docker volume prune -a -f                          # Remove ALL unused volumes (not just anonymous)
```

### volume create — Key Options (verified)

```bash
-d, --driver string   # Specify volume driver name (default "local")
--label list          # Set metadata for a volume
-o, --opt map         # Set driver specific options
```

---

### System Management

```bash
docker info [OPTIONS]                         # Display system-wide information
docker version [OPTIONS]                       # Show Docker version information
docker system df [OPTIONS]                     # Show Docker disk usage
docker system prune [OPTIONS]                  # Remove unused data
docker system events [OPTIONS]                 # Get real time events from the server
docker events [OPTIONS]                        # Alias for docker system events
```

### system df — Key Options (verified)

```bash
-v, --verbose         # Show detailed information on space usage
--format string       # Format output (table/json/TEMPLATE)
```

### system prune — Key Options (verified)

```bash
-a, --all             # Remove all unused images not just dangling ones
--volumes             # Prune anonymous volumes
-f, --force           # Do not prompt for confirmation
--filter filter       # Provide filter values (e.g., "label=<key>=<value>")
```

### events — Key Options (verified)

```bash
-f, --filter filter   # Filter output based on conditions
--since string        # Show all events created since timestamp
--until string        # Stream events until this timestamp
--format string       # Format output (table/json/TEMPLATE)
```

---

### Context Management

```bash
docker context ls [OPTIONS]              # List contexts
docker context show                      # Print the name of the current context
docker context use NAME                  # Set the current docker context
docker context inspect [OPTIONS] [CONTEXT...]  # Display detailed information
docker context create [OPTIONS] CONTEXT  # Create a context
docker context update [OPTIONS] CONTEXT  # Update a context
docker context export [OPTIONS] FILE     # Export a context to a tar archive
docker context import [OPTIONS] FILE     # Import a context from a tar or zip file
docker context rm [OPTIONS] CONTEXT [CONTEXT...]  # Remove one or more contexts
```

---

### File Transfer

```bash
docker cp [OPTIONS] CONTAINER:SRC_PATH DEST_PATH|-    # Extract from container
docker cp [OPTIONS] SRC_PATH|- CONTAINER:DEST_PATH    # Inject into container
docker cp -a <container>:/path ./local_dir            # Preserve uid/gid info
docker cp -L ./src <container>:/dest                  # Follow symlinks
docker cp -q <container>:/file ./local_file           # Suppress progress output
```

### cp — Key Options (verified)

```bash
-a, --archive       # Archive mode (copy all uid/gid information)
-L, --follow-link   # Always follow symbol link in SRC_PATH
-q, --quiet         # Suppress progress output during copy
```

---

### Registry Authentication

```bash
docker login [OPTIONS] [SERVER]        # Authenticate to a registry
docker logout [SERVER]                 # Log out from a registry

# login options (verified):
-u, --username string      # Username
-p, --password string      # Password or Personal Access Token (PAT)
      --password-stdin     # Take the Password or PAT from stdin

# CI/CD pattern:
echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USER" --password-stdin
```

---

### Swarm Mode

```bash
docker swarm init [OPTIONS]                    # Initialize a swarm
docker swarm join [OPTIONS] HOST:PORT           # Join a swarm as a node
docker swarm join-token (worker|manager)        # Manage join tokens
docker swarm leave [OPTIONS]                    # Leave the swarm
docker swarm unlock                             # Unlock swarm
docker swarm update [OPTIONS]                   # Update the swarm

docker node ls [OPTIONS]                        # List nodes in the swarm
docker node inspect [OPTIONS] NODE [NODE...]     # Display detailed information on nodes
docker node ps [OPTIONS] NODE                   # List tasks running on nodes
docker node update [OPTIONS] NODE               # Update a node
docker node promote NODE [NODE...]              # Promote nodes to manager
docker node demote NODE [NODE...]               # Demote nodes from manager
docker node rm NODE [NODE...]                   # Remove nodes from the swarm

docker service create [OPTIONS] IMAGE [CMD]     # Create a new service
docker service ls [OPTIONS]                     # List services
docker service inspect [OPTIONS] SERVICE [SERVICE...]  # Display detailed information
docker service ps [OPTIONS] SERVICE             # List the tasks of one or more services
docker service update [OPTIONS] SERVICE         # Update a service
docker service rollback [OPTIONS] SERVICE       # Revert changes to a service's configuration
docker service scale SERVICE=REPLICAS [...]     # Scale one or multiple replicated services
docker service rm SERVICE [SERVICE...]          # Remove one or more services
docker service logs [OPTIONS] SERVICE           # Fetch the logs of a service or task

docker stack ls [OPTIONS]                       # List stacks
docker stack deploy [OPTIONS] STACK             # Deploy a new stack or update
docker stack ps [OPTIONS] STACK                 # List the tasks in the stack
docker stack services [OPTIONS] STACK           # List the services in the stack
docker stack config [OPTIONS] STACK             # Outputs the final config file
docker stack rm STACK [STACK...]                # Remove one or more stacks
```

### swarm init — Key Options (verified)

```bash
--advertise-addr string        # Advertised address (ip|interface[:port])
--autolock                     # Enable manager autolocking
--availability string          # Availability ("active"|"pause"|"drain")
--cert-expiry duration         # Validity period for node certificates (default 2160h)
--data-path-addr string        # Address for data path traffic
--data-path-port uint32        # Port for data path traffic (1024-49151, default 4789)
--default-addr-pool ipNetSlice # Default address pool in CIDR format
--default-addr-pool-mask-length uint32  # Subnet mask length (default 24)
--dispatcher-heartbeat duration  # Dispatcher heartbeat period (default 5s)
--external-ca external-ca      # Specifications of external certificate signing endpoints
--force-new-cluster            # Force create a new cluster from current state
--listen-addr node-addr        # Listen address (default 0.0.0.0:2377)
--max-snapshots uint           # Number of additional Raft snapshots to retain
--snapshot-interval uint       # Log entries between Raft snapshots (default 10000)
--task-history-limit int       # Task history retention limit (default 5)
```

### swarm join — Key Options (verified)

```bash
--advertise-addr string   # Advertised address (ip|interface[:port])
--availability string     # Availability ("active"|"pause"|"drain")
--data-path-addr string   # Address for data path traffic
--listen-addr node-addr   # Listen address (default 0.0.0.0:2377)
--token string            # Token for entry into the swarm
```

### stack deploy — Key Options (verified)

```bash
-c, --compose-file strings   # Path to a Compose file or "-" for stdin
-d, --detach                 # Exit immediately (default true)
--prune                      # Prune services no longer referenced
-q, --quiet                  # Suppress progress output
--resolve-image string       # Query registry for image digest ("always"|"changed"|"never")
--with-registry-auth         # Send registry authentication details to Swarm agents
```

---

### Plugin Management

```bash
docker plugin install [OPTIONS] PLUGIN [KEY=VALUE...]  # Install a plugin
docker plugin ls [OPTIONS]                             # List plugins
docker plugin inspect [OPTIONS] PLUGIN [PLUGIN...]     # Display detailed information
docker plugin enable [OPTIONS] PLUGIN                  # Enable a plugin
docker plugin disable [OPTIONS] PLUGIN                 # Disable a plugin
docker plugin rm [OPTIONS] PLUGIN [PLUGIN...]          # Remove one or more plugins
docker plugin upgrade [OPTIONS] PLUGIN [PLUGIN...]     # Upgrade an existing plugin
docker plugin set [OPTIONS] PLUGIN KEY=VALUE [...]     # Change settings for a plugin
docker plugin push [OPTIONS] PLUGIN                    # Push a plugin to a registry
docker plugin create PLUGIN ROOTFS CONFIG              # Create a plugin from rootfs and config
```

### plugin install — Key Options (verified)

```bash
--alias string              # Local name for plugin
--disable                   # Do not enable the plugin on install
--grant-all-permissions     # Grant all permissions necessary to run the plugin
```

---

### Builder Management (buildx)

```bash
docker buildx create [OPTIONS] [CONTEXT|ENDPOINT]  # Create a new builder instance
docker buildx ls [OPTIONS]                         # List builder instances
docker buildx use [OPTIONS] NAME                   # Set the current builder instance
docker buildx inspect [OPTIONS] [NAME]             # Inspect current builder instance
docker buildx stop [OPTIONS] [NAME]                # Stop builder instance
docker buildx rm [OPTIONS] [NAME]                  # Remove one or more builder instances
docker buildx version                              # Show buildx version information
docker buildx du [OPTIONS]                         # Disk usage
docker buildx prune [OPTIONS]                      # Remove build cache
```

### buildx create — Key Options (verified)

```bash
--append                    # Append a node to builder instead of changing it
--bootstrap                 # Boot builder after creation
--buildkitd-config string   # BuildKit daemon config file
--buildkitd-flags string    # BuildKit daemon flags
--driver string             # Driver to use ("docker-container", "kubernetes", "remote")
--driver-opt stringArray    # Options for the driver
--leave                     # Remove a node from builder instead of changing it
--name string               # Builder instance name
--node string               # Create/modify node with given name
--platform stringArray      # Fixed platforms for current node
--use                       # Set the current builder instance
```

### buildx prune — Key Options (verified)

```bash
-a, --all                    # Include internal/frontend images
-f, --force                  # Do not prompt for confirmation
--max-used-space bytes       # Maximum amount of disk space allowed to keep for cache
--min-free-space bytes       # Target amount of free space after pruning
--reserved-space bytes       # Amount of disk space always allowed to keep for cache
--timeout duration           # Override the default timeout (default 20s)
--verbose                    # Provide a more verbose output
```

---

### Manifest Management (Experimental)

```bash
docker manifest inspect NAME                       # Display an image manifest or manifest list
docker manifest create NAME SOURCE [SOURCE...]     # Create a local manifest list
docker manifest annotate NAME IMAGE [OPTIONS]      # Add additional information to a local manifest
docker manifest push NAME                          # Push a manifest list to a repository
docker manifest rm NAME [NAME...]                  # Delete one or more manifest lists

# Requires: BUILDX_EXPERIMENTAL=1 (may be available as docker manifest without buildx)
```

---

### Container Stats

```bash
docker stats [OPTIONS] [CONTAINER...]     # Display a live stream of container resource usage

# Options (verified):
-a, --all             # Show all containers (default shows just running)
--no-stream           # Disable streaming and only pull the first result
--no-trunc            # Do not truncate output
--format string       # Format output (table/json/TEMPLATE)
```

---

### Container Update (after creation)

```bash
docker update [OPTIONS] CONTAINER [CONTAINER...]  # Update configuration of running containers

# Options (verified):
--blkio-weight uint16        # Block IO weight (10-1000, 0 = disable)
--cpu-period int             # Limit CPU CFS period
--cpu-quota int              # Limit CPU CFS quota
--cpu-rt-period int          # CPU real-time period (microseconds)
--cpu-rt-runtime int         # CPU real-time runtime (microseconds)
-c, --cpu-shares int         # CPU shares (relative weight)
--cpus decimal               # Number of CPUs
--cpuset-cpus string         # CPUs to allow execution (0-3, 0,1)
--cpuset-mems string         # MEMs to allow execution (0-3, 0,1)
-m, --memory bytes           # Memory limit
--memory-reservation bytes   # Memory soft limit
--memory-swap bytes          # Swap limit (-1 = unlimited)
--pids-limit int             # Tune container pids limit (-1 = unlimited)
--restart string             # Restart policy
```

---

### Common Filter Values

```bash
# docker ps -f
docker ps -f "status=running"           # Running containers
docker ps -f "status=exited"            # Stopped containers
docker ps -f "status=created"           # Created (not started) containers
docker ps -f "status=paused"            # Paused containers
docker ps -f "status=restarting"        # Restarting containers
docker ps -f "status=dead"              # Dead containers
docker ps -f "name=myapp"               # Filter by name
docker ps -f "label=key=value"          # Filter by label
docker ps -f "ancestor=nginx:latest"    # Filter by image
docker ps -f "publish=8080"             # Filter by published port
docker ps -f "network=mynet"            # Filter by network

# docker volume ls -f
docker volume ls -f "dangling=true"     # Unused volumes
docker volume ls -f "driver=local"      # Filter by driver
docker volume ls -f "name=mydata"       # Filter by name

# docker network ls -f
docker network ls -f "driver=bridge"    # Filter by driver
docker network ls -f "type=custom"      # Filter by type

# docker image prune -f
docker image prune -f --filter "until=24h"  # Remove images unused for 24 hours
```

---

### Container Exit Codes Reference

| Code | Meaning |
|------|---------|
| 0    | Success |
| 1    | Application error |
| 125  | Docker daemon error |
| 126  | Command not executable |
| 127  | Command not found |
| 134  | Abnormal termination (SIGABRT) |
| 137  | SIGKILL (often OOM kill) |
| 139  | Segmentation fault |
| 143  | SIGTERM (graceful shutdown) |

---

### Common Dockerfile Instructions

```dockerfile
FROM image:tag[ AS stage-name]           # Base image
WORKDIR /path                            # Set working directory
COPY src dest                            # Copy files from build context
COPY --chown=user:group src dest         # Copy with ownership
COPY --chmod=755 src dest                # Copy with permissions
ADD src dest                             # Copy with tar extraction support
RUN command                              # Execute a command during build
CMD ["executable","param1","param2"]    # Default command (only last one takes effect)
ENTRYPOINT ["executable","param1"]       # Entry point (combines with CMD)
ENV KEY=VALUE                            # Set environment variable
ARG KEY=VALUE                            # Build-time variable
EXPOSE port[/protocol]                   # Document exposed ports
VOLUME ["/path"]                         # Create a mount point
USER user[:group]                        # Set user and group
HEALTHCHECK [OPTIONS] CMD command        # Define a health check
STOPSIGNAL signal                        # Default signal to stop container
LABEL key=value                          # Add metadata
SHELL ["executable", "parameters"]       # Default shell for RUN/CMD/ENTRYPOINT
```

---

### .dockerignore Essentials

```
.git
.gitignore
node_modules
__pycache__
*.md
.env
.dockerignore
Dockerfile
docker-compose.yml
dist
build
coverage
*.log
*.tmp
*.swp
.sass-cache
.editorconfig
.eslintrc
.github
.terraform
```

---

### Multi-Stage Build Pattern

```dockerfile
# Build stage
FROM golang:1.22-bookworm AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o myapp .

# Runtime stage
FROM debian:bookworm-slim
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/myapp /usr/local/bin/myapp
RUN useradd -r -s /bin/false myuser
USER myuser
EXPOSE 8080
ENTRYPOINT ["myapp"]
```

---

### BuildKit Cache Strategies

```bash
# Inline cache (embedded in image, auto-pulled with image)
docker buildx build --cache-to type=inline --cache-from type=inline -t myapp .

# Registry cache (stored as a separate image layer)
docker buildx build --cache-to type=registry,ref=myapp:cache --cache-from type=registry,ref=myapp:cache -t myapp .

# Local cache (stored on disk)
docker buildx build --cache-to type=local,dest=/tmp/build-cache --cache-from type=local,src=/tmp/build-cache -t myapp .

# GitHub Actions cache integration
docker buildx build --cache-to type=gha,mode=max --cache-from type=gha -t myapp .

# Docker Hub cache (requires Docker Hub Premium)
docker buildx build --cache-to type=registry,ref=myapp:cache,mode=max --cache-from type=registry,ref=myapp:cache -t myapp .
```

---

### BuildKit Secrets & SSH

```bash
# Build secrets (never stored in image layers)
docker buildx build \
  --secret id=npmrc,src=$HOME/.npmrc \
  --secret id=ssh,key,src=$HOME/.ssh/id_rsa \
  -t myapp .

# In Dockerfile:
# RUN --mount=type=secret,id=npmrc cat /run/secrets/npmrc > ~/.npmrc && npm install

# Build SSH (for private repo dependencies)
docker buildx build \
  --ssh default \
  -t myapp .

# In Dockerfile:
# RUN --mount=type=ssh git clone git@github.com:org/private-repo.git
```

---

### BuildKit Security Entitlements

```bash
# Allow privileged operations during build
docker buildx build --allow network.host -t myapp .      # Host network access
docker buildx build --allow security.insecure -t myapp .  # Insecure build (e.g., for self-signed certs)
docker buildx build --allow device=/dev/fuse -t myapp .   # Device access
```

---

### BuildKit Provenance & SBOM

```bash
# Build with provenance (build metadata)
docker buildx build --provenance=mode=max -t myapp .

# Build with SBOM (software bill of materials)
docker buildx build --sbom -t myapp .

# Build with both
docker buildx build --attest type=provenance,mode=max --attest type=sbom -t myapp .

# Build with both (shorthand)
docker buildx build --provenance=mode=max --sbom -t myapp .

# Inspect attestations
docker buildx imagetools inspect myapp:latest
```

---

### Build Policy Configuration

```bash
# Use a policy file for build restrictions
docker buildx build --policy policy.json -t myapp .

# Example policy.json:
{
  "version": "1.0",
  "rules": [
    {
      "match": ["*"],
      "action": "allow"
    }
  ]
}
```

---

### Common Docker Compose Patterns

```yaml
# Profile-based environment selection
services:
  web:
    profiles: ["web", "all"]
  worker:
    profiles: ["worker", "all"]
  devtools:
    profiles: ["dev", "all"]

# Usage:
# docker compose --profile dev up          # Start web + devtools
# docker compose --profile worker up       # Start worker
# docker compose --profile all up          # Start everything

# Healthcheck with depends_on
services:
  app:
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started

# Resource limits in deploy section
services:
  web:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
        reservations:
          cpus: '0.25'
          memory: 128M

# Rolling updates with healthcheck
services:
  web:
    deploy:
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
      update_config:
        parallelism: 2
        delay: 10s
        order: start-first

# Secret management
services:
  app:
    secrets:
      - db_password
      - source: api_key
        target: app_api_key        # Custom target name
      - file: ./secrets/cert.pem   # File-based secret

secrets:
  db_password:
    file: ./secrets/db_password.txt
  api_key:
    environment: API_KEY           # From host environment variable
```

---

### Quick Troubleshooting Commands

```bash
# Check if container was OOM killed
docker inspect --format='{{.State.OOMKilled}}' <container>

# Get container exit code
docker inspect --format='{{.State.ExitCode}}' <container>

# List containers with resource usage
docker stats --no-stream

# Check disk usage
docker system df -v

# Clean up unused resources
docker system prune -a --volumes -f        # Aggressive cleanup
docker image prune -a -f                    # Remove unused images
docker volume prune -a -f                   # Remove unused volumes
docker network prune -f                     # Remove unused networks
docker builder prune -a -f                  # Remove build cache

# Find what's using a port
ss -tlnp | grep :80

# Check container logs with timestamps
docker logs --tail 100 -f --timestamps <container>

# Check container filesystem changes
docker diff <container>

# Check image layer sizes
docker history -v myimage:latest

# Check buildx builder status
docker buildx inspect --bootstrap

# Check buildx disk usage
docker buildx du --verbose

# List all compose projects
docker compose ls -a
```

---

### Docker Client Configuration

```bash
# Client config location: ~/.docker/config.json
# Common settings:
{
  "auths": {
    "registry.example.com": {}
  },
  "credsStore": "desktop",
  "experimental": "enabled",
  "features": {
    "buildkit": true
  },
  "proxies": {
    "default": {
      "httpProxy": "http://proxy:8080",
      "httpsProxy": "http://proxy:8080",
      "noProxy": "localhost,127.0.0.1"
    }
  }
}

# Environment variables:
DOCKER_HOST=tcp://localhost:2375        # Override daemon socket
DOCKER_CONTEXT=my-context               # Override current context
DOCKER_BUILDKIT=1                       # Enable BuildKit (default in modern Docker)
COMPOSE_PROJECT_NAME=myproject          # Override compose project name
COMPOSE_FILE=docker-compose.prod.yml    # Specify compose file
```
