SHELL := /bin/bash

ifneq (,$(wildcard ./.env))
include .env
export
endif

AUTH_DOMAIN ?= auth.$(BASE_DOMAIN)
ADMIN_DOMAIN ?= admin.$(BASE_DOMAIN)
LABS_DOMAIN ?= labs.$(BASE_DOMAIN)

NETWORKS := $(REVPROXY_APPS_NETWORK) $(SWAG_NETWORK)

.PHONY: help cp-env env-check docker-check networks init up down restart ps logs pull config clean

help:
	@echo ""
	@echo "Bootstrap"
	@echo "  make cp-env       -> create .env from .env.example if missing"
	@echo "  make env-check    -> validate .env"
	@echo "  make init         -> validate docker + create networks + directories"
	@echo ""
	@echo "Lifecycle"
	@echo "  make up           -> start the stack"
	@echo "  make down         -> stop the stack"
	@echo "  make restart      -> restart the stack"
	@echo "  make ps           -> list containers"
	@echo "  make logs         -> follow logs"
	@echo "  make pull         -> pull images"
	@echo "  make config       -> validate compose config"
	@echo ""
	@echo "Derived domains"
	@echo "  AUTH_DOMAIN=$(AUTH_DOMAIN)"
	@echo "  ADMIN_DOMAIN=$(ADMIN_DOMAIN)"
	@echo "  LABS_DOMAIN=$(LABS_DOMAIN)"
	@echo ""

cp-env:
	@[ -f .env ] || cp .env.example .env
	@echo ".env ready."

env-check:
	@test -f .env || { echo ".env missing. Run: make cp-env"; exit 1; }
	@grep -q '^BASE_DOMAIN=' .env || { echo "BASE_DOMAIN missing"; exit 1; }
	@grep -q '^ADMIN_EMAIL=' .env || { echo "ADMIN_EMAIL missing"; exit 1; }
	@grep -q '^REVPROXY_APPS_NETWORK=' .env || { echo "REVPROXY_APPS_NETWORK missing"; exit 1; }
	@grep -q '^SWAG_NETWORK=' .env || { echo "SWAG_NETWORK missing"; exit 1; }
	@grep -q '^KEYCLOAK_DB_PASSWORD=' .env || { echo "KEYCLOAK_DB_PASSWORD missing"; exit 1; }
	@grep -q '^KEYCLOAK_ADMIN_PASSWORD=' .env || { echo "KEYCLOAK_ADMIN_PASSWORD missing"; exit 1; }
	@grep -q '^OAUTH2_PROXY_CLIENT_SECRET=' .env || { echo "OAUTH2_PROXY_CLIENT_SECRET missing"; exit 1; }
	@grep -q '^OAUTH2_PROXY_COOKIE_SECRET=' .env || { echo "OAUTH2_PROXY_COOKIE_SECRET missing"; exit 1; }
	@grep -q '^GRAFANA_ADMIN_USER=' .env || { echo "GRAFANA_ADMIN_USER missing"; exit 1; }
	@grep -q '^GRAFANA_ADMIN_PASSWORD=' .env || { echo "GRAFANA_ADMIN_PASSWORD missing"; exit 1; }
	@echo ".env OK."

docker-check:
	@command -v docker >/dev/null 2>&1 || { echo "docker missing"; exit 1; }
	@docker info >/dev/null 2>&1 || { echo "docker daemon unavailable"; exit 1; }
	@docker compose version >/dev/null 2>&1 || { echo "docker compose plugin missing"; exit 1; }
	@echo "Docker OK."

networks: env-check
	@for net in $(NETWORKS); do \
		if ! docker network inspect $$net >/dev/null 2>&1; then \
			echo "Creating network $$net"; \
			docker network create $$net >/dev/null; \
		else \
			echo "Network already exists: $$net"; \
		fi; \
	done

init: docker-check env-check networks
	@mkdir -p \
		swag/config/nginx/site-confs \
		swag/config/nginx/snippets \
		keycloak/data/postgres \
		homer/assets \
		portainer/data \
		grafana/data \
		grafana/provisioning/datasources \
		grafana/provisioning/dashboards \
		grafana/provisioning/alerting \
		loki/config \
		loki/data \
		prometheus/config \
		prometheus/data \
		alloy/config \
		tempo/config \
		tempo/data \
		node-exporter/textfile
	@touch keycloak/data/.gitkeep portainer/data/.gitkeep grafana/data/.gitkeep loki/data/.gitkeep prometheus/data/.gitkeep tempo/data/.gitkeep
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
	@echo "Stack stopped."
