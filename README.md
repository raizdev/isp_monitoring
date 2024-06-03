Monitor your home connection in Grafana with Prometheus, InfluxDB and Telegraf. <br>
A mikrotik device is not required to use this stack, the installer will give you a choice.

# Installation
Setup will ask a number of questions to complete the installation process.

installation can be started by running the command:
````bash ./setup.sh````

After following instructions docker container will be installed.

# Mikrotik Dashboard
If you are planning to enable the mikrotik stack in grafana don't forget to create a user with password.
If this is not done, the API will not be able to read anything and the dashboard in Grafana will not work.

````
/user group add name=mktxp_group policy=api,read
/user add name=mktxp_user group=mktxp_group password=mktxp_user_password
````

# Import Speedflux on Grafana
* Create new dashboard under ISP Monitoring folder
* Import JSON ID ````13053```` and select influxdb as datasource

# Environment variables

| Tag Name 	| Description 	|
|-	|-	|
| server_id 	| Speedtest ID of the server (multiple servers seperate with comma) default empty = auto	|	|
| speedtest_interval 	| Interval for processing speedtest in minutes (default 15 minutes) 	|	|
| ping_interval 	| Ping interval in seconds (default is 60) 	|	|
| ping_targets 	| Ping targets (default 8.8.8.8, 1.1.1.1) 	|	|
