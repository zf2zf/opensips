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
                     '$upstream_addr $upstream_connect_time $upstream_first_byte_time';

    log_format detailed '$remote_addr:$remote_port -> $upstream_addr '
                     '$protocol $status $bytes_sent $bytes_received '
                     '$upstream_connect_time $upstream_first_byte_time '
                     '$upstream_bytes_received';

    access_log /var/log/nginx/sip_access.log detailed;
    error_log /var/log/nginx/sip_error.log;

    # UDP 负载均衡，使用 hash 保持客户端固定到同一节点
    upstream opensips_cluster {
ifdef(`UPSTREAM1',,`define(`UPSTREAM1', `20.20.136.66')')dnl
ifdef(`UPSTREAM2',,`define(`UPSTREAM2', `20.20.136.67')')dnl
ifdef(`SIP_PORT',,`define(`SIP_PORT', `5060')')dnl
        hash $remote_addr consistent;
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
