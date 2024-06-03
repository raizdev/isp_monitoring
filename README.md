# Install 
Setup will ask a number of questions to complete the installation process. After this is done, the docker container is installed

installation can be started by running the command:
````bash ./setup.sh````

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
