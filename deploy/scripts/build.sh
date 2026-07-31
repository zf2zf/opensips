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
    echo "=== Building OpenSIPS ==="
    cd "$OPENSIPS_DIR"

    # 从模板生成 Makefile.conf
    cp "$OPENSIPS_DIR/Makefile.conf.template" "$OPENSIPS_DIR/Makefile.conf"

    # 设置 exclude_modules：排除所有不需要的模块，只保留 deploy/Makefile.conf 中启用的模块
    # 启用的模块: db_sqlite sqlops signaling sl tm rr maxfwd sipmsgops db_text usrloc registrar acc proto_udp dispatcher uac nathelper xml tls_openssl clusterer proto_bin proto_bins mi_script
    # 其中 db_sqlite, xml, tls_openssl 在模板 exclude 中，需要特别处理
    sed -i 's/^exclude_modules?=.*/exclude_modules?= aaa_diameter aaa_radius auth_jwt auth_web3 b2b_logic_xml cachedb_cassandra cachedb_couchbase cachedb_dynamodb cachedb_memcached cachedb_mongodb cachedb_redis carrierroute cgrates compression cpl_c db_berkeley db_http db_mysql db_oracle db_perlvdb db_postgres db_unixodbc dialplan emergency event_rabbitmq event_kafka event_sqs h350 httpd http2d identity jabber json launch_darkly ldap lua mi_xmlrpc mmgeoip opentelemetry osp perl pi_http presence presence_dialoginfo presence_mwi presence_reginfo presence_xml presence_dfks proto_ipsec proto_sctp proto_tls proto_wss pua pua_bla pua_dialoginfo pua_mi pua_reginfo pua_usrloc pua_xmpp python regex rabbitmq_consumer rest_client rls rtp.io siprec sngtc snmpstats stir_shaken tls_mgm tls_wolfssl uuid xcap xcap_client xmpp/' "$OPENSIPS_DIR/Makefile.conf"

    make clean
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
