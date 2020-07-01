
data "ibm_container_cluster_config" "iks_cluster_config" {
    cluster_name_id = "iks-joomla"
    resource_group_id = "${data.ibm_resource_group.group.id}"
    #depends_on = ["ibm_container_vpc_cluster.iks-joomla"]
}


provider "kubernetes" { 
    load_config_file       = "false"
    host                   = "${data.ibm_container_cluster_config.iks_cluster_config.host}"
    token                  = "${data.ibm_container_cluster_config.iks_cluster_config.token}"
    cluster_ca_certificate = "${data.ibm_container_cluster_config.iks_cluster_config.ca_certificate}"
}

resource "kubernetes_deployment" "joomla" {
  metadata {
    name = "joomla-example"
    labels = {
      app = "joomla"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "joomla"
      }
    }

    template {
      metadata {
        labels = {
          app = "joomla"
        }
      }

      spec{
        container {
          image = "joomla"
          name  = "joomla"

            env {
                name = "JOOMLA_DB_HOST"
                value = "${ibm_is_instance.vsi1.primary_network_interface.0.primary_ipv4_address}"
            }
            
            env {
                name = "JOOMLA_DB_PASSWORD"
                value = "Passw0rd"
            }
            env {
                name = "JOOMLA_DB_USER"
                value = "joomla"
            }
            env {
                name = "JOOMLA_DB_NAME"
                value = "joomla"
            }
        }
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
      App = "${kubernetes_deployment.joomla.metadata.0.labels.app}"
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

output host {
  value = "host para la base de datos: ${ibm_is_instance.vsi1.primary_network_interface.0.primary_ipv4_address}"
}