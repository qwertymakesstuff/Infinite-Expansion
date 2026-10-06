#!/usr/bin/env bash
# Builds the two IW7 GSC compilers that iw7-mod embeds (plus tools/ixcc on top
# of each) and fetches the stock script reference, so tools/check.py can verify
# the mod offline against both client versions.
#
#   release : auroramod/gsc-tool @ 833822d0  (deps/gsc-tool pin of iw7-mod v1.1.0)
#   develop : auroramod/gsc-tool @ 0be361a4  (deps/gsc-tool pin of iw7-mod develop c0a1c6da)
#
# Usage:  tools/setup_compilers.sh [toolchain-dir]      (default: .toolchain)
# Output: <toolchain-dir>/bin/gsc-tool-iw7-release   stock gsc-tool (disassembler, plain compiles)
#         <toolchain-dir>/bin/gsc-tool-iw7-develop
#         <toolchain-dir>/bin/ixcc-release           tools/ixcc linked against the same pin:
#         <toolchain-dir>/bin/ixcc-develop           compiles like iw7-mod's in-game loader
#         <toolchain-dir>/src/iw7-gsc-dump/          decompiled stock IW7 scripts (mjkzy/iw7-gsc-dump
#                                                    @ 1dd48a78); check.py verifies stock far calls
#                                                    against it. Reference only, never shipped.
#         <toolchain-dir>/src/iw7-mod-ui/            iw7-mod's own Lua UI scripts (auroramod/iw7-mod
#                                                    develop @ c0a1c6da, sparse); check.py only lets the
#                                                    mod's Lua use API names these scripts use.
# Optional: luac5.1 (Debian/Ubuntu package lua5.1) for the Lua syntax check.
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
STOCK_DUMP_REPO="https://github.com/mjkzy/iw7-gsc-dump"
STOCK_DUMP_COMMIT="1dd48a78e55ef9c99519fc5221a206168ce2e98a"
IW7MOD_REPO="https://github.com/auroramod/iw7-mod"
IW7MOD_COMMIT="c0a1c6dacd33c86320b308656d9ba895291c2198"
IXCC_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ixcc/ixcc.cpp"

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

    local lib="$src/build/bin/amd64/release"
    clang++ -std=c++20 -O2 -DNDEBUG -Wall -Wextra -I"$src/include" "$IXCC_SOURCE" \
        "$lib/libxsk-gsc.a" "$lib/libxsk-utils.a" "$lib/libzlib.a" \
        -o "$TOOLCHAIN_DIR/bin/ixcc-$name"
    echo "    -> $TOOLCHAIN_DIR/bin/ixcc-$name"
}

fetch_stock_dump() {
    local dir="$TOOLCHAIN_DIR/src/iw7-gsc-dump"
    echo "==> iw7-gsc-dump @ ${STOCK_DUMP_COMMIT:0:8}"
    if [ ! -d "$dir/.git" ]; then
        git init -q "$dir"
        git -C "$dir" remote add origin "$STOCK_DUMP_REPO"
    fi
    git -C "$dir" fetch -q --depth 1 origin "$STOCK_DUMP_COMMIT"
    git -C "$dir" checkout -q --detach FETCH_HEAD
    echo "    -> $dir/decompiled"
}

fetch_iw7mod_ui() {
    local dir="$TOOLCHAIN_DIR/src/iw7-mod-ui"
    echo "==> iw7-mod ui_scripts @ ${IW7MOD_COMMIT:0:8}"
    if [ ! -d "$dir/.git" ]; then
        git init -q "$dir"
        git -C "$dir" remote add origin "$IW7MOD_REPO"
        git -C "$dir" sparse-checkout set data/cdata/ui_scripts
    fi
    git -C "$dir" fetch -q --depth 1 --filter=blob:none origin "$IW7MOD_COMMIT"
    git -C "$dir" checkout -q --detach FETCH_HEAD
    echo "    -> $dir/data/cdata/ui_scripts"
}

build release "$RELEASE_COMMIT" 5.0.0-beta2 gmake2
build develop "$DEVELOP_COMMIT" 5.0.0-beta8 gmake
fetch_stock_dump
fetch_iw7mod_ui

echo "Done. Check the mod with: python3 tools/check.py"
