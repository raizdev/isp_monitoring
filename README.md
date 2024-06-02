# Install 
````nano .env````
- LOCAL_IP_ADDRESS=IP Address of your device

The stack uses a mikrotik monitoring dashboard. If you don't have a mikrotik remove it from the docker-compose.yml file
- MIKROTIK_GATEWAY=IP of Mikrotik Device

````nano /prometheus/prometheus.yml````
- Set IP Address of your device under RPi Telegraf Agent target in ispmonitor job

# Deploy with docker compose 

- Speedflux on Raspberry PI (ARM64) use 
````docker pull raizdev/speedflux````
- Speedflux for x86  use
````docker pull sethwv/speedflux````

# Import Speedflux on Grafana
https://grafana.com/grafana/dashboards/13053-speedtest/
