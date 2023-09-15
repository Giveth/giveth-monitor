# giveth-monitor

A generalized monitoring stack to be installed on individual servers that we want to monitor.

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

Promtail is the log client that will be shipping the logs from host machines to the Loki Server

## Configuration

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
docker-compose restart servicename
```
