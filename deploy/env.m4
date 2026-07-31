# deploy/env.m4 - m4 预处理器环境变量
# 部署时通过 gen-cfg.sh 设置这些变量

define(`MODE', `single')
define(`NODE_ID', `1')
define(`LOCAL_IP', `127.0.0.1')
define(`PEER_IP', `127.0.0.1')
define(`VIP', `127.0.0.1')
define(`SOCKET_PORT', `5060')
define(`BIN_PORT', `5566')
