#!/bin/bash
# deploy/scripts/build.sh - 编译 OpenSIPS

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENSIPS_DIR="/root/work/zf2zf/opensips/opensips"

usage() {
    echo "Usage: $0 [build|clean|install]"
    exit 1
}

build() {
    echo "=== Building OpenSIPS (all modules) ==="
    cd "$OPENSIPS_DIR"
    cp "$SCRIPT_DIR/../Makefile.conf" "$OPENSIPS_DIR/Makefile.conf"
    make clean
    make config
    make -j$(nproc)
    echo "=== Build Complete ==="
}

install_opensips() {
    echo "=== Installing OpenSIPS to /opt/zfnproxy/opensips ==="
    cd "$OPENSIPS_DIR"
    make install PREFIX=/opt/zfnproxy/opensips
    echo "=== Install Complete ==="
}

case "${1:-}" in
    build) build ;;
    clean)
        cd "$OPENSIPS_DIR"
        make clean
        ;;
    install) install_opensips ;;
    *) usage ;;
esac
