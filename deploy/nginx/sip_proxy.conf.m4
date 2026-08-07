# Nginx SIP UDP 负载均衡配置
# 由 gen-cfg.sh 生成
# 用法: m4 -DUPSTREAM1=20.20.136.66 -DUPSTREAM2=20.20.136.67 -DSIP_PORT=5060

load_module modules/ngx_stream_module.so;

events {
	worker_connections 768;
}

http {
    # 空 http 块，仅为兼容 systemd
}

stream {
    log_format basic '$remote_addr [$time_local] '
                     '$protocol $status $bytes_sent $bytes_received '
                     '$upstream_addr';

    access_log /var/log/nginx/sip_access.log basic;
    error_log /var/log/nginx/sip_error.log;

    # UDP 无法自动传递原始 IP，使用 ip_hash 保持客户端固定到同一节点
    upstream opensips_cluster {
ifdef(`UPSTREAM1',,`define(`UPSTREAM1', `20.20.136.66')')dnl
ifdef(`UPSTREAM2',,`define(`UPSTREAM2', `20.20.136.67')')dnl
ifdef(`SIP_PORT',,`define(`SIP_PORT', `5060')')dnl
        ip_hash;
        server UPSTREAM1:SIP_PORT weight=1 max_fails=3 fail_timeout=10s;
        server UPSTREAM2:SIP_PORT weight=1 max_fails=3 fail_timeout=10s;
    }

    server {
        listen SIP_PORT udp;
        listen [::]:SIP_PORT udp;

        proxy_buffer_size 4k;
        proxy_timeout 10s;

        proxy_pass opensips_cluster;
    }
}
