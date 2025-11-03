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


## Azure Container App - Observability Stack (Prometheus, Grafana, Loki juntos)


resource "azurerm_container_app" "prometheus" {
  revision_mode                = "Single"
  name                         = "prometheus"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = data.azurerm_container_app_environment.observability_env.id

  template {
    container {
      name   = "prometheus"
      image  = "prom/prometheus:latest"
      cpu    = 0.5
      memory = "1Gi"
      volume_mount {
        name       = "prometheus-config"
        mount_path = "/etc/prometheus"
      }
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
  
  volume {
    name = "prometheus-config"
    azure_file {
      share_name           = azurerm_storage_share.prometheus.name
      storage_account_name = azurerm_storage_account.prom.name
      storage_account_key  = data.azurerm_storage_account_keys.prom.keys[0].value
    }
  }

  tags = {
    environment = "observability"
  }
}

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

resource "random_id" "suffix" {
  byte_length = 4
}

resource "azurerm_storage_account" "prom" {
  name                     = "promstor${random_id.suffix.hex}"
  resource_group_name      = var.resource_group_name
  location                 = var.resource_group_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "prometheus" {
  name                 = "prometheus-config"
  storage_account_name = azurerm_storage_account.prom.name
  quota                = 1
}

data "azurerm_storage_account_keys" "prom" {
  name                = azurerm_storage_account.prom.name
  resource_group_name = var.resource_group_name
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
    loki       = azurerm_container_app.loki.latest_revision_fqdn
    grafana    = azurerm_container_app.grafana.latest_revision_fqdn
    # mantendo serviços locais (ex.: APIs) como antes; ajuste se necessário
    users_api  = "users-api:5000"
    games_api  = "games-api:5000"
  })

  # Garantir que o arquivo seja reescrito quando os FQDN mudarem
  depends_on = [
    azurerm_container_app.prometheus,
    azurerm_container_app.loki,
    azurerm_container_app.grafana,
  ]
}




