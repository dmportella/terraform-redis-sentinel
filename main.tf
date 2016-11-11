# Configure the Docker provider
provider "docker" {
	host = "unix:///var/run/docker.sock"
}

resource "docker_container" "redis-master" {
	image = "redis:latest"
	name = "redis-master"

	restart = "always"

	/*volumes {
		container_path  = "/usr/local/etc/redis"
		host_path = "/home/dmportella/_workspaces/terraform/redis-sentinel/config/master"
		read_only = false
	}

	command = ["redis-server", "/usr/local/etc/redis/master.conf"]*/
}

resource "docker_container" "redis-slaves" {
	depends_on = ["docker_container.redis-master"]

	image = "redis:latest"

	name = "redis-slave-${format("%02d", count.index+1)}"

	restart = "always"

	count = 2

	volumes {
		container_path  = "/usr/local/etc/redis"
		host_path = "/home/dmportella/_workspaces/terraform/redis-sentinel/config/slaves"
		read_only = false
	}

	command = ["redis-server", "/usr/local/etc/redis/slaves.conf"]
}

resource "docker_container" "redis-sentinel" {
	depends_on = ["docker_container.redis-slaves"]

	image = "redis:latest"
	
	name = "redis-sentinel-${format("%02d", count.index+1)}"

	restart = "always"

	count = 3

	volumes {
		container_path  = "/usr/local/etc/redis"
		host_path = "/home/dmportella/_workspaces/terraform/redis-sentinel/config/sentinel"
		read_only = false
	}

	command = ["redis-server", "/usr/local/etc/redis/sentinel.conf", "--sentinel"]
}

resource "docker_container" "haproxy-redis-lb" {
	depends_on = ["docker_container.redis-sentinel"]

	image = "haproxy:1.5.18"
	name = "haproxy-redis-lb"

	restart = "always"

	volumes {
		container_path  = "/usr/local/etc/haproxy"
		host_path = "/home/dmportella/_workspaces/terraform/redis-sentinel/config/haproxy"
		read_only = false
	}
}

resource "null_resource" "wait" {

	provisioner "local-exec" {
		command = "echo \"${data.template_file.haproxy_config.rendered}\" > ./config/haproxy/haproxy.cfg"
	}

	provisioner "local-exec" {
		command = "echo \"${data.template_file.redis_slaves_config.rendered}\" > ./config/slaves/slaves.conf"
	}

	provisioner "local-exec" {
		command = "echo \"${data.template_file.redis_sentinel_config.rendered}\" > ./config/sentinel/sentinel.conf"
	}

	provisioner "local-exec" {
		command = "echo 'Sleeping for 5...' && sleep 5"
	}

}

data "template_file" "haproxy_config" {
	template = "${file("${path.module}/config/haproxy/haproxy.tpl")}"

	vars {
		serverNames = "${docker_container.redis-master.name},${join(",", docker_container.redis-slaves.*.name)}"
		serverIpAddresses = "${docker_container.redis-master.ip_address},${join(",", docker_container.redis-slaves.*.ip_address)}"
	}
}

data "template_file" "redis_slaves_config" {
	template = "${file("${path.module}/config/slaves/slaves.tpl")}"

	vars {
		master_ip_address = "${docker_container.redis-master.ip_address}"
	}
}

data "template_file" "redis_sentinel_config" {
	template = "${file("${path.module}/config/sentinel/sentinel.tpl")}"

	vars {
		cluster_name = "redis-cluster"
		master_ip_address = "${docker_container.redis-master.ip_address}"
	}
}