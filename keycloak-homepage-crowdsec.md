# Keycloak, Homepage & CrowdSec — Post Setup Guide

## Secret Setup

Generate and store:

- KEYCLOAK_ADMIN_PASSWORD
- KEYCLOAK_DB_PASSWORD
- OAUTH2_PROXY_CLIENT_SECRET
- OAUTH2_PROXY_COOKIE_SECRET

---

## Keycloak

- Realm: elasticlabs
- Group: infra-admins
- Admin user

---

## OIDC

Client: admin-gateway

Redirect URI:
https://admin.elasticlabs.co/oauth2/callback

Web Origin:
https://admin.elasticlabs.co

---

## Restart

```bash
make restart
```
