SHELL := /bin/bash
.DEFAULT_GOAL := help

-include .env

COMPOSE := docker compose
WP      := ./bin/wp
WP_URL   = http://localhost:$(WP_PORT)
MAIL_URL = http://localhost:$(MAIL_PORT)

.PHONY: help up install down restart destroy fresh wp shell db-shell db-export db-import \
	    logs debug-log xdebug-on xdebug-off status

help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
	    awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

.env:
	@cp .env.example .env
	@sed -i "s/^HOST_UID=.*/HOST_UID=$$(id -u)/; s/^HOST_GID=.*/HOST_GID=$$(id -g)/" .env
	@echo "Created .env from .env.example"

up: .env ## Build and start everything, install WordPress on first run
	$(COMPOSE) up -d --build
	@echo -n "Waiting for WordPress"
	@until $(COMPOSE) exec -T wordpress test -f /var/www/html/wp-config.php 2>/dev/null; do echo -n .; sleep 1; done; echo
	@$(MAKE) --no-print-directory install
	@$(MAKE) --no-print-directory status

install: ## Install WordPress if not installed yet (idempotent)
	@$(COMPOSE) --progress quiet --profile tools run --rm --no-deps -T --entrypoint sh cli /usr/local/bin/wp-setup.sh

down: ## Stop containers (data is kept)
	$(COMPOSE) --profile tools down

restart: down up ## Stop then start

destroy: ## Remove containers, volumes and built images (FORCE=1 skips the prompt)
	@if [ "$(FORCE)" != "1" ]; then \
	    read -p "Delete the database and WordPress volume for '$(COMPOSE_PROJECT_NAME)'? [y/N] " ans; \
	    [ "$$ans" = "y" ] || [ "$$ans" = "Y" ] || { echo "Aborted."; exit 1; }; \
	fi
	$(COMPOSE) --profile tools down -v --remove-orphans --rmi local

fresh: ## Destroy and rebuild from scratch
	@$(MAKE) --no-print-directory destroy FORCE=1
	@$(MAKE) --no-print-directory up

wp: ## Run WP-CLI: make wp ARGS="plugin list"
	@$(WP) $(ARGS)

shell: ## Bash shell in the WordPress container
	$(COMPOSE) exec wordpress bash

db-shell: ## MariaDB client
	$(COMPOSE) exec db mariadb -u$(DB_USER) -p$(DB_PASSWORD) $(DB_NAME)

db-export: ## Dump the database to backups/<timestamp>.sql
	@$(WP) db export /backups/$(COMPOSE_PROJECT_NAME)-$$(date +%Y%m%d-%H%M%S).sql

db-import: ## Import a dump: make db-import FILE=backups/x.sql [OLD_URL=https://example.com]
	@[ -n "$(FILE)" ] || { echo "Usage: make db-import FILE=backups/x.sql [OLD_URL=...]"; exit 1; }
	@[ "$(dir $(FILE))" = "backups/" ] || { echo "FILE must be inside backups/"; exit 1; }
	@$(WP) db import /backups/$(notdir $(FILE))
	@if [ -n "$(OLD_URL)" ]; then $(WP) search-replace "$(OLD_URL)" "$(WP_URL)" --all-tables --skip-columns=guid; fi
	@$(WP) cache flush

logs: ## Follow logs (S=wordpress to pick one service)
	$(COMPOSE) logs -f $(S)

debug-log: ## Follow wp-content/debug.log
	$(COMPOSE) exec wordpress sh -c 'touch wp-content/debug.log && tail -f wp-content/debug.log'

xdebug-on: ## Restart WordPress with Xdebug step debugging on
	XDEBUG_MODE=debug $(COMPOSE) up -d wordpress
	@echo "Xdebug on (port 9003). Run 'make xdebug-off' when done."

xdebug-off: ## Restart WordPress with Xdebug off
	XDEBUG_MODE=off $(COMPOSE) up -d wordpress

status: ## Show containers and URLs
	@$(COMPOSE) ps
	@echo
	@echo "  Site:    $(WP_URL)"
	@echo "  Admin:   $(WP_URL)/wp-admin  ($(WP_ADMIN_USER) / $(WP_ADMIN_PASSWORD))"
	@echo "  Mailpit: $(MAIL_URL)"
