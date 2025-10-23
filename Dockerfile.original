# MUXI Runtime Runner
# Docker wrapper for running Singularity SIF files on macOS/Windows
# 
# This image provides a Linux environment with Singularity, allowing SIF files
# to run on platforms where Singularity isn't natively available.
#
# Usage:
#   docker run --rm --privileged \
#     -v ./runtime.sif:/sif/runtime.sif \
#     -v ./formation:/formation \
#     -p 8001:8001 \
#     ghcr.io/muxi-ai/runtime-runner:latest \
#     exec /sif/runtime.sif python app.py
#
# Note: Must be built for linux/amd64 platform to match SIF files

FROM --platform=linux/amd64 ubuntu:22.04

LABEL maintainer="MUXI AI <hello@muxi.ai>"
LABEL org.opencontainers.image.source="https://github.com/muxi-ai/runtime-runner"
LABEL org.opencontainers.image.description="MUXI Runtime Runner with Singularity support"
LABEL org.opencontainers.image.licenses="MIT"

# Avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies and Singularity
RUN apt-get update && \
    apt-get install -y \
        wget \
        ca-certificates \
        squashfs-tools \
        fuse \
    && \
    # Download and install Singularity
    SINGULARITY_VERSION=3.11.4 && \
    wget https://github.com/sylabs/singularity/releases/download/v${SINGULARITY_VERSION}/singularity-ce_${SINGULARITY_VERSION}-jammy_amd64.deb && \
    apt-get install -y ./singularity-ce_${SINGULARITY_VERSION}-jammy_amd64.deb && \
    rm singularity-ce_*.deb && \
    # Clean up to reduce image size
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Verify Singularity is installed
RUN singularity --version

# Create mount points for SIF files and formation code
RUN mkdir -p /sif /formation

# Set working directory
WORKDIR /formation

# Singularity as entrypoint
ENTRYPOINT ["singularity"]

# Default command shows help
CMD ["--help"]
