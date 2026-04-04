# tennisme-revproxy

Zone reverse proxy / admin / sécurité pour `elasticlabs.co`.

---

## URLs cibles

- https://auth.elasticlabs.co
- https://admin.elasticlabs.co/portainer/
- https://admin.elasticlabs.co/observe/

---

## Initialisation (à suivre dans cet ordre)

### 1. Cloner le dépôt

```bash
git clone <repo-url>
cd tennisme-revproxy
```

### 2. Préparer le fichier `.env`

```bash
make cp-env
```

👉 Puis éditer le fichier :

```bash
nano .env
```

⚠️ **Obligatoire : changer les valeurs suivantes**

- AUTHENTIK_SECRET_KEY
- AUTHENTIK_POSTGRES_PASSWORD
- OPENOBSERVE_ROOT_PASSWORD
- RESTIC_PASSWORD

---

### 3. Vérifier la configuration

```bash
make config
```

👉 Permet de valider :
- variables d’environnement
- cohérence du `docker-compose.yml`

---

### 4. Initialiser l’environnement

```bash
make init
```

👉 Cette commande :
- vérifie Docker
- crée les réseaux Docker (`revproxy_apps`, `swag_net`)
- crée les dossiers nécessaires

---

### 5. Démarrer la stack

```bash
make up
```

---

### 6. Vérifier

```bash
make ps
make logs
```

---

## Commandes utiles

```bash
make up
make down
make restart
make logs
make ps
make pull
```

---

## Arborescence

- `swag/` : reverse proxy Nginx / certificats / snippets
- `authentik/` : IAM
- `portainer/` : admin Docker
- `openobserve/` : observabilité
- `restic/` : sauvegardes
- `crowdsec/` : sécurité

---

## Notes importantes

- `revproxy_apps` est le réseau applicatif principal.
- aucun service n’est exposé directement (hors SWAG).
- toute l’exposition passe par Nginx (SWAG).
- Authentik est accessible via `auth.elasticlabs.co`.
- Portainer et OpenObserve sont accessibles via `admin.elasticlabs.co` en sous-chemins.

---

## Prochaines étapes

- configuration DNS challenge (Cloudflare)
- intégration Authentik (forward auth)
- ajout CrowdSec (bouncer nginx + firewall)
- backups restic automatisés
