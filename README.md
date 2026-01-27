# MUXI Runtime Runner

Docker wrapper that enables running Singularity SIF files on macOS and Windows.

> [!IMPORTANT]
> ## MUXI Ecosystem
>
> This repository is part of the larger MUXI ecosystem.
>
> **📋 Complete architectural overview:** See [muxi/ARCHITECTURE.md](https://github.com/muxi-ai/muxi/blob/main/ARCHITECTURE.md) - explains how all 9 repositories fit together, dependencies, status, and roadmap.

## What is this?

Singularity (the tool that runs SIF files) only works on Linux. This Docker image provides a Linux environment with Singularity installed, allowing MUXI Server to execute SIF files on non-Linux platforms.

**You typically don't interact with this directly** - MUXI Server uses it automatically when running on macOS or Windows.

## Architecture

```
macOS/Windows Host
  ↓
Docker Desktop (provides Linux VM)
  ↓
runtime-runner container (has Singularity)
  ↓
SIF file (mounted from host)
  ↓
Formation executes
```

## Usage

### Automatic (via MUXI Server)

When you run MUXI Server on macOS or Windows, it automatically:
1. Detects the platform
2. Pulls `ghcr.io/muxi-ai/runtime-runner:latest` (if not already cached)
3. Spawns formations using this wrapper

**You don't need to do anything!**

### Manual Testing

If you want to test the image directly:

```bash
# Pull the image
docker pull ghcr.io/muxi-ai/runtime-runner:latest

# Verify Singularity is installed
docker run --rm ghcr.io/muxi-ai/runtime-runner:latest --version
# Output: singularity-ce version 3.11.4-jammy

# Run a SIF file
docker run --rm --privileged \
  -v ./runtime.sif:/sif/runtime.sif \
  -v ./formation:/formation \
  -p 8001:8001 \
  ghcr.io/muxi-ai/runtime-runner:latest \
  exec /sif/runtime.sif python app.py
```

## Why `--privileged`?

Singularity creates user namespaces for container isolation, which requires privileged mode inside Docker.

**Security note:** This is only for local development on macOS/Windows. Production Linux servers use native Singularity without Docker.

## Building Locally

```bash
# Build the image
docker build -t runtime-runner:local .

# Test it
docker run --rm runtime-runner:local --version
```

## Image Details

- **Base:** Ubuntu 22.04
- **Singularity:** 3.11.4
- **Platform:** linux/amd64 (emulated on ARM Macs)
- **Size:** ~222MB (optimized from 266MB)

## Automatic Builds

This image is automatically built and published to GitHub Container Registry when:
- Code is pushed to `main` branch (tagged as `latest`)
- A version tag is created (e.g., `v1.0.0`)

## Registry

**Location:** `ghcr.io/muxi-ai/runtime-runner`

**Tags:**
- `latest` - Latest build from main branch
- `v1.0.0` - Specific version (if tagged)
- `sha-abc1234` - Specific commit

**Visibility:** Public (no authentication needed to pull)

## Related Projects

- [MUXI Server](https://github.com/muxi-ai/server) - Uses this wrapper on macOS/Windows
- [MUXI Runtime](https://github.com/muxi-ai/runtime) - SIF files that run inside this container

## License

MIT License - See LICENSE file

## Support

- **Issues:** https://github.com/muxi-ai/runtime-runner/issues
- **Documentation:** https://github.com/muxi-ai/server/docs
- **Website:** https://muxi.org
