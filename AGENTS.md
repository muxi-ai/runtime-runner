# AGENTS.md

This document provides guidance for AI coding assistants working with the runtime-runner project.

---

## MUXI Ecosystem

This repository is part of the larger MUXI ecosystem.

**📋 Complete architectural overview:** See [MUXI-ARCHITECTURE.md](../MUXI-ARCHITECTURE.md) - explains how all 9 repositories fit together, dependencies, status, and roadmap.

**🎯 This repo (runtime-runner):** Runtime executor that bridges server and runtime - spawns SIF containers and manages their lifecycle.

---

## Project Overview

**runtime-runner** is a Docker wrapper that enables running Singularity SIF files on macOS and Windows platforms. Since Singularity only works natively on Linux, this container provides the necessary Linux environment for MUXI Server to execute formations on non-Linux platforms.

## Architecture

```
macOS/Windows Host
  ↓
Docker Desktop (Linux VM)
  ↓
runtime-runner container (Ubuntu 22.04 + Singularity 3.11.4)
  ↓
SIF file execution
```

## Key Components

### Dockerfile
- **Base Image**: Ubuntu 22.04 (jammy)
- **Singularity Version**: 3.11.4-jammy
- **Platform**: linux/amd64 (emulated on ARM Macs)
- **Size**: ~222MB (optimized from 266MB with --no-install-recommends, aggressive cleanup)
- **Entrypoint**: `/usr/local/bin/singularity`

### Build & Publish
- GitHub Actions workflow: `.github/workflows/docker-build-publish.yml`
- Registry: `ghcr.io/muxi-ai/runtime-runner`
- Auto-publishes on push to `main` and version tags

## Development Guidelines

### When Making Changes

1. **Dockerfile Modifications**
   - Keep the image size minimal (currently ~222MB, optimized from 266MB)
   - Use `--no-install-recommends` for apt-get installations
   - Aggressively clean up build artifacts and unnecessary files
   - Always test locally before pushing
   - Ensure Singularity version remains compatible with MUXI runtime

2. **Testing Workflow**
   ```bash
   # Build locally
   docker build -t runtime-runner:local .
   
   # Verify Singularity
   docker run --rm runtime-runner:local --version
   # Expected: singularity-ce version 3.11.4-jammy
   
   # Check image size
   docker images runtime-runner:local
   # Expected: ~222MB
   
   # Test with actual SIF file
   docker run --rm --privileged \
     -v ./runtime.sif:/sif/runtime.sif \
     -v ./formation:/formation \
     -p 8001:8001 \
     runtime-runner:local \
     exec /sif/runtime.sif python app.py
   ```

3. **Version Tagging**
   - Follow semantic versioning (v1.0.0, v1.1.0, etc.)
   - Tags trigger automated builds with version labels

### Security Considerations

- `--privileged` flag is required for Singularity user namespaces
- This is a local development tool only - production uses native Singularity
- No authentication required for public registry access

### Documentation Updates

When modifying functionality, update:
- `README.md` - User-facing documentation
- `AGENTS.md` (this file) - AI assistant guidance
- Inline comments in `Dockerfile` if adding complexity

## Common Tasks

### Adding Dependencies
If you need to add system packages:
```dockerfile
RUN apt-get update && \
    apt-get install -y your-package && \
    rm -rf /var/lib/apt/lists/*
```

### Updating Singularity Version
1. Check available versions at SylabsIO
2. Update the `singularity-ce` version in Dockerfile
3. Test thoroughly with MUXI runtime SIF files
4. Update README.md with new version number

### Debugging Build Issues
- Check GitHub Actions logs for CI failures
- Verify base image availability
- Ensure GHCR authentication is configured (for publishing)
- Test local build before committing

## Related Repositories

- **MUXI Server**: Consumes this image when running on macOS/Windows
- **MUXI Runtime**: Creates the SIF files executed by this container

## Integration Points

This image is used by MUXI Server:
1. Server detects non-Linux platform
2. Pulls `ghcr.io/muxi-ai/runtime-runner:latest`
3. Mounts SIF file and formation directory
4. Executes formation via Singularity inside container

## Testing Checklist

Before submitting changes:
- [ ] Local build succeeds
- [ ] `singularity --version` works in container
- [ ] Can execute a sample SIF file
- [ ] Image size hasn't increased significantly
- [ ] README.md updated if user-facing changes
- [ ] GitHub Actions workflow still valid

## Troubleshooting

### Build Fails
- Check Ubuntu package availability
- Verify Singularity version exists
- Ensure network connectivity for downloads

### Runtime Issues
- Verify `--privileged` flag is used
- Check volume mounts are correct
- Ensure SIF file is compatible

### Registry Issues
- Confirm GHCR permissions
- Check GitHub Actions secrets configuration
- Verify tag format follows convention

## Questions to Ask

When working on this project, consider:
- Does this change affect MUXI Server integration?
- Will this work on both Intel and ARM Macs (via emulation)?
- Is the image size reasonable?
- Are we maintaining compatibility with existing SIF files?
- Do we need to version bump?

## License

MIT License - See LICENSE file for details.
