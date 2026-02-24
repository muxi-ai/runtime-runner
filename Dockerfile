# MUXI Runtime Runner - Multi-Architecture Support
# Docker wrapper for running Singularity SIF files on macOS/Windows
#
# Singularity bind-mounts host paths into the SIF at runtime, so tools
# installed here are available to formations running inside SIF containers.
# On production Linux servers, users install these dependencies natively.
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

# ============================================================================
# Stage 1: Singularity + system dependencies
# ============================================================================

# Install Singularity and all host dependencies that SIF containers need.
# These are bind-mounted into the SIF by Singularity at runtime.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # --- Singularity runtime ---
        singularity-container \
        squashfs-tools \
        fuse \
        # --- General utilities ---
        curl \
        wget \
        git \
        ca-certificates \
        jq \
        unzip \
        openssh-client \
        sqlite3 \
        python3 \
        # --- Document/media processing ---
        poppler-utils \
        tesseract-ocr \
        ffmpeg \
        libmagic1 \
        pandoc \
        graphviz \
        # --- Fonts (required for matplotlib chart rendering) ---
        fonts-dejavu-core \
        fontconfig \
    && \
    # Clean up apt cache
    apt-get clean && \
    rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/doc/* \
        /usr/share/man/* \
        /usr/share/locale/* \
        /var/cache/apt/archives/* \
        /var/log/*

# ============================================================================
# Stage 2: Node.js 22 LTS (required for npx-based MCP servers)
# ============================================================================

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    node --version && npm --version && npx --version

# ============================================================================
# Verify installations
# ============================================================================

RUN singularity --version && \
    node --version && \
    npx --version && \
    git --version && \
    ffmpeg -version 2>&1 | head -1 && \
    echo "All dependencies verified"

# Create mount points for SIF files and formation code
RUN mkdir -p /sif /formation

# Set working directory
WORKDIR /formation

# Singularity as entrypoint
ENTRYPOINT ["singularity"]

# Default command shows help
CMD ["--help"]
