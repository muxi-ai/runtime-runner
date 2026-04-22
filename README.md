# MUXI Runtime Runner

Docker wrapper that enables running Singularity SIF files on macOS and Windows.

> [!IMPORTANT]
> ## MUXI Ecosystem
>
> This repository is part of the larger MUXI ecosystem.
>
> **📋 Complete architectural overview:** See [muxi/ARCHITECTURE.md](https://github.com/muxi-ai/muxi/blob/main/ARCHITECTURE.md) - explains how all 9 repositories fit together, dependencies, status, and roadmap.

## Why does this exist?

MUXI formations are packaged as [Singularity SIF](https://docs.sylabs.io/guides/latest/user-guide/) files -- single-file, immutable containers that bundle an application with its entire runtime environment. SIF gives us reproducible execution: the same file runs identically everywhere, with no dependency drift, no virtualenv conflicts, and no "works on my machine" problems.

The catch is that Singularity only runs on Linux. On macOS and Windows, there is no native Singularity support. The Runtime Runner solves this by providing a minimal Docker image with Singularity pre-installed, so MUXI Server can execute SIF files on any platform via Docker Desktop.

**You typically don't interact with this directly** -- MUXI Server detects non-Linux platforms and uses the Runtime Runner automatically.

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
- **Size:** ~280MB compressed

## Registry

`ghcr.io/muxi-ai/runtime-runner`

Auto-built on push to `main` and version tags.

## Related

- [muxi-ai/server](https://github.com/muxi-ai/server) -- Uses this wrapper on macOS/Windows
- [muxi-ai/runtime](https://github.com/muxi-ai/runtime) -- SIF files that run inside this container
- [muxi.org/docs](https://muxi.org/docs) -- Documentation

## License

MIT
