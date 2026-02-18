# giveth-monitor

*A generalized monitoring stack to be installed on individual servers that we want to monitor.*

Consists of:

- **cAdvisor**: Exports docker container metrics for consumption by Prometheus
- **Node-Exporter**: Exports server system metrics for consumption by Prometheus
- **Grafana Alloy**: Ships application and container logs to Loki (replaces Promtail)

Supports both **Docker Compose** and **Docker Swarm** deployments. In Swarm mode, Alloy extracts stable service-level labels (`swarm_service`, `stack`) so dashboards survive container rescheduling.

## 1 - Configure and run the monitoring stack

Clone the repo:

```
git clone https://github.com/Giveth/giveth-monitor.git
```

Copy `.env.template` to `.env` and fill in the values:

```
cp .env.template .env && nano .env
```

## 2 - Alloy configuration

*Grafana Alloy is the log collector that ships logs from host machines to the Loki server.*

The configuration lives in `alloy-config.alloy` and uses Alloy's River syntax. It collects:

1. **Caddy logs** from `/var/giveth/logs/caddy/*` (static file scraping)
2. **Docker container logs** via the Docker socket (automatic discovery)

### Labels extracted automatically

| Label | Source | Available in |
|-------|--------|-------------|
| `container` | Container name | Compose + Swarm |
| `logstream` | stdout / stderr | Compose + Swarm |
| `job` | `logging_jobname` container label | Compose + Swarm |
| `swarm_service` | `com.docker.swarm.service.name` | Swarm only |
| `stack` | `com.docker.stack.namespace` | Swarm only |
| `swarm_task` | `com.docker.swarm.task.name` | Swarm only |
| `node_id` | `com.docker.swarm.node.id` | Swarm only |
| `service` | Short service name (without stack prefix) | Swarm only |
| `compose_service` | `com.docker.compose.service` | Compose only |
| `compose_project` | `com.docker.compose.project` | Compose only |

### Grafana dashboard tips

- **Swarm deployments**: Use `{swarm_service="mystack_web"}` or `{service="web"}` in LogQL queries. Create dashboard variables with `label_values(swarm_service)`.
- **Compose deployments**: Use `{compose_service="web"}` or `{container="web-1"}`.
- **Avoid** filtering by `container` name in Swarm — it changes on every reschedule.

### Environment variables

All credentials are injected via `sys.env()` in the Alloy config. Required variables in `.env`:

- `LOKI_URL` — Loki push endpoint (e.g. `https://loki.mydomain.com`)
- `INSTANCE` — Tenant ID, unique per monitored instance (e.g. `staging`)
- `LOKIUSER` — Loki basic auth username
- `LOKIPASS` — Loki basic auth password

## 3 - Customization

1. Modify `docker-compose.yml` to add volume mounts for additional log directories
2. Update `alloy-config.alloy` to add more `local.file_match` + `loki.source.file` blocks for additional static log paths
3. Ensure `.env` has been configured — Alloy depends on a **Loki URL** and credentials

## Operate

### Start (Docker Compose)

```
docker-compose up -d
```

### Start (Docker Swarm)

```
docker stack deploy -c docker-compose.yml giveth-monitor
```

### Stop

```
docker-compose down
```

### Restart a service

```
docker-compose up -d servicename
```

### Alloy debugging UI

Alloy includes a built-in web UI for inspecting component health, discovered targets, and pipeline status:

```
http://<host>:12345
```

## Firewall configuration

If the host runs Caddy or another reverse proxy, open the necessary ports for the monitoring stack. Run `01-allow-ports.sh` which restricts access to a trusted IP:

- **8080** — cAdvisor metrics
- **12345** — Alloy UI / API
- **9100** — Node-Exporter metrics

## Migration from Promtail

The previous `promtail-config.yml` is kept for reference. To migrate an existing deployment:

1. Update `.env`: replace `PROMTAIL_VERSION` with `ALLOY_VERSION=v1.13.1`
2. Pull the new images: `docker-compose pull`
3. Restart: `docker-compose up -d`
4. Verify at `http://<host>:12345` that Alloy is discovering containers
5. Update firewall rules: run `01-allow-ports.sh` (port changed from 9080 to 12345)
6. If the Loki Docker log driver was previously installed, remove it to avoid double-ingestion:
   ```
   sudo bash 02-remove-loki-docker-driver.sh
   ```
   This disables/removes the plugin and cleans up `/etc/docker/daemon.json` (with backup and confirmation).
