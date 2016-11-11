defaults REDIS
	mode tcp
	timeout connect  4s
	timeout server  30s
	timeout client  30s
 
frontend ft_redis
	bind *:6379 name redis
	default_backend bk_redis
 
backend bk_redis
	option tcp-check
	tcp-check connect
	tcp-check send PING\r\n
	tcp-check expect string +PONG
	tcp-check send info\ replication\r\n
	tcp-check expect string \#\ Replication\r\n
	tcp-check expect string role:master\r\n
	tcp-check send QUIT\r\n
	tcp-check expect string +OK
${join("\n", formatlist("\tserver %s %s:6379 check inter 1s", split(",", serverNames), split(",", serverIpAddresses)))}