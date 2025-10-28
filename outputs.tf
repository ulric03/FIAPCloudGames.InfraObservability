


output "prometheus_fqdn" {
	description = "FQDN do Container App Prometheus"
	value       = azurerm_container_app.prometheus.latest_revision_fqdn
}

output "grafana_fqdn" {
	description = "FQDN do Container App Grafana"
	value       = azurerm_container_app.grafana.latest_revision_fqdn
}

output "loki_fqdn" {
	description = "FQDN do Container App Loki"
	value       = azurerm_container_app.loki.latest_revision_fqdn
}
