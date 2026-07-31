#!/bin/bash
# deploy/scripts/sync-to-peer.sh - 将配置同步到对等节点

set -e

INSTALL_PREFIX="/opt/zfnproxy/opensips"
LOCAL_CFG="$INSTALL_PREFIX/etc/opensips/local.cfg"

if [ ! -f "$LOCAL_CFG" ]; then
    echo "Error: $LOCAL_CFG not found"
    exit 1
fi

source "$LOCAL_CFG"

RSYNC_OPTS="-az --delete -e ssh"

echo "=== Syncing config to peer ($peer_ip) ==="
rsync $RSYNC_OPTS \
    "$INSTALL_PREFIX/etc/opensips/local.cfg" \
    "$INSTALL_PREFIX/etc/opensips/ha.cfg" \
    "$INSTALL_PREFIX/etc/opensips/cluster/" \
    "$INSTALL_PREFIX/etc/opensips/opensips_proxy.cfg" \
    "root@$peer_ip:$INSTALL_PREFIX/etc/opensips/"

echo "=== Sync Complete ==="
