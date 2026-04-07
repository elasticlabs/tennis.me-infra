SHELL := /bin/bash

ifneq (,$(wildcard ./.env))
include .env
export
endif

AUTH_DOMAIN ?= auth.$(BASE_DOMAIN)
ADMIN_DOMAIN ?= admin.$(BASE_DOMAIN)
LABS_DOMAIN ?= labs.$(BASE_DOMAIN)

NETWORKS := $(REVPROXY_APPS_NETWORK) $(SWAG_NETWORK)

.PHONY: help cp-env env-check docker-check networks init up down restart ps logs pull build config clean secrets-bootstrap

help:
	@echo ""
	@echo "Bootstrap"
	@echo "  make cp-env            -> create .env from .env.example if missing"
	@echo "  make env-check         -> validate .env"
	@echo "  make secrets-bootstrap -> generate secrets in ./.tmp/secrets.md if CHANGE_ME exists in .env"
	@echo "  make init              -> validate docker + create networks + directories"
	@echo ""
	@echo "Lifecycle"
	@echo "  make build             -> build local images"
	@echo "  make up                -> start the stack"
	@echo "  make down              -> stop the stack"
	@echo "  make restart           -> restart the stack"
	@echo "  make ps                -> list containers"
	@echo "  make logs              -> follow logs"
	@echo "  make pull              -> pull base images"
	@echo "  make config            -> validate compose config"
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

secrets-bootstrap:
	@test -f .env || { echo ".env missing. Run: make cp-env"; exit 1; }
	@if grep -Eqi 'changeme|change_me|change-me' .env; then \
		mkdir -p .tmp; \
		DB_PASS="$$(openssl rand -base64 24)"; \
		KC_ADMIN_PASS="$$(openssl rand -base64 24)"; \
		OAUTH_CLIENT_SECRET="$$(openssl rand -base64 32)"; \
		OAUTH_COOKIE_SECRET="$$(openssl rand -base64 32)"; \
		GRAFANA_ADMIN_PASS="$$(openssl rand -base64 24)"; \
		{ \
			printf '%s\n' '# tennisme-revproxy bootstrap secrets'; \
			printf '\n'; \
			printf '%s\n' '## KeepassXC entries to create'; \
			printf '\n'; \
			printf '%s\n' '### keycloak-db'; \
			printf '%s\n' '- username: $(KEYCLOAK_DB_USER)'; \
			printf '%s\n' "- password: $$DB_PASS"; \
			printf '\n'; \
			printf '%s\n' '### keycloak-admin'; \
			printf '%s\n' '- username: $(KEYCLOAK_ADMIN_USER)'; \
			printf '%s\n' "- password: $$KC_ADMIN_PASS"; \
			printf '\n'; \
			printf '%s\n' '### oauth2-proxy-client'; \
			printf '%s\n' '- username: $(OAUTH2_PROXY_CLIENT_ID)'; \
			printf '%s\n' "- password: $$OAUTH_CLIENT_SECRET"; \
			printf '\n'; \
			printf '%s\n' '### oauth2-proxy-cookie'; \
			printf '%s\n' '- username: cookie-secret'; \
			printf '%s\n' "- password: $$OAUTH_COOKIE_SECRET"; \
			printf '\n'; \
			printf '%s\n' '### grafana-admin'; \
			printf '%s\n' '- username: $(GRAFANA_ADMIN_USER)'; \
			printf '%s\n' "- password: $$GRAFANA_ADMIN_PASS"; \
			printf '\n'; \
			printf '%s\n' '## Suggested .env values'; \
			printf '\n'; \
			printf '%s\n' "KEYCLOAK_DB_PASSWORD=$$DB_PASS"; \
			printf '%s\n' "KEYCLOAK_ADMIN_PASSWORD=$$KC_ADMIN_PASS"; \
			printf '%s\n' "OAUTH2_PROXY_CLIENT_SECRET=$$OAUTH_CLIENT_SECRET"; \
			printf '%s\n' "OAUTH2_PROXY_COOKIE_SECRET=$$OAUTH_COOKIE_SECRET"; \
			printf '%s\n' "GRAFANA_ADMIN_PASSWORD=$$GRAFANA_ADMIN_PASS"; \
		} > .tmp/secrets.bootstrap.md; \
		echo ""; \
		echo "Bootstrap secrets written to .tmp/secrets.bootstrap.md"; \
		echo "Copy them into KeePassXC, then into .env"; \
	else \
		echo "No CHANGE_ME occurrence found in .env. Secrets bootstrap skipped."; \
	fi

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
		.tmp \
		swag/config/nginx/site-confs \
		swag/config/nginx/snippets \
		homer/assets \
		grafana/grafana/provisioning/datasources \
		grafana/grafana/provisioning/dashboards \
		grafana/grafana/provisioning/alerting \
		grafana/loki/config \
		grafana/prometheus/config \
		grafana/alloy/config \
		grafana/tempo/config \
		filebrowser
	@touch \
		grafana/loki/config/loki-config.yml \
		grafana/prometheus/config/prometheus.yml \
		grafana/alloy/config/config.alloy \
		grafana/tempo/config/tempo.yaml \
		grafana/grafana/provisioning/datasources/datasources.yml \
		grafana/grafana/provisioning/dashboards/dashboard-provider.yml \
		grafana/grafana/provisioning/alerting/alerts.yml
	@echo "Init OK."

build: init
	@docker compose build

up: init
	@docker compose up -d
	@echo ""
	@echo "Available URLs"
	@echo "  Auth        : https://$(AUTH_DOMAIN)"
	@echo "  Admin       : https://$(ADMIN_DOMAIN)/"
	@echo "  Portainer   : https://$(ADMIN_DOMAIN)/portainer/"
	@echo "  Grafana     : https://$(ADMIN_DOMAIN)/grafana/"
	@echo "  cAdvisor    : https://$(ADMIN_DOMAIN)/cadvisor/"
	@echo "  Files       : https://$(ADMIN_DOMAIN)/files/"
	@echo "  Labs        : https://$(LABS_DOMAIN)/"

down:
	@docker compose down

restart:
	@docker compose down
	@docker compose up -d
	@echo ""
	@echo "Available URLs"
	@echo "  Auth        : https://$(AUTH_DOMAIN)"
	@echo "  Admin       : https://$(ADMIN_DOMAIN)/"
	@echo "  Portainer   : https://$(ADMIN_DOMAIN)/portainer/"
	@echo "  Grafana     : https://$(ADMIN_DOMAIN)/grafana/"
	@echo "  cAdvisor    : https://$(ADMIN_DOMAIN)/cadvisor/"
	@echo "  Files       : https://$(ADMIN_DOMAIN)/files/"
	@echo "  Labs        : https://$(LABS_DOMAIN)/"

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
