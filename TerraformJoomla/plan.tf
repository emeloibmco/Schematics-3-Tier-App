provider "ibm" {
  generation         = 1
  region             = "us-south"
}

data "ibm_is_vpc" "vpcjoomla" {
  name = "vpcjoomla"
  resource_group_id = "${data.ibm_resource_group.group.id}"
}

output "lb_ip" {
  value = "${ibm_is_vpc.vpcjoomla}"
}


data "ibm_resource_group" "group" {
  name = "${var.resource_group}"
}

data "ibm_container_cluster_config" "iks_cluster_config" {
    cluster_name_id = "iks-joomla"
    resource_group_id = "${data.ibm_resource_group.group.id}"
}

output path {
  value = "${data.ibm_container_cluster_config.iks_cluster_config.config_file_path}"
}

provider "kubernetes" { 
    load_config_file       = "true"
    config_path = "${data.ibm_container_cluster_config.iks_cluster_config.config_file_path}"
}


resource "kubernetes_pod" "joomla" {
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
              value = "10.10.10.0:3306"
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
  metadata {
    name = "joomla-example"
  }
  spec {
    selector = {
      App = "${kubernetes_pod.joomla.metadata.0.labels.App}"
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}