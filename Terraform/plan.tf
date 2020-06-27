provider "ibm" {
  generation         = 1
  region             = "us-south"
}

data "ibm_resource_group" "group" {
  name = "${var.resource_group}"
}

resource "ibm_is_ssh_key" "sshkey" {
  name       = "keysshforjoomla"
  public_key = "${var.ssh_public}"
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

data "ibm_container_cluster_config" "iks_cluster_config" {
    cluster_name_id = "iks-joomla"
    resource_group_id = "${data.ibm_resource_group.group.id}"
    depends_on = ["ibm_container_vpc_cluster.iks-joomla"]
}

provider "kubernetes" { 
    depends_on = ["ibm_container_vpc_cluster.iks-joomla"]
    load_config_file = "true"
    config_path = "${data.ibm_container_cluster_config.iks_cluster_config.config_file_path}"
}


resource "kubernetes_pod" "joomla" {
  depends_on = ["ibm_container_vpc_cluster.iks-joomla"]
  metadata {
    name = "joomla-example"
    labels = {
      App = "joomla"
    }
  }

  spec {
    container {
      image = "joomla"
      name  = "joomla"

          env {
              name = "JOOMLA_DB_HOST"
              value = "10.241.91.80:3306"
          }
           
           env {
              name = "JOOMLA_DB_PASSWORD"
              value = "Passw0rd"
          }
          env {
              name = "JOOMLA_DB_USER"
              value = "joomla"
          }


      port {
        container_port = 80
      }
    }
  }
}

resource "kubernetes_service" "joomla" {
  depends_on = ["ibm_container_vpc_cluster.iks-joomla"]
  metadata {
    name = "joomla-example"
  }
  spec {
    selector = {
      App = "${kubernetes_pod.joomla.metadata.labels.App}"
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

output "lb_ip" {
  depends_on = ["ibm_container_vpc_cluster.iks-joomla"]
  value = "${kubernetes_service.joomla.load_balancer_ingress.ip}"
}