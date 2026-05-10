#!/bin/bash
# Native macOS build for ffmpeg-patch (fms fork).
#
# BtbN/FFmpeg-Builds 의 build.sh 는 docker cross-compile 만 지원 — macOS 는 별 path.
# Apple SDK 라이선스 + Mach-O 빌드 환경 때문에 GitHub Actions macos-13/macos-14
# runner 에서 native build.
#
# Usage: ./build-macos.sh <amd64|arm64>
#
# Env:
#   FFMPEG_REPO   — git remote (default https://github.com/FFmpeg/FFmpeg.git)
#   GIT_BRANCH    — branch (default master)
#
# Output:
#   artifacts/ffmpeg-<describe>-macos-<arch>-gpl-shared-8.1.tar.xz
#
# Doc: docs/ffmpeg-patch-macos-build.md (fms repo)

set -xe

ARCH="${1:?usage: build-macos.sh <amd64|arm64>}"
case "$ARCH" in
    amd64|arm64) ;;
    *) echo "error: unknown arch '$ARCH' (expected amd64 or arm64)"; exit 1 ;;
esac

cd "$(dirname "$0")"

FFMPEG_REPO="${FFMPEG_REPO:-https://github.com/FFmpeg/FFmpeg.git}"
GIT_BRANCH="${GIT_BRANCH:-master}"

WORK_DIR="$(pwd)/ffbuild-macos"
ARTIFACT_DIR="$(pwd)/artifacts"

rm -rf "$WORK_DIR" "$ARTIFACT_DIR"
mkdir -p "$WORK_DIR" "$ARTIFACT_DIR"

cd "$WORK_DIR"

# Clone ffmpeg source
git clone --filter=blob:none --branch="$GIT_BRANCH" "$FFMPEG_REPO" ffmpeg
cd ffmpeg

DESCRIBE="$(git describe --tags --always 2>/dev/null || git rev-parse --short HEAD)"

# pkg-config path setup (Homebrew on Apple Silicon = /opt/homebrew, intel = /usr/local)
if [[ "$ARCH" == "arm64" ]]; then
    BREW_PREFIX="/opt/homebrew"
else
    BREW_PREFIX="/usr/local"
fi
export PKG_CONFIG_PATH="$BREW_PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"

PREFIX="$WORK_DIR/prefix"

./configure \
    --prefix="$PREFIX" \
    --pkg-config-flags="--static" \
    --enable-gpl --enable-version3 \
    --disable-debug \
    --enable-shared --disable-static \
    --enable-libzmq --enable-libsrt \
    --enable-libx264 --enable-libx265 \
    --enable-libvpx \
    --enable-libopus --enable-libvorbis \
    --enable-libfreetype --enable-libharfbuzz --enable-libfribidi \
    --enable-libxml2 \
    --enable-libdav1d --enable-libsvtav1 \
    --enable-videotoolbox \
    --extra-version="$(date +%Y%m%d)"

make -j"$(sysctl -n hw.ncpu)" V=1
make install

# Package
cd "$WORK_DIR"
ARTIFACT_NAME="ffmpeg-${DESCRIBE}-macos-${ARCH}-gpl-shared-8.1"
mv prefix "$ARTIFACT_NAME"
tar -cJf "$ARTIFACT_DIR/${ARTIFACT_NAME}.tar.xz" "$ARTIFACT_NAME"

echo "=== build-macos.sh done ==="
ls -lh "$ARTIFACT_DIR"
