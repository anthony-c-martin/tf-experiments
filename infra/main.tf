terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.12.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.12.1"
    }
  }
}


provider "azurerm" {
  features {}
}

provider "kubernetes" {
  host = azurerm_kubernetes_cluster.cluster.kube_config[0].host

  client_key             = base64decode(azurerm_kubernetes_cluster.cluster.kube_config[0].client_key)
  client_certificate     = base64decode(azurerm_kubernetes_cluster.cluster.kube_config[0].client_certificate)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate)
}

resource "azurerm_resource_group" "rg" {
  name     = "ant-test"
  location = "eastus2"
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name       = "aks"
  location   = azurerm_resource_group.rg.location
  dns_prefix = "aks"

  resource_group_name = azurerm_resource_group.rg.name
  kubernetes_version  = "1.24.0"

  default_node_pool {
    name       = "aks"
    node_count = "1"
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "kubernetes_deployment" "back_deploy" {
  metadata {
    name = "azure-vote-back"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "azure-vote-back"
      }
    }
    template {
      metadata {
        labels = {
          app = "azure-vote-back"
        }
      }
      spec {
        container {
          name = "azure-vote-back"
          image = "mcr.microsoft.com/oss/bitnami/redis:6.0.8"
          env {
            name = "ALLOW_EMPTY_PASSWORD"
            value = "yes"
          }
          resources {
            requests = {
              cpu = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu = "250m"
              memory = "256Mi"
            }
          }
          port {
            container_port = 6379
            name = "redis"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "back_service" {
  metadata {
    name = "azure-vote-back"
  }
  spec {
    port {
      port = 6379
    }
    selector = {
      app = "azure-vote-back"
    }
  }
}

resource "kubernetes_deployment" "front_deploy" {
  metadata {
    name = "azure-vote-front"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "azure-vote-front"
      }
    }
    template {
      metadata {
        labels = {
          app = "azure-vote-front"
        }
      }
      spec {
        node_selector = {
          "beta.kubernetes.io/os" = "linux"
        }
        container {
          name = "azure-vote-front"
          image = "mcr.microsoft.com/azuredocs/azure-vote-front:v1"
          resources {
            requests = {
              cpu = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu = "250m"
              memory = "256Mi"
            }
          }
          port {
            container_port = 80
          }
          env {
            name = "REDIS"
            value = "azure-vote-back"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "front_service" {
  metadata {
    name = "azure-vote-front"
  }
  spec {
    type = "LoadBalancer"
    port {
      port = 80
    }
    selector = {
      app = "azure-vote-front"
    }
  }
}