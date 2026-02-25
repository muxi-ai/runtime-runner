# MUXI Runtime Runner - Multi-Architecture Support
# Docker wrapper for running Singularity SIF files on macOS/Windows
#
# Tools installed here are made available inside SIF containers via
# Singularity --bind /opt/muxi-tools. The server adds this bind and
# prepends /opt/muxi-tools/bin to PATH when spawning formations.
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
#     exec --bind /opt/muxi-tools /sif/runtime.sif \
#     bash -c 'export PATH=/opt/muxi-tools/bin:$PATH && python -m muxi.utils.run_formation /formation/formation.yaml'

FROM ubuntu:24.04

LABEL maintainer="MUXI AI <hello@muxi.ai>"
LABEL org.opencontainers.image.source="https://github.com/muxi-ai/runtime-runner"
LABEL org.opencontainers.image.description="MUXI Runtime Runner with Singularity support (multi-arch: amd64/arm64)"
LABEL org.opencontainers.image.licenses="MIT"

# Avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# ============================================================================
# Install system packages (used to populate /opt/muxi-tools)
# ============================================================================

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # --- Singularity runtime ---
        singularity-container \
        squashfs-tools \
        fuse \
        # --- Tools to install into /opt/muxi-tools ---
        curl \
        wget \
        git \
        ca-certificates \
        jq \
        unzip \
        openssh-client \
        sqlite3 \
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
# Node.js 22 LTS (required for npx-based MCP servers)
# ============================================================================

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ============================================================================
# Build /opt/muxi-tools -- a self-contained directory of host tools
# that gets bind-mounted into the SIF at runtime via --bind /opt/muxi-tools.
# The server sets PATH, LD_LIBRARY_PATH, and other env vars.
#
# Structure:
#   /opt/muxi-tools/bin/          - binaries
#   /opt/muxi-tools/lib/          - shared libraries (from ldd)
#   /opt/muxi-tools/lib/node_modules/ - npm global modules
#   /opt/muxi-tools/share/fonts/  - font files
#   /opt/muxi-tools/share/certs/  - CA certificates
# ============================================================================

# Helper script: copy a binary + all its shared library dependencies
RUN echo '#!/bin/bash\n\
set -e\n\
BIN=$(which "$1" 2>/dev/null || echo "$1")\n\
[ -f "$BIN" ] || { echo "SKIP: $1 not found"; exit 0; }\n\
cp "$BIN" /opt/muxi-tools/bin/\n\
# Copy shared libs, but skip core glibc/system libs that the SIF already has.\n\
# Mixing glibc versions causes symbol errors.\n\
SKIP="libc.so|libm.so|libdl.so|librt.so|libpthread.so|libnsl.so|libutil.so|libresolv.so|libnss_|libcrypt.so|ld-linux|libmvec.so|libBrokenLocale.so|libanl.so|libthread_db.so"\n\
ldd "$BIN" 2>/dev/null | grep "=>" | awk "{print \$3}" | while read lib; do\n\
  base=$(basename "$lib")\n\
  echo "$base" | grep -qE "$SKIP" && continue\n\
  [ -f "$lib" ] && cp -n "$lib" /opt/muxi-tools/lib/ 2>/dev/null || true\n\
done\n\
echo "OK: $1"' > /tmp/stage-tool.sh && chmod +x /tmp/stage-tool.sh

RUN mkdir -p /opt/muxi-tools/bin /opt/muxi-tools/lib \
             /opt/muxi-tools/share/fonts /opt/muxi-tools/share/certs && \
    # ── Node.js + npm/npx ──
    /tmp/stage-tool.sh node && \
    cp -a /usr/lib/node_modules /opt/muxi-tools/lib/ && \
    ln -s ../lib/node_modules/npm/bin/npm-cli.js /opt/muxi-tools/bin/npm && \
    ln -s ../lib/node_modules/npm/bin/npx-cli.js /opt/muxi-tools/bin/npx && \
    # ── Core utilities ──
    /tmp/stage-tool.sh git && \
    /tmp/stage-tool.sh curl && \
    /tmp/stage-tool.sh wget && \
    /tmp/stage-tool.sh jq && \
    /tmp/stage-tool.sh unzip && \
    /tmp/stage-tool.sh ssh && \
    /tmp/stage-tool.sh sqlite3 && \
    /tmp/stage-tool.sh python3 && \
    # ── Document/media processing ──
    /tmp/stage-tool.sh ffmpeg && \
    /tmp/stage-tool.sh ffprobe && \
    /tmp/stage-tool.sh tesseract && \
    /tmp/stage-tool.sh pdftotext && \
    /tmp/stage-tool.sh pdfinfo && \
    /tmp/stage-tool.sh pandoc && \
    /tmp/stage-tool.sh dot && \
    # ── Build tools ──
    /tmp/stage-tool.sh make && \
    /tmp/stage-tool.sh gcc && \
    /tmp/stage-tool.sh g++ && \
    /tmp/stage-tool.sh cc && \
    # ── Fonts ──
    cp -r /usr/share/fonts/truetype/dejavu/* /opt/muxi-tools/share/fonts/ 2>/dev/null || true && \
    # ── CA certificates ──
    cp /etc/ssl/certs/ca-certificates.crt /opt/muxi-tools/share/certs/ 2>/dev/null || true && \
    # ── Linker cache for our lib dir ──
    echo "/opt/muxi-tools/lib" > /etc/ld.so.conf.d/muxi-tools.conf && ldconfig && \
    # ── Cleanup ──
    rm -f /tmp/stage-tool.sh && \
    echo "muxi-tools directory built successfully"

# ============================================================================
# Verify installations
# ============================================================================

RUN singularity --version && \
    /opt/muxi-tools/bin/node --version && \
    /opt/muxi-tools/bin/npx --version && \
    /opt/muxi-tools/bin/git --version && \
    /opt/muxi-tools/bin/curl --version 2>&1 | head -1 && \
    /opt/muxi-tools/bin/ffmpeg -version 2>&1 | head -1 && \
    /opt/muxi-tools/bin/python3 --version && \
    echo "All tools verified"

# Create mount points for SIF files and formation code
RUN mkdir -p /sif /formation

# Set working directory
WORKDIR /formation

# Singularity as entrypoint
ENTRYPOINT ["singularity"]

# Default command shows help
CMD ["--help"]
