#!/bin/bash
# Build MUXI Runtime Runner for multiple architectures
# Creates images for both amd64 and arm64

set -e

IMAGE_NAME="ghcr.io/muxi-ai/runtime-runner"
VERSION="${1:-latest}"

echo "======================================"
echo "🏗️  MUXI Runtime Runner Builder"
echo "======================================"
echo ""
echo "📦 Configuration:"
echo "   Image: $IMAGE_NAME"
echo "   Version: $VERSION"
echo ""

# Check if buildx is available
if ! docker buildx version > /dev/null 2>&1; then
    echo "❌ Docker buildx is required for multi-arch builds"
    echo "   Install: docker buildx install"
    exit 1
fi

# Create/use buildx builder
BUILDER_NAME="muxi-multiarch"
if ! docker buildx inspect "$BUILDER_NAME" > /dev/null 2>&1; then
    echo "🔧 Creating buildx builder: $BUILDER_NAME"
    docker buildx create --name "$BUILDER_NAME" --use
else
    docker buildx use "$BUILDER_NAME"
fi

echo "🔨 Building multi-arch images..."
echo ""

# Build and push (or load for local testing)
if [ "$2" = "--push" ]; then
    echo "📤 Building and pushing to registry..."
    docker buildx build \
        --platform linux/amd64,linux/arm64 \
        --tag "$IMAGE_NAME:$VERSION" \
        --tag "$IMAGE_NAME:latest" \
        --push \
        .
    echo ""
    echo "✅ Pushed to registry:"
    echo "   • $IMAGE_NAME:$VERSION"
    echo "   • $IMAGE_NAME:latest"
else
    echo "💾 Building for local architecture only..."
    echo "   (Use --push to build and push multi-arch)"
    docker buildx build \
        --tag "$IMAGE_NAME:$VERSION" \
        --tag "$IMAGE_NAME:latest" \
        --load \
        .
    echo ""
    echo "✅ Built locally:"
    docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
fi

echo ""
echo "✨ Test the image:"
echo "   docker run --rm $IMAGE_NAME:$VERSION --version"
echo ""
