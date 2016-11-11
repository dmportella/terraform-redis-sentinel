# terraform-redis-sentinel
A quick example for setting up Redis with Replication with Sentinel for High availability and fronted by HAproxy TCP load balancing.

## Terraform

Check everything is oke.

`terraform plan`

Apply changes.

`terraform apply`

# Setup Includes

* redis master with 2 slaves for replication
* 3 x sentinel nodes managing the high availability
* HAProxy for redis load balancing 

All nodes can be scaled up or down.

> *Note*: please ensure change the volumes locations before running
> Also bear in mind that the way the config files are rendered the `\r\n` dont get escaped properly so if haproxy is not work just make sure it matches the tpl file. I am working on a solution for that.
