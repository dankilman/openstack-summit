# Basic Terraform configuration using the Openstack provider


provider "openstack" {
    user_name = "${var.user_name}"
    tenant_name = "${var.tenant_name}"
    auth_url = "${var.auth_url}"
    password = "${var.password}"
}



#
# Resource - KeyPair
# Creates a new keypair in our openstack tenant.
# Will show up in OpenStack as "tf-keypair-1"
# Can be referenced elsewhere in terraform configuration as "keypair1"
#

resource "openstack_compute_keypair_v2" "keypair1" {
    name = "tf-keypair-1"
    region = ""
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAod4fYg8oQTIxAi6VhYhEoEwH/yOgSDWe0lttgM1DwB4g4Fct7H702vg5GZ6jkHKDUGHKNBgGoy0dycyUzer/KN+tLIDi0lXnxusPn+YMwhZli5lD5KRumoE3Li7gBwom/Hc/oyhKiT3JrJgIHUw7xaGz6jjDueIK5z9XbAYWTEAUeJXza/oopbljOLZV/PDgzmK0SBTyu1H3nSHNXwd8IHAR2YlmDfrN4OYVI5e2/G/YXVGsvHwm74RAV46YXKm9BFm1bJTnI6R6KnAjlXECEo96/ze/La3dmqw9VG7wJl78XP4lhItqIROYOw1Lu3e7cvj61f9bc8nfhbAlqkEF uricohen@MacBook-Air.local"
}



#
# Create security groups 
#

resource "openstack_compute_secgroup_v2" "mongo_security_group" {
    name = "mongo_security_group"
    description = "security group for mongodb"
    rule {
        from_port = 22
        to_port = 22
        ip_protocol = "tcp"
        cidr = "0.0.0.0/0"
    }
    rule {
        from_port = "${var.mongo_port}"
        to_port = "${var.mongo_port}"
        ip_protocol = "tcp"
        cidr = "0.0.0.0/0"
    }
    rule {
        from_port = "${var.mongo_web_port}"
        to_port = "${var.mongo_web_port}"
        ip_protocol = "tcp"
        cidr = "0.0.0.0/0"
    }
    # more mongo ports as needed 
}

resource "openstack_compute_secgroup_v2" "nodejs_security_group" {
    name = "nodejs_security_group"
    description = "security group for mongodb"
    rule {
        from_port = 22
        to_port = 22
        ip_protocol = "tcp"
        cidr = "0.0.0.0/0"
    }
    rule {
        from_port = "${var.nodejs_port}"
        to_port = "${var.nodejs_port}"
        ip_protocol = "tcp"
        cidr = "0.0.0.0/0"
    }
}


#
# Create a Network
#
resource "openstack_networking_network_v2" "tf_network" {
    region = ""
    name = "tf_network"
    admin_state_up = "true"
}

#
# Create a subnet in our new network
# Notice here we use a TF variable for the name of our network above.
#
resource "openstack_networking_subnet_v2" "tf_net_sub1" {
    region = ""
    network_id = "${openstack_networking_network_v2.tf_network.id}"
    cidr = "192.168.1.0/24"
    ip_version = 4
}

#
# Create a router for our network
#
resource "openstack_networking_router_v2" "tf_router1" {
    region = ""
    name = "tf_router1"
    admin_state_up = "true"
    external_gateway = "ca80ff29-4f29-49a5-aa22-549f31b09268"
}

#
# Attach the Router to our Network via an Interface
#
resource "openstack_networking_router_interface_v2" "tf_rtr_if_1" {
    region = ""
    router_id = "${openstack_networking_router_v2.tf_router1.id}"
    subnet_id = "${openstack_networking_subnet_v2.tf_net_sub1.id}"
}


#
# Create a Floating IP for our the load balancer
#
resource "openstack_compute_floatingip_v2" "lb_fip" {
    region = ""
    pool = "public-floating-601"
}


#
# Create mongod instances per the number of shards and replicas per 
# shard
#

resource "openstack_compute_instance_v2" "mongod_host" {
    # The connection block tells our provisioner how to
    # communicate with the resource (instance)
    
    count = "3"
    region = ""
    name = "mongod_host"
    image_name = "${var.image_name}"
    flavor_name = "${var.flavor_name}"
    key_pair = "tf-keypair-1"
    security_groups = ["mongo_security_group"]
    metadata {
        demo = "metadata"
    }
    network {
        uuid = "${openstack_networking_network_v2.tf_network.id}"
        fixed_ip_v4 = "${lookup(var.mongod_instance_ips, count.index)}"
    }
    connection {
        # The default username for our AMI
        user = "ubuntu"
        # The path to your keyfile
        key_file = "${var.key_path}"
    }
    provisioner "remote-exec" {
        scripts = [
        "scripts/install_mongo.sh"
        "start_mongod.sh"
        ]
    }
}

#
# Create mongo-cfg instances 
#

resource "openstack_compute_instance_v2" "mongod_cfg_host" {
    count = "3"
    region = ""
    name = "mongod_cfg_host"
    image_name = "${var.image_name}"
    flavor_name = "${var.flavor_name}"
    key_pair = "tf-keypair-1"
    security_groups = ["mongo_security_group"]
    metadata {
        demo = "metadata"
    }
    network {
        uuid = "${openstack_networking_network_v2.tf_network.id}"
        fixed_ip_v4 = "${lookup(var.mongo_cfg_instance_ips, count.index)}"
    }
    connection {
        # The default username for our AMI
        user = "ubuntu"
        # The path to your keyfile
        key_file = "${var.key_path}"
    }
    provisioner "remote-exec" {
        scripts = [
        "scripts/install_mongo.sh"
        "start_mongo_cfg.sh"
        ]
    }
}


# Create nodejs instances 
#

resource "openstack_compute_instance_v2" "nodejs_host" {
    count = "3"
    region = ""
    name = "nodejs_host"
    image_name = "${var.image_name}"
    flavor_name = "${var.flavor_name}"
    key_pair = "tf-keypair-1"
    security_groups = ["nodejs_security_group"]
    metadata {
        demo = "metadata"
    }
    network {
        uuid = "${openstack_networking_network_v2.tf_network.id}"
        fixed_ip_v4 = "${lookup(var.nodejs_instance_ips, count.index)}"
    }
    connection {
        # The default username for our AMI
        user = "ubuntu"
        # The path to your keyfile
        key_file = "${var.key_path}"
    }
    provisioner "remote-exec" {
        scripts = [
        "scripts/install_mongo.sh"
        "start_mongos.sh"
        "scripts/install_node.sh"
        ]
    }
}


#
# Create a LB Monitor, Pool and VIP
#
resource "openstack_lb_monitor_v1" "tf_lb_mon_1" {
    region = ""
    type = "PING"
    delay = 30
    timeout = 5
    max_retries = 3
    admin_state_up = "true"
}


resource "openstack_lb_pool_v1" "tf_lb_pl_1" {
    region = ""
    name = "tf_lb_pl_1"
    protocol = "HTTP"
    subnet_id = "${openstack_networking_subnet_v2.tf_net_sub1.id}"
    lb_method = "ROUND_ROBIN"
    monitor_ids = ["${openstack_lb_monitor_v1.tf_lb_mon_1.id}"]
    member {
        address = "${lookup(var.nodejs_instance_ips, 0)}"
        region = ""
        port = 80
        admin_state_up = "true"
    }
    member {
        address = "${lookup(var.nodejs_instance_ips, 1)}"
        region = ""
        port = 80
        admin_state_up = "true"
    }
    member {
        address = "${lookup(var.nodejs_instance_ips, 2)}"
        region = ""
        port = 80
        admin_state_up = "true"
    }
}

resource "openstack_lb_vip_v1" "tf_lb_vip_1" {
    region = ""
    name = "tf_lb_vip_1"
    subnet_id = "${openstack_networking_subnet_v2.tf_net_sub1.id}"
    protocol = "HTTP"
    port = 80
    pool_id = "${openstack_lb_pool_v1.tf_lb_pl_1.id}"
    floating_ip="${openstack_compute_floatingip_v2.lb_fip.id}"
}
