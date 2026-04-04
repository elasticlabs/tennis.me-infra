# tennisme-revproxy

Zone reverse proxy / admin / sécurité pour `elasticlabs.co`.

---

## URLs cibles

- https://auth.elasticlabs.co  → Keycloak
- https://admin.elasticlabs.co/portainer/ → Portainer
- https://admin.elasticlabs.co/observe/ → OpenObserve Enterprise

---

## Initialisation (à suivre strictement)

### 1. Cloner le dépôt

```bash
git clone <repo-url>
cd tennisme-revproxy
```

---

### 2. Préparer l’environnement

```bash
make cp-env
nano .env
```

⚠️ À modifier immédiatement :

- KEYCLOAK_DB_PASSWORD
- KEYCLOAK_ADMIN_PASSWORD
- OPENOBSERVE_ROOT_PASSWORD

---

### 3. Vérifier la configuration

```bash
make config
```

---

### 4. Initialiser l’infrastructure

```bash
make init
```

Cela va :

- vérifier Docker
- créer les réseaux :
  - revproxy_apps
  - swag_net
- créer l’arborescence nécessaire

---

### 5. Démarrer la stack

```bash
make up
```

---

### 6. Vérifier le fonctionnement

```bash
make ps
make logs
```

---

## Accès aux services

- Keycloak : https://auth.elasticlabs.co
- Portainer : https://admin.elasticlabs.co/portainer/
- OpenObserve : https://admin.elasticlabs.co/observe/

---

## Architecture

- SWAG → reverse proxy Nginx + TLS
- Keycloak → IAM / SSO
- Portainer → admin Docker
- OpenObserve Enterprise → logs / observabilité
- CrowdSec → sécurité (non exposé)

---

## Notes importantes

- aucun service n’est exposé directement sauf SWAG
- tout passe par HTTPS
- CrowdSec est administré via la console officielle
- OpenObserve Enterprise fonctionne en mode self-hosted

---

## Prochaines étapes

- config DNS (Cloudflare ou autre)
- config Google login dans Keycloak
- activer CrowdSec bouncer Nginx
- envoyer logs Nginx → OpenObserve
