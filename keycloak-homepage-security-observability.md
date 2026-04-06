# Keycloak, Homepage, Security & Observability - Post Setup Guide

## Goal

After `make up`, complete the functional setup of:

- Keycloak for IAM / SSO
- Homepage for the admin portal
- oauth2-proxy for protected admin access
- Grafana for dashboards and unified supervision
- Loki, Alloy, and Tempo for logs, metrics, and traces
- Fail2ban + ModSecurity / OWASP CRS for security

---

## 1. Secret Setup

Before configuring Keycloak or oauth2-proxy:

1. generate strong secrets in KeePassXC
2. store them in a local KeePass database
3. copy them into `.env`

Required secrets:

- `KEYCLOAK_ADMIN_PASSWORD`
- `KEYCLOAK_DB_PASSWORD`
- `OAUTH2_PROXY_CLIENT_SECRET`
- `OAUTH2_PROXY_COOKIE_SECRET`

Optional future secrets:

- SMTP credentials
- Google Identity Provider credentials
- lab-specific database passwords

---

## 2. Keycloak Minimal Setup

### 2.1 Login

Open:

`https://auth.elasticlabs.co`

Login with the bootstrap admin defined in `.env`.

### 2.2 Create realm

Create a realm named:

`elasticlabs`

### 2.3 Create group

Create the group:

`infra-admins`

### 2.4 Create a named admin user

Create a personal admin user and assign it to `infra-admins`.

Avoid using the bootstrap account for daily work.

---

## 3. OIDC Client for oauth2-proxy

Create the OIDC client used by the admin gateway.

### Required values

- **Client ID**: `admin-gateway`
- **Protocol**: OpenID Connect
- **Client authentication**: enabled
- **Standard flow**: enabled

### Redirect URI

```text
https://admin.elasticlabs.co/oauth2/callback
```

### Web origin

```text
https://admin.elasticlabs.co
```

### Home URL

```text
https://admin.elasticlabs.co
```

### Client secret

Once created, copy the client secret to `.env`:

```env
OAUTH2_PROXY_CLIENT_SECRET=replace-me
```

### Cookie secret

Generate a 32-byte base64 value and store it in `.env`:

```bash
python3 - <<'PY'
import secrets, base64
print(base64.urlsafe_b64encode(secrets.token_bytes(32)).decode())
PY
```

Then set:

```env
OAUTH2_PROXY_COOKIE_SECRET=replace-me
```

---

## 4. Restart and Validate SSO

After updating `.env`:

```bash
make config
make restart
docker compose logs -f oauth2-proxy
```

Expected result:

- no OIDC provider error
- no client secret error
- admin portal redirects to Keycloak
- successful login returns to Homepage

Test URL:

`https://admin.elasticlabs.co`

---

## 5. Homepage Role

Homepage is the human-facing admin entrypoint.

Recommended root links:

- Keycloak
- Portainer
- Grafana
- documentation
- future internal tools

Keycloak remains the identity authority; Homepage remains the portal.

---

## 6. Observability Setup

### 6.1 Recommended components

- **Grafana** -> dashboards / Explore / alerting
- **Loki** -> logs
- **Alloy** -> collector and routing layer
- **Tempo** -> traces / APM
- **Prometheus-compatible metrics backend** -> metrics

Grafana Alloy provides native pipelines for OpenTelemetry, Prometheus, Loki, and other telemetry tools, making it a strong fit as the single collection agent for this platform. Tempo is Grafana’s tracing backend and supports connecting traces with logs and metrics. citeturn521441search12turn521441search2turn521441search14

### 6.2 What Grafana should supervise

Grafana should become the single dashboard plane for:

- SWAG / Nginx access and error logs
- ModSecurity events
- Fail2ban actions
- Keycloak logs and metrics
- oauth2-proxy logs
- Portainer logs / metrics when available
- host and Docker metrics
- lab services logs / metrics / traces
- future backend API latency and traces

### 6.3 Log ingestion targets

Use Alloy to collect and push logs into Loki for:

- Nginx access logs
- Nginx error logs
- ModSecurity audit / error logs
- Fail2ban logs
- Docker container logs
- host logs

Grafana documents Alloy as the collector layer and Loki as the log backend for this kind of pipeline. citeturn521441search4turn521441search5

### 6.4 Tracing / APM

Tempo should be used for tracing as soon as your backend services emit traces.

Recommended next step once the backend exists:

- instrument APIs with OpenTelemetry
- send traces through Alloy
- store traces in Tempo
- visualize traces and service relationships in Grafana

Grafana documents Tempo as a distributed tracing backend and recommends instrumentation plus collector setup as the tracing pipeline. citeturn521441search2turn521441search10turn521441search18

---

## 7. Security Baseline

### 7.1 Fail2ban

Use Fail2ban for:

- SSH protection
- Nginx log-based bans for obvious abusive patterns

### 7.2 ModSecurity + OWASP CRS

Use ModSecurity as the WAF engine and OWASP CRS as the rule set.

This gives a more integrated Nginx-centric security posture than CrowdSec for this stack. OWASP states that ModSecurity supports Nginx, and CRS is the rule set intended for ModSecurity-compatible WAFs. citeturn521441search15turn521441search3turn521441search7

### 7.3 Security logging

Security-relevant events should be visible in Grafana through Loki:

- ModSecurity hits
- WAF anomalies
- Fail2ban ban / unban events
- authentication failures
- suspicious admin access patterns

---

## 8. Suggested Implementation Order

1. finish Keycloak realm and client setup
2. validate oauth2-proxy login flow
3. make Homepage the root admin portal
4. add Grafana to the admin zone
5. wire Alloy -> Loki
6. add host / Docker / Keycloak metrics
7. add Tempo
8. enable ModSecurity + CRS in front of public routes
9. tune Fail2ban jails
10. build Grafana dashboards for the whole stack

---

## 9. Adding a New Admin Service

For every new admin-facing service:

1. add the service to `docker-compose.yml`
2. connect it to `revproxy_apps`
3. explicitly declare the internal port with `expose`
4. add a route in the admin Nginx config
5. add a Homepage entry
6. decide whether service-native auth stays enabled
7. add log / metric collection to Alloy
8. add a Grafana panel if the service matters operationally

### Compose template

```yaml
my-admin-service:
  image: image/example:latest
  container_name: my-admin-service
  restart: unless-stopped
  expose:
    - "3000"
  networks:
    - revproxy_apps
```

### Nginx template

```nginx
location /my-admin-service/ {
    proxy_pass http://my-admin-service:3000/;
    include /config/nginx/snippets/proxy-common.conf;
}
```

### Homepage template

```yaml
- My Admin Service:
    href: https://admin.elasticlabs.co/my-admin-service/
    description: Short description
```

---

## 10. TL;DR

This post-setup baseline now is:

- Keycloak for identity
- oauth2-proxy for admin SSO
- Homepage for the portal
- Grafana ecosystem for observability
- Fail2ban + ModSecurity / CRS for security
- Grafana as the unified supervision UI for the whole platform
