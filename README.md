# tennisme-revproxy Docs

## Overview

Infrastructure stack for:
- Reverse proxy (SWAG / Nginx)
- IAM (Keycloak)
- Admin portal (Homepage)
- Observability (OpenObserve)
- Security (CrowdSec)

---

## Domains

- auth.elasticlabs.co
- admin.elasticlabs.co
- labs.elasticlabs.co

---

## Secret Management (IMPORTANT)

### Recommended Tool

Use KeePassXC to manage all secrets.

### Strategy

- `.env.example` → committed (no secrets)
- `.env` → local only (never commit)
- secrets stored in KeePassXC

---

## Generate Secrets

### KeePassXC
- length: 32+
- include symbols
- unique per service

### CLI

```bash
openssl rand -base64 32
```

---

## Workflow

```bash
make cp-env
# generate secrets
nano .env
make config
make up
```

---

## Security Rules

- never commit `.env`
- one secret per service
- backup KeePass database
