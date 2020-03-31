provider "ibm" {
  generation         = 1
  region             = "us-south"
}

variable "ibmcloud_api_key" {
  description = "Enter your IBM Cloud API Key, you can get your IBM Cloud API key using: https://console.bluemix.net/iam#/apikeys"
}

variable "resource_group" {
  description = "Name of resource group to provision resources"
  default     = "landing-zone"
}

data "ibm_resource_group" "group" {
  name = "${var.resource_group}"
}

resource "ibm_is_ssh_key" "sshkey" {
  name       = "keysshforjoomla"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrj07zmf/ZgFlL/y7v6jNVzomf7zF6CLsSGi8BQQO8QYkAEXKUcWn+ZBMjdYV+k02cCT91L0u5JjYuDVuP434p94SyS9Ur9xVapz5kNub2JAWF4JgB9HyKnEkDJAk/596f7LpBslXs8cTzQIS6UnykCl9GKd825U+EwC2YMj/B3MAnxsTNYq27PNVo2aTH6OgufSb5h+2LfbREFfTDlDe/ASzKFUC9MxuJFJzOLeZtTMHPUQWq+0Z/WRybzEnDoQXoA0b/8UxzGvvbgPLGSPEt+qtb6r9BAqXuWFpQ+YIDODYWjg5J1T0a6xpf1iwGXhDuH8z42DlN395vpV/B1f+B"
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

resource "ibm_is_floating_ip" "ipf1" {
  name   = "ipforjoomla"
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
  value = "ssh root@${ibm_is_floating_ip.ipf1.address}"
}
