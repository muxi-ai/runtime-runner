# AGENTS.md -- AI Agent Development Guide

**Project:** MUXI Runtime Runner
**Language:** Dockerfile, Bash
**License:** MIT

## What This Is

Docker image that provides Singularity on non-Linux platforms, enabling MUXI Server to run SIF files on macOS and Windows via Docker Desktop.

This repo is part of the [MUXI ecosystem](https://github.com/muxi-ai/muxi/blob/main/ARCHITECTURE.md).

## Repository Structure

```
.
├── Dockerfile         # Ubuntu 24.04 + Singularity (multi-arch)
├── build.sh           # Local multi-arch build script
├── README.md
├── AGENTS.md
├── LICENSE-MIT
└── .github/workflows/
    └── docker-build-publish.yml  # Auto-publish to GHCR
```

## Key Design Decisions

- Ubuntu 24.04 base (not Alpine -- Singularity needs glibc)
- Multi-arch: linux/amd64 + linux/arm64
- `--no-install-recommends` + aggressive cleanup for minimal size (~222MB)
- `--privileged` required for Singularity user namespaces
- Entrypoint is `singularity` binary

## Testing

```bash
docker build -t runtime-runner:local .
docker run --rm runtime-runner:local --version
```

## How MUXI Server Uses This

1. Server detects non-Linux platform
2. Pulls `ghcr.io/muxi-ai/runtime-runner:latest`
3. Mounts SIF file + formation directory
4. Executes formation via Singularity inside container
