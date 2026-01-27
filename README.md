# MUXI Runtime Runner

Docker wrapper that enables running Singularity SIF files on macOS and Windows.

This repo is part of the [MUXI ecosystem](https://github.com/muxi-ai/muxi/blob/main/ARCHITECTURE.md).

## What is this?

Singularity only runs on Linux. This Docker image provides a Linux environment with Singularity installed, allowing MUXI Server to execute SIF files on non-Linux platforms.

**You typically don't interact with this directly** -- MUXI Server uses it automatically when running on macOS or Windows.

```
macOS/Windows Host
  -> Docker Desktop (provides Linux VM)
    -> runtime-runner container (has Singularity)
      -> SIF file (mounted from host)
        -> Formation executes
```

## Usage

### Automatic (via MUXI Server)

When you run MUXI Server on macOS or Windows, it automatically:
1. Detects the platform
2. Pulls `ghcr.io/muxi-ai/runtime-runner:latest`
3. Spawns formations using this wrapper

### Manual Testing

```bash
docker pull ghcr.io/muxi-ai/runtime-runner:latest

# Verify Singularity is installed
docker run --rm ghcr.io/muxi-ai/runtime-runner:latest --version

# Run a SIF file
docker run --rm --privileged \
  -v ./runtime.sif:/sif/runtime.sif \
  -v ./formation:/formation \
  -p 8001:8001 \
  ghcr.io/muxi-ai/runtime-runner:latest \
  exec /sif/runtime.sif python app.py
```

### Why `--privileged`?

Singularity creates user namespaces for container isolation, which requires privileged mode inside Docker. This is only for local development on macOS/Windows. Production Linux servers use native Singularity without Docker.

## Building Locally

```bash
docker build -t runtime-runner:local .
docker run --rm runtime-runner:local --version
```

## Image Details

- **Base:** Ubuntu 24.04
- **Platforms:** linux/amd64, linux/arm64
- **Size:** ~222MB

## Registry

`ghcr.io/muxi-ai/runtime-runner`

Auto-built on push to `main` and version tags.

## Related

- [muxi-ai/server](https://github.com/muxi-ai/server) -- Uses this wrapper on macOS/Windows
- [muxi-ai/runtime](https://github.com/muxi-ai/runtime) -- SIF files that run inside this container
- [muxi.org/docs](https://muxi.org/docs) -- Documentation

## License

MIT
