# giveth-monitor

*A generalized monitoring stack to be installed on individual servers that we want to monitor.*

Consists of:

- cAdvisor: Exports docker container metrics for consumption by Prometheus
- Node-Exporter: Exports server system metrics for consumption by Prometheus
- Promtail: Exports application logs for consumption by Loki

## 1 - Configure and run the monitoring stack
Clone the repo
```
git clone https://github.com/Giveth/giveth-monitor.git
```
Copy `.env.template` to `.env` and fill in the values

```
cp .env.template .env $$ nano .env
```

## 2 - Promtail configuration

*Promtail is the log client that will be shipping the logs from host machines to the Loki Server*

1. Modify the `docker-compose.yml` file to add a new volume for a persistent log directory
2. Configure the paths of all application logs to monitor in the `promtail-config.yml` file. Out of the box `giveth-monitor` is configured to observe a deployed `giveth-all` stack.
3. Make sure `.env` had been copied and modified from `.env.template` - promtail depends on a **Loki URL**

## Operate

### Start

```
docker-compose up -d
```

### Stop

```
docker-compose down
```

### Restart a service

```
docker-compose up -d containername
```

## Add to a giveth-all host

If the host is configured to run caddy, you will need to open the necessary ports for the monitoring stack:


**allow cAdvisor:**
```
sudo ufw route allow proto tcp from any to any port 8080
```

**allow node-exporter:**
```
sudo ufw route allow proto tcp from any to any port 9100
```

**allow promtail**
```
sudo ufw route allow proto tcp from any to any port 9080
```
Or just run `01-allow-ports.sh`

## Install Loki Docker log driver

This is specifically configured to send the logs to the Giveth instance.

Run `02-install-loki-docker-log-driver.sh`

## Further configuration
Have a look at the two config files.

1 - check `docker-compose.yml`:

- correct network to observe other containers:
```
networks:
  external_network:
    external:
      name: giveth-all_giveth
```

2 - check `promtail-config.yml` if you send more than one promtail exporter to your Loki instance:

- the `tenant_id` should be unique
- the labels for `job name`and `job`should be unique
