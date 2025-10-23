# MUXI Runtime Runner - Optimized Version
# Docker wrapper for running Singularity SIF files on macOS/Windows
# 
# Optimization techniques applied:
# 1. Minimized dependencies (removed wget, use curl instead)
# 2. More aggressive cleanup of package manager cache
# 3. Removed documentation and locale files
# 4. Combined operations to reduce layers
#
# Usage:
#   docker run --rm --privileged \
#     -v ./runtime.sif:/sif/runtime.sif \
#     -v ./formation:/formation \
#     -p 8001:8001 \
#     ghcr.io/muxi-ai/runtime-runner:latest \
#     exec /sif/runtime.sif python app.py

FROM --platform=linux/amd64 ubuntu:22.04

LABEL maintainer="MUXI AI <hello@muxi.ai>"
LABEL org.opencontainers.image.source="https://github.com/muxi-ai/runtime-runner"
LABEL org.opencontainers.image.description="MUXI Runtime Runner with Singularity support"
LABEL org.opencontainers.image.licenses="MIT"

# Avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies and Singularity in a single layer with aggressive cleanup
RUN apt-get update && \
    # Install minimal dependencies
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        squashfs-tools \
        fuse \
    && \
    # Download and install Singularity
    SINGULARITY_VERSION=3.11.4 && \
    curl -fsSL -o singularity.deb \
        "https://github.com/sylabs/singularity/releases/download/v${SINGULARITY_VERSION}/singularity-ce_${SINGULARITY_VERSION}-jammy_amd64.deb" && \
    apt-get install -y --no-install-recommends ./singularity.deb && \
    rm singularity.deb && \
    # Aggressive cleanup to reduce image size
    apt-get purge -y --auto-remove curl && \
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
