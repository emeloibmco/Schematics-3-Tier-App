provider "ibm" {
  generation         = 1
  region             = "us-south"
}

variable "ibmcloud_api_key" {
  description = "Enter your IBM Cloud API Key, you can get your IBM Cloud API key using: https://console.bluemix.net/iam#/apikeys"
}

variable "ibmcloud_resource_group" {
  description = "Enter your IBM Cloud resource group"
}

data "ibm_resource_group" "group" {
  name = "${var.ibm_resource_group}"
}

resource "ibm_is_ssh_key" "sshkey" {
  name       = "sshforjoomla"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLkp7uT/BGP3Jky3qO9hX1JK4GtxL/O0mVUFzKXKdsvU4QLPGGKOgGmlPkcN0mautI7qIKxWzNGXd8zElvSr34Ofy6bFCrOcZsL8dbR7bIe6OhEMCbfrYFziQQTv4aiC5g3HYQW1Y+DEwwOFisbgCJ7hE+p1SCec+ydqifOXQ9fNWbbAeODgaSI2XQLrHo/3I90Gi2uYarjHvjE3KBLlLUY6p7Y5VW4Ir0H+Ey3L+CzejXpCjc/FnZxJtzMslZt41Y5LkyljCHzDYatY/jd/fPrfhBmzq0IhDdp2/mA2a/6MJhqOkQPlkl8E0xGUJu78XFTzwnclT0CoAFtHiqWEUF"
}

resource "ibm_is_vpc" "vpcforjoomla" {
  name = "vpcjoomla"
  resource_group = "${data.ibm_resource_group.group.id}"
}

resource "ibm_is_subnet" "subnetjoomla" {
  name            = "subnetjoomla"
  vpc             = "${ibm_is_vpc.vpcforjoomla.id}"
  zone            = "us-south-1"
  total_ipv4_address_count= "256"
}

resource "ibm_is_security_group" "securitygroupforjoomla" {
  name = "securitygroupforjoomla"
  vpc  = "${ibm_is_vpc.vpcforjoomla.id}"
  resource_group = "${data.ibm_resource_group.group.id}"
}


resource "ibm_is_instance" "vsi1" {
  name    = "joomla-mysql"
  image   = "7eb4e35b-4257-56f8-d7da-326d85452591"
  profile = "b-2x8"
  resource_group = "${data.ibm_resource_group.group.id}"


  primary_network_interface {
    subnet = "${ibm_is_subnet.subnetjoomla.id}"
    security_groups = ["${ibm_is_security_group.securitygroupforjoomla.id}"]
  }

  vpc       = "${ibm_is_vpc.vpcforjoomla.id}"
  zone      = "us-south-1"
  keys = ["${ibm_is_ssh_key.sshkey.id}"]
}

resource "ibm_is_security_group_rule" "testacc_security_group_rule_all" {
  group     = "${ibm_is_security_group.securitygroupforjoomla.id}"
  direction = "inbound"
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "testacc_security_group_rule_icmp" {
  group     = "${ibm_is_security_group.securitygroupforjoomla.id}"
  direction = "inbound"
  icmp {
    type = 8
  }
}

resource "ibm_is_security_group_rule" "testacc_security_group_rule_out" {
  group     = "${ibm_is_security_group.securitygroupforjoomla.id}"
  direction = "outbound"
}

resource "ibm_is_floating_ip" "fip1" {
  name   = "testfip1"
  target = "${ibm_is_instance.vsi1.primary_network_interface.0.id}"
  resource_group = "${data.ibm_resource_group.group.id}"
}

resource "ibm_container_vpc_cluster" "iks-joomla" {
  name              = "iks-joomla"
  vpc_id            = "${ibm_is_vpc.vpcforjoomla.id}"
  flavor            = "c2.2x4"
  worker_count      = "1"
  resource_group_id = "${data.ibm_resource_group.group.id}"
  zones {
    subnet_id = "${ibm_is_subnet.subnetjoomla.id}"
    name      = "${ibm_is_subnet.subnetjoomla.zone}"
  }
}

output sshcommand {
  value = "ssh root@${ibm_is_floating_ip.fip1.address}"
}
