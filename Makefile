SHELL := /bin/bash

ifneq (,$(wildcard ./.env))
include .env
export
endif

NETWORKS := $(REVPROXY_APPS_NETWORK) $(SWAG_NETWORK)

.PHONY: help cp-env env-check docker-check networks init up down restart ps logs pull config clean

help:
	@echo ""
	@echo "Bootstrap"
	@echo "  make cp-env       -> crée .env depuis .env.example si absent"
	@echo "  make env-check    -> vérifie .env"
	@echo "  make init         -> vérifie docker + crée les réseaux"
	@echo ""
	@echo "Cycle de vie"
	@echo "  make up           -> démarre la stack"
	@echo "  make down         -> arrête la stack"
	@echo "  make restart      -> redémarre la stack"
	@echo "  make ps           -> liste les conteneurs"
	@echo "  make logs         -> suit les logs"
	@echo "  make pull         -> met à jour les images"
	@echo "  make config       -> valide la config compose"
	@echo ""
	@echo "Variables"
	@echo "  BASE_DOMAIN=$(BASE_DOMAIN)"
	@echo "  AUTH_DOMAIN=$(AUTH_DOMAIN)"
	@echo "  ADMIN_DOMAIN=$(ADMIN_DOMAIN)"
	@echo "  REVPROXY_APPS_NETWORK=$(REVPROXY_APPS_NETWORK)"
	@echo "  SWAG_NETWORK=$(SWAG_NETWORK)"
	@echo ""

cp-env:
	@[ -f .env ] || cp .env.example .env
	@echo ".env prêt."

env-check:
	@test -f .env || { echo ".env manquant. Lance: make cp-env"; exit 1; }
	@grep -q '^BASE_DOMAIN=' .env || { echo "BASE_DOMAIN manquant dans .env"; exit 1; }
	@grep -q '^AUTH_DOMAIN=' .env || { echo "AUTH_DOMAIN manquant dans .env"; exit 1; }
	@grep -q '^ADMIN_DOMAIN=' .env || { echo "ADMIN_DOMAIN manquant dans .env"; exit 1; }
	@grep -q '^REVPROXY_APPS_NETWORK=' .env || { echo "REVPROXY_APPS_NETWORK manquant dans .env"; exit 1; }
	@grep -q '^SWAG_NETWORK=' .env || { echo "SWAG_NETWORK manquant dans .env"; exit 1; }
	@grep -q '^AUTHENTIK_SECRET_KEY=' .env || { echo "AUTHENTIK_SECRET_KEY manquant dans .env"; exit 1; }
	@grep -q '^AUTHENTIK_POSTGRES_PASSWORD=' .env || { echo "AUTHENTIK_POSTGRES_PASSWORD manquant dans .env"; exit 1; }
	@grep -q '^OPENOBSERVE_ROOT_PASSWORD=' .env || { echo "OPENOBSERVE_ROOT_PASSWORD manquant dans .env"; exit 1; }
	@grep -q '^KOPIA_PASSWORD=' .env || { echo "KOPIA_PASSWORD manquant dans .env"; exit 1; }
	@grep -q '^OPENOBSERVE_IMAGE=' .env || { echo "OPENOBSERVE_IMAGE manquant dans .env"; exit 1; }
	@echo ".env OK."

docker-check:
	@command -v docker >/dev/null 2>&1 || { echo "docker absent"; exit 1; }
	@docker info >/dev/null 2>&1 || { echo "daemon docker inaccessible"; exit 1; }
	@docker compose version >/dev/null 2>&1 || { echo "plugin docker compose absent"; exit 1; }
	@echo "Docker OK."

networks: env-check
	@for net in $(NETWORKS); do \
		if ! docker network inspect $$net >/dev/null 2>&1; then \
			echo "Création réseau $$net"; \
			docker network create $$net >/dev/null; \
		else \
			echo "Réseau déjà présent: $$net"; \
		fi; \
	done

init: docker-check env-check networks
	@mkdir -p \
		swag/config/nginx/site-confs \
		swag/config/nginx/snippets \
		authentik/data/postgres \
		authentik/data/media \
		authentik/data/custom-templates \
		authentik/data/certs \
		portainer/data \
		openobserve/data \
		kopia/config \
		kopia/logs \
		kopia/cache \
		kopia/tmp \
		kopia/sources \
		kopia/repository \
		crowdsec/acquis \
		crowdsec/data \
		crowdsec/bouncers
	@touch authentik/data/.gitkeep portainer/data/.gitkeep openobserve/data/.gitkeep kopia/repository/.gitkeep crowdsec/data/.gitkeep
		@echo "Init OK."

up: init
	@docker compose up -d

down:
	@docker compose down

restart:
	@docker compose down
	@docker compose up -d

ps:
	@docker compose ps

logs:
	@docker compose logs -f --tail=200

pull:
	@docker compose pull

config: env-check
	@docker compose config

clean: down
	@echo "Stack arrêtée."