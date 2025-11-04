# Variáveis para resource group existente
variable "resource_group_name" {
  description = "Nome do resource group já existente no Azure."
  type        = string
  default     = "Fase-3"
}

variable "resource_group_location" {
  description = "Localização do resource group já existente no Azure."
  type        = string
  default     = "brazilsouth"
}


## Data source para buscar o ID do ambiente gerenciado pelo nome
data "azurerm_container_app_environment" "observability_env" {
  name                = "managedEnvironment-Fase-3"
  resource_group_name = var.resource_group_name
}


## Azure Container App - Observability Stack (Grafana, Loki juntos)

resource "azurerm_container_app" "grafana" {
  revision_mode                = "Single"
  name                         = "grafana"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = data.azurerm_container_app_environment.observability_env.id

  template {
    container {
      name   = "grafana"
      image  = "grafana/grafana:latest"
      cpu    = 0.5
      memory = "1Gi"
      env {
        name  = "GF_SECURITY_ADMIN_PASSWORD"
        value = "admin"
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 3000
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = {
    environment = "observability"
  }
}

resource "azurerm_container_app" "loki" {
  revision_mode                = "Single"
  name                         = "loki"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = data.azurerm_container_app_environment.observability_env.id

  template {
    container {
      name   = "loki"
      image  = "grafana/loki:latest"
      cpu    = 0.5
      memory = "1Gi"
    }
  }

  ingress {
    external_enabled = true
    target_port      = 3100
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

