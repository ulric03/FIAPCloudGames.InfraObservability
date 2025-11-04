
## Azure Container App - Observability Stack (Prometheus)

resource "azurerm_container_app" "prometheus" {
  revision_mode                = "Single"
  name                         = "prometheus"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = data.azurerm_container_app_environment.observability_env.id

  template {
    container {
      name   = "prometheus"
      image  = "997353105/prometheus-fcg:custom"
      cpu    = 0.5
      memory = "1Gi"
    }
  }

  ingress {
    external_enabled = true
    target_port      = 9090
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = {
    environment = "observability"
  }
}


# Provider Azure e configuração inicial

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}


# Gera o arquivo de configuração do Prometheus localmente com os FQDNs das Container Apps
resource "local_file" "prometheus_config" {
  filename = "${path.module}/monitoring/prometheus.yml"
  content  = templatefile("${path.module}/monitoring/prometheus.tpl", {
    prometheus = azurerm_container_app.prometheus.latest_revision_fqdn
  })

  # Garantir que o arquivo seja reescrito quando os FQDN mudarem
  depends_on = [
    azurerm_container_app.prometheus,
    azurerm_container_app.loki,
    azurerm_container_app.grafana,
  ]
}




