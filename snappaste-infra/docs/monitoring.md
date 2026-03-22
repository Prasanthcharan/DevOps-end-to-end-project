# Monitoring on Kubernetes — How It Works

## Overview

There are two approaches to monitoring a Kubernetes cluster:

- **Traditional**: Prometheus + Promtail + Grafana
- **Modern**: Grafana Alloy + Mimir + Loki + Grafana

Both approaches end up in the same place — metrics and logs visible in Grafana. The difference is in how the data is collected and stored.

---

## Part 1 — Traditional Stack (Prometheus + Promtail)

### Components

```
┌──────────────────────────────────────────────────────────────────┐
│                        KUBERNETES CLUSTER                         │
│                                                                  │
│  ┌─────────────────┐   ┌──────────────────┐   ┌──────────────┐ │
│  │  Your App Pods  │   │  kube-state-     │   │ node-exporter│ │
│  │  (FastAPI etc.) │   │  metrics         │   │ (DaemonSet)  │ │
│  │  /metrics       │   │  /metrics        │   │ /metrics     │ │
│  └────────┬────────┘   └────────┬─────────┘   └──────┬───────┘ │
│           │                     │                    │          │
│           └─────────────────────┼────────────────────┘          │
│                                 │  HTTP GET /metrics every 15s  │
│                                 ▼                                │
│                          ┌────────────┐                          │
│                          │ Prometheus │ ← scrapes all targets    │
│                          │            │   stores on local disk   │
│                          └─────┬──────┘                          │
│                                │                                  │
│  Pod stdout/stderr             │                                  │
│  (written to node disk)        │                                  │
│  /var/log/pods/...             │                                  │
│       │                        │                                  │
│       ▼                        │                                  │
│  ┌──────────┐                  │                                  │
│  │ Promtail │ ← reads log      │                                  │
│  │(DaemonSet│   files from     │                                  │
│  │ one per  │   node disk      │                                  │
│  │  node)   │                  │                                  │
│  └────┬─────┘                  │                                  │
│       │                        │                                  │
└───────┼────────────────────────┼──────────────────────────────────┘
        │                        │
        ▼                        ▼
    ┌───────┐              ┌──────────┐
    │  Loki │              │ Grafana  │
    │(logs) │◄─────────────│ queries  │
    └───────┘              │ both     │
                           └──────────┘
```

---

### 1. Prometheus — Metrics Scraper and Storage

**What it is**: A time-series database and scraping engine.

**How it works — Pull model:**
Prometheus does NOT wait for apps to push metrics to it. Instead, it actively pulls (scrapes) metrics from every target on a schedule (default every 15 seconds).

```
Prometheus → HTTP GET http://backend-pod:8000/metrics → receives text like:
  http_requests_total{method="POST", path="/api/pastes"} 142
  http_request_duration_seconds{quantile="0.99"} 0.023
  process_resident_memory_bytes 45678592
```

**How it discovers targets (Service Discovery):**
Prometheus does not need a hardcoded list of IPs. It talks to the Kubernetes API and automatically finds all pods, services, and nodes to scrape.

```yaml
# Prometheus config — tells it to find all pods in K8s
scrape_configs:
  - job_name: kubernetes-pods
    kubernetes_sd_configs:
      - role: pod          # talk to K8s API, get list of all pods
    relabel_configs:
      # only scrape pods that have this annotation:
      # prometheus.io/scrape: "true"
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
```

So to make Prometheus scrape your FastAPI pod, you add an annotation to the pod:
```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8000"
  prometheus.io/path: "/metrics"
```

**Where metrics are stored:**
Prometheus stores metrics on local disk using its own time-series database (TSDB). Data is written in 2-hour blocks and compacted over time.

```
/prometheus/data/
  ├── 01BKGV7JBM69T2G1BGBGM6KB12/   ← 2hr block
  ├── 01BKGTZQ1ZTBGX3NQPAQ5TDPSB/   ← 2hr block
  └── wal/                            ← write-ahead log (recent data in memory)
```

**Problem with local storage:**
- If the node dies, all metrics are lost
- Can only scale vertically (bigger disk)
- No HA — single point of failure

---

### 2. kube-state-metrics — Kubernetes Object State

**What it is**: A service that watches the Kubernetes API and exposes the state of K8s objects as Prometheus metrics.

**How it works:**
```
kube-state-metrics pod
  → watches K8s API (like kubectl does)
  → converts K8s object state into metrics
  → exposes them at /metrics for Prometheus to scrape
```

**What metrics it exposes:**
```
kube_pod_status_phase{pod="backend-abc123", phase="Running"} 1
kube_deployment_status_replicas_available{deployment="backend"} 2
kube_deployment_spec_replicas{deployment="backend"} 2
kube_pod_container_status_restarts_total{container="backend"} 0
kube_persistentvolumeclaim_status_phase{pvc="postgres-data"} Bound
```

**Key difference from Prometheus:**
- Prometheus scrapes app metrics (what your code is doing)
- kube-state-metrics exposes K8s resource state (what Kubernetes knows about your pods)

---

### 3. node-exporter — Node (Machine) Metrics

**What it is**: A DaemonSet — one pod runs on every node — that exposes hardware and OS metrics.

**How it works:**
```
node-exporter pod (on each node)
  → reads from Linux kernel (/proc, /sys filesystems)
  → exposes at /metrics for Prometheus to scrape
```

**What metrics it exposes:**
```
node_cpu_seconds_total{cpu="0", mode="idle"} 12345.67
node_memory_MemAvailable_bytes 2147483648
node_filesystem_avail_bytes{mountpoint="/"} 10737418240
node_network_receive_bytes_total{device="eth0"} 987654321
```

---

### 4. Promtail — Log Shipper

**What it is**: A DaemonSet — one pod per node — that reads pod log files from the node disk and ships them to Loki.

**How Kubernetes stores logs:**
When a container writes to stdout or stderr, the kubelet (K8s node agent) captures it and writes it to a file on the node:
```
/var/log/pods/
  └── snappaste_backend-abc123_xyz/
      └── backend/
          └── 0.log    ← actual log file on node disk
```

**How Promtail reads them:**
```
Promtail pod
  → mounts /var/log/pods/ from the node (hostPath volume)
  → watches for new log files
  → tails each file (like tail -f)
  → adds K8s labels (pod name, namespace, app name)
  → ships to Loki via HTTP
```

**Promtail config:**
```yaml
scrape_configs:
  - job_name: kubernetes-pods
    kubernetes_sd_configs:
      - role: pod
    pipeline_stages:
      - docker: {}          # parse Docker log format
      - labels:
          app:              # add app label from pod labels
          namespace:
```

---

### 5. Loki — Log Storage

**What it is**: A log aggregation system designed by Grafana Labs. Stores logs indexed only by labels (not full text), making it very storage efficient.

**How it stores logs:**
```
Loki receives log stream:
  {namespace="snappaste", app="backend"} → "2026-03-22 INFO POST /api/pastes 201"
  {namespace="snappaste", app="backend"} → "2026-03-22 ERROR Database timeout"

Stores:
  - Index: just the labels (tiny)
  - Chunks: compressed raw log text (in S3 or local disk)
```

**How you query logs in Grafana (LogQL):**
```
{namespace="snappaste", app="backend"}              → all backend logs
{namespace="snappaste"} |= "ERROR"                  → logs containing ERROR
{app="backend"} | json | status_code >= 500         → parse JSON logs, filter 5xx
rate({app="backend"} |= "ERROR" [5m])               → error rate over 5 min
```

---

### 6. Grafana — Visualization

**What it is**: Dashboard and visualization UI. Does not store any data itself — it only queries Prometheus and Loki.

**Data sources configured:**
```
Prometheus → http://prometheus:9090   (metrics)
Loki       → http://loki:3100         (logs)
```

**How dashboards work:**
Each panel in Grafana is a query:
```
Panel: "Request Rate"
Query: rate(http_requests_total{app="backend"}[5m])
→ Grafana sends this to Prometheus, gets results, draws graph
```

---

## Part 2 — Modern Stack (Grafana Alloy + Mimir + Loki)

### Why the Change

The traditional stack has two problems:
1. **Two separate agents** — Prometheus (metrics) + Promtail (logs) — double the memory, double the config
2. **Prometheus local storage** — metrics lost if node dies, can't scale horizontally

The modern stack fixes both:
1. **One agent** — Grafana Alloy replaces both Prometheus scraper and Promtail
2. **Mimir** — replaces Prometheus local storage with S3-backed scalable storage

---

### Modern Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        KUBERNETES CLUSTER                         │
│                                                                  │
│  ┌─────────────────┐   ┌──────────────────┐   ┌──────────────┐ │
│  │  Your App Pods  │   │  kube-state-     │   │ node-exporter│ │
│  │  /metrics       │   │  metrics /metrics│   │ /metrics     │ │
│  └────────┬────────┘   └────────┬─────────┘   └──────┬───────┘ │
│           │                     │                    │          │
│           └─────────────────────┼────────────────────┘          │
│                                 │ scrape /metrics                │
│  /var/log/pods/ (node disk)     │                                │
│       │                         │                                │
│       └──────────┐              │                                │
│                  ▼              ▼                                │
│             ┌──────────────────────┐                            │
│             │    Grafana Alloy     │ ← single agent does both   │
│             │    (DaemonSet)       │   metrics + logs           │
│             └──────┬──────────────┘                            │
│                    │                                            │
└────────────────────┼────────────────────────────────────────────┘
                     │
          ┌──────────┴──────────┐
          │                     │
          ▼                     ▼
   remote_write HTTP      loki push HTTP
          │                     │
          ▼                     ▼
       Mimir                  Loki
    (metrics store)        (log store)
          │                     │
          └──────────┬──────────┘
                     ▼
                  Grafana
              (queries both)
                     │
               S3 (storage)
          ┌──────────┴──────────┐
          ▼                     ▼
  snappaste-mimir-blocks  snappaste-loki-chunks
```

---

### Grafana Alloy — The Unified Agent

**What it is**: A single agent that replaces Prometheus scraper + Promtail. Uses a pipeline-based config language called River (`.alloy` files).

**How it works internally:**

Alloy is built around **components** that connect together in a pipeline:

```
discover targets → scrape metrics → send to Mimir
discover pods   → read logs      → send to Loki
```

**Alloy config example:**
```alloy
// ── Discover all pods in K8s ──
discovery.kubernetes "pods" {
  role = "pod"
}

// ── Scrape metrics from discovered pods ──
prometheus.scrape "pods" {
  targets    = discovery.kubernetes.pods.targets
  forward_to = [prometheus.remote_write.mimir.receiver]
}

// ── Send metrics to Mimir ──
prometheus.remote_write "mimir" {
  endpoint {
    url = "http://mimir:9009/api/v1/push"
  }
}

// ── Read pod logs from node disk ──
loki.source.kubernetes "pods" {
  targets    = discovery.kubernetes.pods.targets
  forward_to = [loki.write.loki.receiver]
}

// ── Send logs to Loki ──
loki.write "loki" {
  endpoint {
    url = "http://loki:3100/loki/api/v1/push"
  }
}
```

**How Alloy discovers pods (same as Prometheus):**
- Talks to Kubernetes API server
- Gets list of all pods with their IPs and labels
- Filters based on annotations or namespaces
- Knows exactly which port to scrape for each pod

**How Alloy reads logs:**
- Runs as DaemonSet (one per node)
- Mounts `/var/log/pods/` from node via hostPath volume
- Watches for new log files
- Tails each file, adds K8s metadata labels
- Streams to Loki

---

### Mimir — Scalable Metrics Storage

**What it is**: A horizontally scalable metrics backend that stores data in S3. Designed as a drop-in replacement for Prometheus storage.

**How it works:**
```
Alloy → remote_write → Mimir Distributor
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
               Mimir Ingester      Mimir Ingester   ← hold recent data in memory
                    │                   │
                    └─────────┬─────────┘
                              ▼
                         Mimir Store
                              │
                              ▼
                      S3 (snappaste-mimir-blocks)
                     (permanent storage — survives anything)
```

**Querying:**
```
Grafana → PromQL query → Mimir Querier
                              │
                    ┌─────────┴──────────┐
                    ▼                    ▼
             recent data (ingesters)   old data (S3)
                    │                    │
                    └──────── merged ────┘
                                │
                             Grafana
```

**Why Mimir over Prometheus storage:**

| Scenario | Prometheus | Mimir |
|---|---|---|
| Node dies | Lose all metrics | Data safe in S3 |
| Need 1 year retention | Need huge disk | Just costs S3 storage |
| High write volume | One node bottleneck | Scale ingesters horizontally |
| Query large time range | Slow | Fast — parallel queries across S3 |

---

### Loki — Scalable Log Storage

Same idea as Mimir but for logs. Stores log chunks in S3, only indexes labels (not full text). Much cheaper than Elasticsearch because it does not index every word.

```
Query: {app="backend"} |= "ERROR"

Loki:
  1. Look up index → find chunks with label app="backend"
  2. Download only those chunks from S3
  3. Grep for "ERROR" within chunks
  4. Return matching lines
```

---

### kube-state-metrics and node-exporter

These two are still needed in the modern stack. Alloy scrapes them just like it scrapes your app pods. Nothing changes about what they do — only who scrapes them changes (Alloy instead of Prometheus).

---

## Summary — Traditional vs Modern

| | Traditional | Modern |
|---|---|---|
| **Metrics collection** | Prometheus | Grafana Alloy |
| **Log collection** | Promtail | Grafana Alloy (same agent) |
| **Metrics storage** | Prometheus local disk | Mimir → S3 |
| **Log storage** | Loki local disk or S3 | Loki → S3 |
| **Agents per node** | 2 (Prometheus + Promtail) | 1 (Alloy) |
| **Memory per node** | ~500MB | ~150MB |
| **HA for metrics** | No | Yes |
| **Survive node failure** | No (metrics lost) | Yes (S3) |
| **Config complexity** | Moderate | Moderate |
| **Visualization** | Grafana | Grafana |

---

## Our Final Stack for SnapPaste

```
Component           Helm Chart                    Namespace
─────────────────   ──────────────────────────    ──────────
Grafana Alloy       grafana/k8s-monitoring        monitoring
kube-state-metrics  (bundled in k8s-monitoring)   monitoring
node-exporter       (bundled in k8s-monitoring)   monitoring
Mimir               grafana/mimir-distributed     monitoring
Loki                grafana/loki                  monitoring
Grafana             grafana/grafana               monitoring

S3 Buckets (Terraform)
  snappaste-mimir-blocks    ← metrics
  snappaste-loki-chunks     ← logs
```
