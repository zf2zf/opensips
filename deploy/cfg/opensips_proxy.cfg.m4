#
# OpenSIPS GB28181 代理配置（m4 模板）
# 用于 GB28181 视频平台，代理设备与平台之间的 SIP 信令
#
# 用法: m4 -DMODE=cluster -DNODE_ID=1 -DLOCAL_IP=10.0.0.11 -DVIP=10.0.0.10 -DSOCKET_PORT=5060 -DBIN_PORT=5070 etc/opensips_proxy.cfg.m4 > opensips_proxy.cfg
#

########### m4 宏定义 ##########
# 使用 ifdef guard: 只有当宏未定义时才设置默认值，允许通过 -D 或 env.m4 覆盖
ifdef(`LOCAL_IP',,`define(`LOCAL_IP', `10.0.0.11')')dnl
ifdef(`VIP',,`define(`VIP', `10.0.0.10')')dnl
ifdef(`SOCKET_PORT',,`define(`SOCKET_PORT', `5060')')dnl
ifdef(`BIN_PORT',,`define(`BIN_PORT', `5070')')dnl
ifdef(`NODE_ID',,`define(`NODE_ID', `1')')dnl
ifdef(`MODE',,`define(`MODE', `single')')dnl
ifdef(`MPATH',,`define(`MPATH', `/opt/zfnproxy/opensips/lib64/opensips/modules/')')dnl
ifdef(`DB_PATH',,`define(`DB_PATH', `/opt/zfnproxy/opensips/data/opensips.db')')dnl
ifdef(`DTEXT_PATH',,`define(`DTEXT_PATH', `/opt/zfnproxy/opensips/etc/dbtext')')dnl

########### 全局参数 ##########

log_level=3
xlog_level=3
stderror_enabled=yes
syslog_enabled=yes
syslog_facility=LOG_LOCAL0
udp_workers=4

# SIP 监听地址（m4 宏）
# 监听本地 IP
socket = udp:LOCAL_IP:SOCKET_PORT
# 监听 VIP（仅 MASTER 节点，NODE_ID=1）
ifdef(`NODE_ID',,`define(`NODE_ID', `1')')dnl
ifelse(NODE_ID, `1', `socket = udp:VIP:SOCKET_PORT')dnl

########### 模块加载 ##########

mpath="MPATH"

loadmodule "db_sqlite.so"
loadmodule "sqlops.so"
modparam("sqlops", "db_url", "sqlite:///DB_PATH")

loadmodule "signaling.so"
loadmodule "sl.so"
loadmodule "tm.so"
modparam("tm", "fr_timeout", 5)
modparam("tm", "fr_inv_timeout", 30)
modparam("tm", "restart_fr_on_each_reply", 0)
modparam("tm", "onreply_avp_mode", 1)

loadmodule "rr.so"
modparam("rr", "append_fromtag", 0)

loadmodule "maxfwd.so"
loadmodule "sipmsgops.so"
loadmodule "db_text.so"
loadmodule "usrloc.so"
loadmodule "registrar.so"
loadmodule "acc.so"
loadmodule "proto_udp.so"
loadmodule "dispatcher.so"
loadmodule "uac.so"
loadmodule "nathelper.so"
loadmodule "xml.so"
loadmodule "mi_script.so"
modparam("mi_script", "pretty_printing", 1)

# usrloc 配置：sql-only 模式，直接操作 SQLite
# use_domain=false 让 lookup/save 基于 username 匹配，支持跨域查询
modparam("usrloc", "db_url", "sqlite:///DB_PATH")
modparam("usrloc", "working_mode_preset", "sql-only")
modparam("usrloc", "use_domain", false)
modparam("usrloc", "sql_write_mode", "write-through")
modparam("usrloc", "nat_bflag", "NAT")

# === 集群模式条件配置 ===
ifelse(MODE, `cluster', `
# ---- 集群模式额外模块 ----
loadmodule "proto_bin.so"
loadmodule "proto_bins.so"
loadmodule "clusterer.so"

# ---- clusterer 参数 ----
modparam("clusterer", "db_mode", 0)
modparam("clusterer", "ping_interval", 4)
modparam("clusterer", "ping_timeout", 1000)
modparam("clusterer", "node_timeout", 60)
modparam("clusterer", "seed_fallback_interval", 10)

# ---- proto_bin 监听 ----
listen = bin:LOCAL_IP:BIN_PORT

# ---- usrloc 集群模式 ----
modparam("usrloc", "working_mode_preset", "full-sharing-cluster")
modparam("usrloc", "location_cluster", 1)

# ---- 节点拓扑 ----
ifelse(NODE_ID, `1', `
    include_file "cluster/node_a.cfg"
', `
    include_file "cluster/node_b.cfg"
')

xlog("L_INFO", "CLUSTER: starting in cluster mode, node_id=NODE_ID\n");
')


# dispatcher 配置：使用 db_text 文件（自动创建表）
modparam("dispatcher", "db_url", "sqlite:///DB_PATH")

# nathelper 配置
modparam("nathelper", "nortpproxy_str", "")

# db_text 配置
modparam("db_text", "db_mode", 1)

# 数据库初始化（启动时执行一次）
startup_route {
    xlog("L_INFO", "DB: ready\n");
}

########### 工具路由 ##########

route[maxfwd] {
    if (!mf_process_maxfwd_header(10)) {
        sl_send_reply(483, "Too Many Hops");
        return -1;
    }
    return 1;
}

route[dedup] {
    t_check_trans();
    return 1;
}

route[relay] {
    forward();
    exit;
}

########### 注册处理 ##########

route[register] {
    $avp(expires_hdr) = $hdr(Expires);
    fix_nated_contact();

    xlog("L_INFO", "REGISTER: $fu expires=$avp(expires_hdr)\n");

    if (!save("location", "no-reply"))
        xlog("L_ERR", "REGISTER: failed for $tu\n");

    # 设备注销时：级联删除该设备的所有子通道
    if ($avp(expires_hdr) == "0") {
        xlog("L_INFO", "REGISTER: unregister, finding child channels\n");
        # 查找该设备的所有子通道
        sql_query("SELECT username FROM location WHERE attr LIKE '%' || '$tu' || '%'", "$avp(ra)");
        $var(i) = 0;
        while ($var(i) < 1000) {
            $avp(del_chan_id) = $(avp(ra)[$var(i)]);
            if ($avp(del_chan_id) == NULL) {
                xlog("L_INFO", "REGISTER: found $var(i) child channels\n");
                break;
            }
            xlog("L_INFO", "REGISTER: deleting child $avp(del_chan_id)\n");
            usrloc_rm_user("location", $avp(del_chan_id));
            $var(i) = $var(i) + 1;
        }
    } else {
        xlog("L_INFO", "REGISTER: not unregister (expires=$avp(expires_hdr))\n");
    }

    t_on_reply("handle_nat");
    if (ds_select_dst(1, 0, "f"))
        t_relay();
    else
        sl_send_reply(503, "Service Unavailable");
    return 1;
}

########### MESSAGE 处理 ##########

route[message] {
    # === Keepalive 心跳检查 ===
    # Content-Type: Application/MANSCDP+xml 且包含 Keepalive
    if ($hdr(Content-Type) == "Application/MANSCDP+xml" && $rb =~ "Keepalive") {
        route(check_keepalive);
        exit;
    }

    # === 正常 MESSAGE 处理 ===
    # 设备响应：To 本机 + From 非本机
    # 设备查询：To 外部地址
    if (is_myself("$td") && !is_myself("$fd")) {
        route(device_response);
    } else {
        route(platform_query);
    }
    return 1;
}

route[check_keepalive] {
    # 从 From header 提取设备ID（Keepalive 发起方）
    # From: <sip:11010000001320000001@1101000000>;tag=xxx
    $var(device_id) = $fU;

    if ($var(device_id) == "" || $var(device_id) == NULL) {
        # fallback: 从 XML DeviceID 提取
        $var(device_id) = $xml($rb/Notify/DeviceID.val);
    }

    if ($var(device_id) == "" || $var(device_id) == NULL) {
        xlog("L_WARN", "KEEPALIVE: cannot extract device ID from From or XML\n");
        sl_send_reply(200, "OK");
        return;
    }

    xlog("L_INFO", "KEEPALIVE: device=$var(device_id)\n");

    # 检查设备是否已注册
    $ru = "sip:" + $var(device_id) + "@" + $td;
    lookup("location");

    if ($rc > 0) {
        sl_send_reply(200, "OK");
    } else {
        xlog("L_INFO", "KEEPALIVE: device $var(device_id) NOT registered, reply 403\n");
        sl_send_reply(401, "Not Registered");
    }
}

route[platform_query] {
    # 平台查询设备：lookup 查设备注册地址
    if (lookup("location")) {
        t_on_reply("handle_nat");
        t_relay();
        return 1;
    }
    sl_send_reply(404, "Device Not Found");
    return 1;
}

route[device_response] {
    # 按命令类型分发
    if ($rb =~ "Catalog") {
        route(process_catalog);
    } else if ($rb =~ "DeviceInfo") {
        route(process_device_info);
    }
    # 转发设备响应到平台
    append_hf("P-hint: outbound\r\n");
    t_on_reply("handle_nat");
    if (ds_select_dst(1, 0, "f"))
        t_relay();
    else
        sl_send_reply(503, "Service Unavailable");
    return 1;
}

route[process_catalog] {
    # 解析 Catalog XML，INSERT 子通道到 location 表
    $xml(cat) = $rb;
    $var(cnt) = 0;
    $var(i) = 0;

    while ($var(i) < 256) {
        $avp(chan_id) = $xml(cat/Response/DeviceList/Item[$var(i)]/DeviceID.val);
        if ($avp(chan_id) == NULL || $(avp(chan_id){s.len}) == 0)
            break;

        $avp(parent_id) = $xml(cat/Response/DeviceList/Item[$var(i)]/ParentID.val);

        # 跳过录像机自身（通道ID == 父ID）
        if ($avp(chan_id) != $avp(parent_id)) {
            $var(sip_socket) = "udp:" + $si + ":" + $sp;
            $avp(recorder_contact) = "sip:" + $avp(chan_id) + "@" + $si + ":" + $sp;
            $avp(channel_attr) = "parent=" + $fu;
            xlog("L_INFO", "CATALOG: calling usrloc_add_contact table=location aor=$avp(chan_id) contact=$avp(recorder_contact) expires=7200 attr=$avp(channel_attr)\n");
            # 使用导出的 usrloc_add_contact 函数直接添加联系人
            if (usrloc_add_contact("location", $avp(chan_id), $avp(recorder_contact), 0, $ci, $ua, $avp(channel_attr))) {
                xlog("L_INFO", "CATALOG: insert channel $avp(chan_id) ok\n");
            } else {
                xlog("L_INFO", "CATALOG: insert channel $avp(chan_id) failed\n");
            }
            $var(cnt) = $var(cnt) + 1;
        }
        $var(i) = $var(i) + 1;
    }
    xlog("L_INFO", "CATALOG: inserted $var(cnt) channels\n");
    $xml(cat) = NULL;
    return 1;
}

route[process_device_info] {
    # DeviceInfo 响应处理（可扩展）
    return 1;
}

########### INVITE 处理 ##########

route[invite] {
    do_accounting("log");

    # GB28181 回放：平台 INVITE 子通道
    # 条件：From/To 域名是本机；R-URI 域名非本机；用户名纯数字
    if ((is_myself("$fd") || is_myself("$td")) && !is_myself("$rd") && $rU =~ "^[0-9]+$") {
        if (route(gb28181_playback)) {
            exit;
        }
        sl_send_reply(404, "Channel Not Found");
        return -1;
    }

    # 标准位置查询
    if (!lookup("location")) {
        t_reply(404, "Not Found");
        return -1;
    }

    do_accounting("log", "missed");
    route(forward);
    return 1;
}

route[gb28181_playback] {
    # sql-only 模式下 lookup 直接查 SQLite
    if (lookup("location")) {
        t_on_reply("handle_nat");
        t_relay();
        return 1;
    }
    return -1;
}

route[forward] {
    t_on_reply("handle_nat");
    if (!ds_select_dst(1, 0, "f")) {
        t_reply(503, "Service Unavailable");
        return -1;
    }
    t_relay();
    return 1;
}

########### 主路由 ##########

route {
    route(maxfwd);
    if ($rc < 0) exit;

    if (has_totag()) {
        route(in_dialog);
        exit;
    }

    route(dedup);

    if (is_method("CANCEL")) {
        forward();
        exit;
    }

    if (is_method("REGISTER")) {
        route(register);
        exit;
    }

    if (is_method("MESSAGE")) {
        route(message);
        exit;
    }

    if (is_method("INVITE")) {
        route(invite);
        exit;
    }

    if (is_method("PUBLISH|SUBSCRIBE")) {
        sl_send_reply(503, "Service Unavailable");
        exit;
    }

    # 其他方法
    if (!lookup("location", "method-filtering")) {
        t_reply(404, "Not Found");
        exit;
    }
    do_accounting("log", "missed");
    route(forward);
}

route[in_dialog] {
    if (is_method("ACK") && t_check_trans()) {
        t_relay();
        return 1;
    }
    if (!loose_route()) {
        sl_send_reply(404, "Not here");
        return -1;
    }
    if (is_method("BYE"))
        do_accounting("log", "failed");
    route(relay);
    return 1;
}

########### 回复路由 ##########

onreply_route[handle_nat] {
    # === GB28181 SDP 修复 ===
    # 设备 200 OK 缺少 a=setup:active / a=connection:new
    # 注入这两个属性告知 EasyGBS 设备是 active 端（主动发起 TCP 连接）
    if (t_check_status("200") && $mb =~ "application/sdp") {
        fix_nated_sdp("add-no-rtpproxy", "$socket_in(ip)", "\r\na=setup:active\r\na=connection:new");
    }
    fix_nated_contact();
}

########### 失败路由 ##########

failure_route[missed_call] {
    if (t_was_cancelled())
        exit;
}
