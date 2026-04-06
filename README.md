# Final stack notes

This final compose reflects the current decisions:

- SWAG / Nginx as the single public entrypoint
- Keycloak + oauth2-proxy for admin SSO
- Homer as the lightweight admin landing page
- Portainer behind /portainer/
- Grafana ecosystem for observability:
  - Grafana
  - Loki
  - Prometheus
  - Alloy
  - Tempo
  - node-exporter
  - cAdvisor

Not included in this compose:
- Fail2ban: host-level service, better managed directly on Rocky Linux
- ModSecurity + OWASP CRS: intentionally left out of compose for now because this is best handled once the Nginx/WAF packaging decision is finalized

Before first run:
1. copy `.env.example` to `.env`
2. replace every `CHANGE_ME`
3. create the external network:
   docker network inspect revproxy_apps >/dev/null 2>&1 || docker network create revproxy_apps
4. run:
   make config
   make up
