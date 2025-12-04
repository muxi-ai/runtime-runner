# MUXI Runtime Runner - Multi-Architecture Support
# Docker wrapper for running Singularity SIF files on macOS/Windows
#
# Supports: linux/amd64 (Intel/AMD) and linux/arm64 (Apple Silicon, ARM servers)
#
# Usage:
#   docker run --rm --privileged \
#     -v ./runtime.sif:/sif/runtime.sif \
#     -v ./formation:/formation \
#     -p 8001:8001 \
#     ghcr.io/muxi-ai/runtime-runner:latest \
#     exec /sif/runtime.sif python -m muxi.utils.run_formation /formation/formation.yaml

FROM ubuntu:24.04

LABEL maintainer="MUXI AI <hello@muxi.ai>"
LABEL org.opencontainers.image.source="https://github.com/muxi-ai/runtime-runner"
LABEL org.opencontainers.image.description="MUXI Runtime Runner with Singularity support (multi-arch: amd64/arm64)"
LABEL org.opencontainers.image.licenses="MIT"

# Avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install Singularity from Ubuntu's official repositories
# This provides both amd64 and arm64 packages automatically
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        singularity-container \
        squashfs-tools \
        fuse \
    && \
    # Aggressive cleanup to reduce image size
    apt-get clean && \
    rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/doc/* \
        /usr/share/man/* \
        /usr/share/locale/* \
        /var/cache/apt/archives/* \
        /var/log/* && \
    # Verify Singularity is installed
    singularity --version

# Create mount points for SIF files and formation code
RUN mkdir -p /sif /formation

# Set working directory
WORKDIR /formation

# Singularity as entrypoint
ENTRYPOINT ["singularity"]

# Default command shows help
CMD ["--help"]
