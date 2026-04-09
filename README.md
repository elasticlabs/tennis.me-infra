# 🔐 Observability & Platform Stack (Docker Compose)

This stack provides a **self-hosted platform** combining:

* Reverse proxy & TLS
* Authentication (SSO)
* Container management
* Full observability (metrics, logs, traces)
* File access to persistent data

Designed for **homelab / small infra / dev platforms**.

---

## 🧱 Stack Overview

### 🌐 Access & Security

* **SWAG (Nginx + Let's Encrypt)** → reverse proxy, HTTPS, routing
* **Keycloak** → identity provider (OIDC / SSO)
* **OAuth2 Proxy** → protects services behind authentication

---

### 🖥️ Platform & Tools

* **Homer** → dashboard / homepage
* **Portainer** → Docker management UI
* **Filebrowser** → access volumes & persistent data

---

### 📊 Observability (LGTM Stack)

* **Prometheus** → metrics collection
* **Node Exporter** → host metrics
* **cAdvisor** → container metrics
* **Loki** → logs aggregation
* **Alloy (Grafana Agent)** → logs + metrics shipping
* **Tempo** → distributed tracing
* **Grafana** → visualization (metrics, logs, traces)
* **Alertmanager** → alerting system

---

## 🔗 How It Works

```text
                ┌──────────────┐
                │     SWAG     │
                │ (Reverse Proxy)
                └──────┬───────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
   ┌────▼────┐                 ┌──────▼──────┐
   │ Keycloak│                 │ OAuth2 Proxy│
   └────┬────┘                 └──────┬──────┘
        │                             │
        └──────────────┬──────────────┘
                       │
         ┌─────────────▼─────────────┐
         │   Internal Services       │
         │ (Grafana, Portainer, etc) │
         └─────────────┬─────────────┘
                       │
      ┌────────────────┴────────────────┐
      │                                 │
 ┌────▼────┐  ┌──────────┐  ┌───────────▼──────┐
 │Prometheus│ │   Loki   │  │      Tempo       │
 └────┬────┘  └────┬─────┘  └───────────┬──────┘
      │            │                    │
 ┌────▼────┐  ┌────▼────┐        ┌──────▼─────┐
 │Node Exp.│  │ cAdvisor│        │   Alloy    │
 └─────────┘  └─────────┘        └────────────┘
```

---

## 🔐 Authentication Flow

1. User accesses a protected service
2. SWAG routes traffic
3. OAuth2 Proxy checks authentication
4. Redirects to Keycloak if needed
5. User logs in via Keycloak
6. Access is granted to the service

---

## 📊 Observability Flow

* Exporters (Node Exporter, cAdvisor) expose metrics
* Prometheus scrapes and stores them
* Alloy collects logs & forwards to Loki
* Tempo stores traces
* Grafana queries everything

---

## 💾 Data Persistence

Volumes are used for:

* Databases (PostgreSQL / Keycloak)
* Metrics (Prometheus)
* Logs (Loki)
* Traces (Tempo)
* Dashboards (Grafana)
* App data (Portainer, Filebrowser)

---

## ⚙️ Networking

Two external Docker networks:

* `swag_net` → public entrypoint
* `revproxy_apps` → internal communication

---

## 🧹 Logging Strategy

All services use:

```yaml
driver: local
max-size: "10m"
max-file: "3"
```

➡️ Prevents Docker logs from growing indefinitely.

---

## 🚀 Usage

```bash
docker compose up -d
```

---

## ✅ Key Features

* 🔒 Secure by default (TLS + SSO)
* 📊 Full observability (metrics + logs + traces)
* 🧩 Modular & extensible
* 🐳 Fully containerized
* 🧰 Self-hosted platform ready

---

## 🧠 Summary

This stack turns Docker into a **mini platform**:

* Access layer → SWAG + OAuth2 + Keycloak
* Services → Grafana, Portainer, Homer
* Observability → Prometheus + Loki + Tempo
* Data → persistent volumes + Filebrowser

---

Perfect for **DevOps, homelab, and small production setups**.
