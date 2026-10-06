#!/usr/bin/env bash
# Builds the two IW7 GSC compilers that iw7-mod embeds, so the mod can be
# compile-checked offline against both client versions.
#
#   release : auroramod/gsc-tool @ 833822d0  (deps/gsc-tool pin of iw7-mod v1.1.0)
#   develop : auroramod/gsc-tool @ 0be361a4  (deps/gsc-tool pin of iw7-mod develop c0a1c6da)
#
# Usage:  tools/setup_compilers.sh [toolchain-dir]      (default: .toolchain)
# Output: <toolchain-dir>/bin/gsc-tool-iw7-release
#         <toolchain-dir>/bin/gsc-tool-iw7-develop
# Needs:  Linux x86_64, git, curl, tar, make, clang/clang++ with C++20 support.
#
# The older commit's premake5.lua uses a flag that premake beta8 rejects, so
# each pin is generated with the premake version its own CI used.
set -euo pipefail

TOOLCHAIN_DIR="${1:-.toolchain}"
GSC_TOOL_REPO="https://github.com/auroramod/gsc-tool"
RELEASE_COMMIT="833822d0c680f1a7a9a8cfdc4dd42b74bddb385f"
DEVELOP_COMMIT="0be361a4b22be0d0997b92ad94506ee5a5f99fc9"
PREMAKE_URL_BASE="https://github.com/premake/premake-core/releases/download"

mkdir -p "$TOOLCHAIN_DIR/src" "$TOOLCHAIN_DIR/bin" "$TOOLCHAIN_DIR/premake"
TOOLCHAIN_DIR="$(cd "$TOOLCHAIN_DIR" && pwd)"

fetch_premake() {
    local version="$1"
    local dir="$TOOLCHAIN_DIR/premake/$version"
    if [ ! -x "$dir/premake5" ]; then
        mkdir -p "$dir"
        curl -sSL --fail -o "$dir/premake.tar.gz" \
            "$PREMAKE_URL_BASE/v$version/premake-$version-linux.tar.gz"
        tar -xzf "$dir/premake.tar.gz" -C "$dir"
        chmod 755 "$dir/premake5"
    fi
    echo "$dir/premake5"
}

checkout() {
    local name="$1" commit="$2"
    local dir="$TOOLCHAIN_DIR/src/gsc-tool-$name"
    if [ ! -d "$dir/.git" ]; then
        git init -q "$dir"
        git -C "$dir" remote add origin "$GSC_TOOL_REPO"
    fi
    git -C "$dir" fetch -q --depth 1 origin "$commit"
    git -C "$dir" checkout -q --detach FETCH_HEAD
    git -C "$dir" submodule update -q --init --depth 1 deps/zlib deps/cxxopts
    echo "$dir"
}

build() {
    local name="$1" commit="$2" premake_version="$3" premake_action="$4"
    local src premake
    echo "==> gsc-tool ($name) @ ${commit:0:8}"
    src="$(checkout "$name" "$commit")"
    premake="$(fetch_premake "$premake_version")"
    (cd "$src" && "$premake" "$premake_action" > /dev/null)
    CC=clang CXX=clang++ make -s -C "$src/build" config=release_amd64 xsk-tool -j"$(nproc)"
    cp "$src/build/bin/amd64/release/gsc-tool" "$TOOLCHAIN_DIR/bin/gsc-tool-iw7-$name"
    echo "    -> $TOOLCHAIN_DIR/bin/gsc-tool-iw7-$name"
}

build release "$RELEASE_COMMIT" 5.0.0-beta2 gmake2
build develop "$DEVELOP_COMMIT" 5.0.0-beta8 gmake

echo "Done. Compile with: <bin> -m comp -g iw7 -s pc <file.gsc>"
