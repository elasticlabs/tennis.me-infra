# Adding a Client / Lab Service on `labs.elasticlabs.co`

## Goal

Standardize how demo platforms and training stacks are added under:

`labs.elasticlabs.co`

This domain is used for:

- training environments
- teaching demos
- student-facing platforms
- technical workshops
- presentation stacks

---

## 1. Domain Role

Keep responsibilities separated:

- `auth.elasticlabs.co` -> IAM / SSO
- `admin.elasticlabs.co` -> internal administration
- `labs.elasticlabs.co` -> demos, labs, workshops, student-facing stacks

---

## 2. URL Strategy

### Default strategy

Prefer subpaths first:

- `https://labs.elasticlabs.co/flutter-workshop/`
- `https://labs.elasticlabs.co/supabase-demo/`
- `https://labs.elasticlabs.co/ml-playground/`

### Fallback strategy

If the application does not support subpaths correctly, switch to a dedicated subdomain:

- `flutter-workshop.elasticlabs.co`
- `supabase-demo.elasticlabs.co`

---

## 3. Standard Add-Service Pattern

For each new lab service:

1. add the service to `docker-compose.yml`
2. connect it to `revproxy_apps`
3. explicitly declare the internal port with `expose`
4. add the route in the labs Nginx config
5. test subpath compatibility
6. switch to dedicated subdomain if needed
7. document the service
8. add observability collection in Alloy
9. add a Grafana dashboard or panels if operational visibility matters

---

## 4. Secret Management

If the lab service needs credentials:

- generate them in KeePassXC
- store them in the KeePass database
- inject them through `.env`
- never hardcode them into compose files

### Example

```yaml
environment:
  DB_PASSWORD: ${MY_SERVICE_DB_PASSWORD}
```

---

## 5. Compose Template

### Image-based service

```yaml
my-lab-service:
  image: image/example:latest
  container_name: my-lab-service
  restart: unless-stopped
  expose:
    - "3000"
  networks:
    - revproxy_apps
```

### Build-based service

```yaml
my-lab-service:
  build:
    context: ./labs/my-lab-service
  container_name: my-lab-service
  restart: unless-stopped
  expose:
    - "3000"
  networks:
    - revproxy_apps
```

---

## 6. Nginx Template

Suggested config file:

`swag/config/nginx/site-confs/labs.subfolder.conf`

```nginx
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name labs.*;

    include /config/nginx/ssl.conf;
    include /config/nginx/snippets/security-headers.conf;

    location = / {
        return 200 'labs.elasticlabs.co online';
        add_header Content-Type text/plain;
    }

    location /my-lab-service/ {
        proxy_pass http://my-lab-service:3000/;
        include /config/nginx/snippets/proxy-common.conf;
    }
}
```

---

## 7. Optional Protection

Choose one of these modes per lab:

- **public** -> no authentication
- **semi-private** -> lightweight gate if needed
- **private** -> protect with Keycloak + oauth2-proxy

### Recommended naming if labs gets SSO later

- `admin-gateway` for `admin.elasticlabs.co`
- `labs-gateway` for `labs.elasticlabs.co`

---

## 8. Observability for Labs

All lab services should be observable through the same Grafana ecosystem.

### Minimum recommended telemetry

- container logs -> Alloy -> Loki
- service metrics -> Alloy -> metrics backend
- traces when applicable -> Alloy -> Tempo

### Why

Grafana should remain the single place to inspect:

- demo service availability
- error rates
- logs during student sessions
- backend latency
- workshop incidents

Grafana Alloy supports log, metric, and trace pipelines, and Loki and Tempo are the storage backends used in this stack. citeturn521441search0turn521441search1turn521441search2

---

## 9. Documentation Template for Each Lab

```md
# Service Name

## Purpose
Short description.

## URL
https://labs.elasticlabs.co/my-lab-service/

## Access
Public | Semi-private | Private

## Compose service name
my-lab-service

## Internal port
3000

## Dependencies
Database / API / none

## Secrets
List required `.env` variables

## Observability
Logs | Metrics | Traces

## Notes
Known limitations or caveats
```

---

## 10. TL;DR

For `labs.elasticlabs.co`:

- prefer subpaths first
- use dedicated subdomains only when necessary
- keep secrets in KeePassXC + `.env`
- wire each service into Alloy / Grafana
- document every service consistently
