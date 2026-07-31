# deploy/cfg/cluster/node_a.cfg.m4
# 节点 A 配置（node_id=1）

modparam("clusterer", "my_node_info", "cluster_id=1, node_id=1, url=bin:LOCAL_IP:BIN_PORT, flags=seed")
modparam("clusterer", "neighbor_node_info", "cluster_id=1, node_id=2, url=bin:PEER_IP:BIN_PORT")
