sentinel monitor ${cluster_name} ${master_ip_address} 6379 2
sentinel down-after-milliseconds ${cluster_name} 5000
sentinel parallel-syncs ${cluster_name} 1
sentinel failover-timeout ${cluster_name} 10000