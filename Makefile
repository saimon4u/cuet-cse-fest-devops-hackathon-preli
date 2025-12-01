.DEFAULT_GOAL := help
.PHONY: help up down build logs restart shell ps dev-up dev-down dev-build dev-logs dev-restart dev-shell dev-ps prod-up prod-down prod-build prod-logs prod-restart backend-shell gateway-shell mongo-shell backend-build backend-install backend-type-check backend-dev db-reset db-backup clean clean-all clean-volumes status health

MODE ?= dev
SERVICE ?= backend
COMPOSE_FILE_DEV = docker/compose.development.yaml
COMPOSE_FILE_PROD = docker/compose.production.yaml
COMPOSE_CMD = docker compose
ARGS ?=

ifeq ($(MODE),prod)
	COMPOSE_FILE = $(COMPOSE_FILE_PROD)
else
	COMPOSE_FILE = $(COMPOSE_FILE_DEV)
endif

help:
	@echo "MERN DevOps Makefile"
	@echo ""
	@echo "Usage: make [target] [MODE=dev|prod] [SERVICE=service_name] [ARGS=\"additional_args\"]"
	@echo ""
	@echo "Docker Services:"
	@echo "  make up                    - Start services (development)"
	@echo "  make up MODE=prod          - Start services (production)"
	@echo "  make up ARGS=\"--build\"     - Start with rebuild"
	@echo "  make down                  - Stop services"
	@echo "  make down ARGS=\"-v\"        - Stop and remove volumes"
	@echo "  make build                 - Build containers"
	@echo "  make logs                  - View all logs"
	@echo "  make logs SERVICE=backend  - View backend logs"
	@echo "  make restart               - Restart services"
	@echo "  make shell                 - Open shell in backend (default)"
	@echo "  make shell SERVICE=gateway - Open shell in gateway"
	@echo "  make ps                    - Show running containers"
	@echo ""
	@echo "Development Aliases:"
	@echo "  make dev-up                - Start development environment"
	@echo "  make dev-down              - Stop development environment"
	@echo "  make dev-build             - Build development containers"
	@echo "  make dev-logs              - View development logs"
	@echo "  make dev-restart           - Restart development services"
	@echo "  make dev-shell             - Open shell in backend container"
	@echo "  make backend-shell         - Open shell in backend container"
	@echo "  make gateway-shell         - Open shell in gateway container"
	@echo "  make mongo-shell           - Open MongoDB shell"
	@echo ""
	@echo "Production Aliases:"
	@echo "  make prod-up               - Start production environment"
	@echo "  make prod-down             - Stop production environment"
	@echo "  make prod-build            - Build production containers"
	@echo "  make prod-logs             - View production logs"
	@echo "  make prod-restart          - Restart production services"
	@echo ""
	@echo "Backend Commands:"
	@echo "  make backend-build         - Build backend TypeScript"
	@echo "  make backend-install       - Install backend dependencies"
	@echo "  make backend-type-check    - Type check backend code"
	@echo "  make backend-dev           - Run backend locally (not Docker)"
	@echo ""
	@echo "Database:"
	@echo "  make db-reset              - Reset MongoDB (WARNING: deletes data)"
	@echo "  make db-backup             - Backup MongoDB database"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean                 - Remove containers and networks"
	@echo "  make clean-all             - Remove everything including images"
	@echo "  make clean-volumes         - Remove all volumes"
	@echo ""
	@echo "Utilities:"
	@echo "  make status                - Show container status"
	@echo "  make health                - Check service health"

up:
	$(COMPOSE_CMD) -f $(COMPOSE_FILE) --env-file .env up -d $(ARGS)

down:
	$(COMPOSE_CMD) -f $(COMPOSE_FILE) --env-file .env down $(ARGS)

build:
	$(COMPOSE_CMD) -f $(COMPOSE_FILE) --env-file .env build $(ARGS)

logs:
	@if [ -z "$(SERVICE)" ] || [ "$(SERVICE)" = "backend" ]; then \
		$(COMPOSE_CMD) -f $(COMPOSE_FILE) --env-file .env logs -f; \
	else \
		$(COMPOSE_CMD) -f $(COMPOSE_FILE) --env-file .env logs -f $(SERVICE); \
	fi

restart:
	$(COMPOSE_CMD) -f $(COMPOSE_FILE) --env-file .env restart $(ARGS)

shell:
	$(COMPOSE_CMD) -f $(COMPOSE_FILE) --env-file .env exec $(SERVICE) sh

ps:
	$(COMPOSE_CMD) -f $(COMPOSE_FILE) --env-file .env ps

dev-up:
	@$(MAKE) up MODE=dev ARGS="$(ARGS)"

dev-down:
	@$(MAKE) down MODE=dev ARGS="$(ARGS)"

dev-build:
	@$(MAKE) build MODE=dev ARGS="$(ARGS)"

dev-logs:
	@$(MAKE) logs MODE=dev

dev-restart:
	@$(MAKE) restart MODE=dev

dev-shell:
	@$(MAKE) shell MODE=dev SERVICE=backend

dev-ps:
	@$(MAKE) ps MODE=dev

backend-shell:
	@$(MAKE) shell MODE=dev SERVICE=backend

gateway-shell:
	@$(MAKE) shell MODE=dev SERVICE=gateway

mongo-shell:
	$(COMPOSE_CMD) -f $(COMPOSE_FILE_DEV) --env-file .env exec mongodb mongosh -u $$MONGO_INITDB_ROOT_USERNAME -p $$MONGO_INITDB_ROOT_PASSWORD --authenticationDatabase admin

prod-up:
	@$(MAKE) up MODE=prod ARGS="$(ARGS)"

prod-down:
	@$(MAKE) down MODE=prod ARGS="$(ARGS)"

prod-build:
	@$(MAKE) build MODE=prod ARGS="$(ARGS)"

prod-logs:
	@$(MAKE) logs MODE=prod

prod-restart:
	@$(MAKE) restart MODE=prod

backend-build:
	cd backend && npm run build

backend-install:
	cd backend && npm install

backend-type-check:
	cd backend && npm run type-check

backend-dev:
	cd backend && npm run dev

db-reset:
	@echo "WARNING: This will delete all data in MongoDB!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(COMPOSE_CMD) -f $(COMPOSE_FILE_DEV) --env-file .env down -v; \
		$(COMPOSE_CMD) -f $(COMPOSE_FILE_DEV) --env-file .env up -d; \
		echo "Database reset complete"; \
	else \
		echo "Database reset cancelled"; \
	fi

db-backup:
	@mkdir -p backups
	@TIMESTAMP=$$(date +%Y%m%d_%H%M%S); \
	docker exec mongodb-devopsss mongodump --authenticationDatabase admin \
		-u $$MONGO_INITDB_ROOT_USERNAME -p $$MONGO_INITDB_ROOT_PASSWORD \
		--out=/tmp/backup_$$TIMESTAMP; \
	docker cp mongodb-devopsss:/tmp/backup_$$TIMESTAMP ./backups/; \
	echo "Backup saved to ./backups/backup_$$TIMESTAMP"

clean:
	$(COMPOSE_CMD) -f $(COMPOSE_FILE_DEV) --env-file .env down
	$(COMPOSE_CMD) -f $(COMPOSE_FILE_PROD) --env-file .env down
	docker network prune -f

clean-all:
	$(COMPOSE_CMD) -f $(COMPOSE_FILE_DEV) --env-file .env down --rmi all -v
	$(COMPOSE_CMD) -f $(COMPOSE_FILE_PROD) --env-file .env down --rmi all -v
	docker network prune -f

clean-volumes:
	@echo "WARNING: This will delete all Docker volumes!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(COMPOSE_CMD) -f $(COMPOSE_FILE_DEV) --env-file .env down -v; \
		$(COMPOSE_CMD) -f $(COMPOSE_FILE_PROD) --env-file .env down -v; \
		echo "Volumes removed"; \
	else \
		echo "Volume removal cancelled"; \
	fi

status:
	@$(MAKE) ps MODE=$(MODE)

health:
	@echo "=== Development Services ==="
	@$(COMPOSE_CMD) -f $(COMPOSE_FILE_DEV) --env-file .env ps
	@echo ""
	@echo "=== Production Services ==="
	@$(COMPOSE_CMD) -f $(COMPOSE_FILE_PROD) --env-file .env ps