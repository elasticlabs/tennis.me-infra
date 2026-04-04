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
	@echo ""

cp-env:
	@[ -f .env ] || cp .env.example .env
	@echo ".env prêt."

env-check:
	@test -f .env || { echo ".env manquant. Lance: make cp-env"; exit 1; }
	@grep -q '^BASE_DOMAIN=' .env || { echo "BASE_DOMAIN manquant"; exit 1; }
	@grep -q '^AUTH_DOMAIN=' .env || { echo "AUTH_DOMAIN manquant"; exit 1; }
	@grep -q '^ADMIN_DOMAIN=' .env || { echo "ADMIN_DOMAIN manquant"; exit 1; }
	@grep -q '^KEYCLOAK_ADMIN_PASSWORD=' .env || { echo "KEYCLOAK_ADMIN_PASSWORD manquant"; exit 1; }
	@grep -q '^OPENOBSERVE_ROOT_PASSWORD=' .env || { echo "OPENOBSERVE_ROOT_PASSWORD manquant"; exit 1; }
	@echo ".env OK."

docker-check:
	@command -v docker >/dev/null 2>&1 || { echo "docker absent"; exit 1; }
	@docker info >/dev/null 2>&1 || { echo "docker daemon inaccessible"; exit 1; }
	@docker compose version >/dev/null 2>&1 || { echo "docker compose plugin absent"; exit 1; }
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
		keycloak/data/postgres \
		portainer/data \
		openobserve/data \
		crowdsec/acquis \
		crowdsec/data
	@touch keycloak/data/.gitkeep portainer/data/.gitkeep openobserve/data/.gitkeep crowdsec/data/.gitkeep
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
