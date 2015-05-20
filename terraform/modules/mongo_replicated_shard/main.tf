
resource "openstack_compute_keypair_v2" "mongo_kp" {
    name = "mongo_kp"
    region = ""
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAod4fYg8oQTIxAi6VhYhEoEwH/yOgSDWe0lttgM1DwB4g4Fct7H702vg5GZ6jkHKDUGHKNBgGoy0dycyUzer/KN+tLIDi0lXnxusPn+YMwhZli5lD5KRumoE3Li7gBwom/Hc/oyhKiT3JrJgIHUw7xaGz6jjDueIK5z9XbAYWTEAUeJXza/oopbljOLZV/PDgzmK0SBTyu1H3nSHNXwd8IHAR2YlmDfrN4OYVI5e2/G/YXVGsvHwm74RAV46YXKm9BFm1bJTnI6R6KnAjlXECEo96/ze/La3dmqw9VG7wJl78XP4lhItqIROYOw1Lu3e7cvj61f9bc8nfhbAlqkEF uricohen@MacBook-Air.local"
}

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

#
# Create mongod instances
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