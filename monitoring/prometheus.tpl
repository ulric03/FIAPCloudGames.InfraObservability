global:
  scrape_interval: 15s

scrape_configs:

  - job_name: 'prometheus'
    static_configs:
      - targets: ['${prometheus}:9090']

  - job_name: 'loki'
    static_configs:
      - targets: ['${loki}:3100']

  - job_name: 'grafana'
    static_configs:
      - targets: ['${grafana}:3000']
  
  - job_name: 'users-api'
    static_configs:
      - targets: ['${users_api}']

  - job_name: 'games-api'
    static_configs:
      - targets: ['${games_api}']
