API_DIR   := apps/api
POS_DIR   := apps/pos
COMPOSE   := docker compose -f infra/docker/compose.yml

DATABASE_URL ?= postgres://postgres:postgres@localhost:5432/billiards?sslmode=disable
MIGRATIONS_DIR := $(API_DIR)/db/migrations
SEEDS_DIR      := $(API_DIR)/db/seeds

.DEFAULT_GOAL := help

.PHONY: help
help: ## Muestra la lista de comandos disponibles
	@echo "Comandos disponibles:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

# ----------------------------------------------------------------------------
# Base de datos
# ----------------------------------------------------------------------------
.PHONY: db-up
db-up: ## Levanta PostgreSQL en Docker
	$(COMPOSE) up -d postgres

.PHONY: db-down
db-down: ## Detiene los contenedores de desarrollo
	$(COMPOSE) down

.PHONY: migrate
migrate: migrate-up ## Alias de migrate-up

.PHONY: migrate-up
migrate-up: ## Aplica todas las migraciones pendientes
	goose -dir $(MIGRATIONS_DIR) postgres "$(DATABASE_URL)" up

.PHONY: migrate-down
migrate-down: ## Revierte la última migración
	goose -dir $(MIGRATIONS_DIR) postgres "$(DATABASE_URL)" down

.PHONY: migrate-status
migrate-status: ## Muestra el estado de las migraciones
	goose -dir $(MIGRATIONS_DIR) postgres "$(DATABASE_URL)" status

.PHONY: migrate-version
migrate-version: ## Muestra la versión actual de la base de datos
	goose -dir $(MIGRATIONS_DIR) postgres "$(DATABASE_URL)" version

.PHONY: migrate-create
migrate-create: ## Crea una migración secuencial (NAME=nombre)
	@test -n "$(NAME)" || { echo "Uso: make migrate-create NAME=nombre"; exit 1; }
	goose -dir $(MIGRATIONS_DIR) -s create $(NAME) sql

.PHONY: db-reset
db-reset: ## Borra el esquema, reaplica migraciones y datos iniciales
	psql "$(DATABASE_URL)" -v ON_ERROR_STOP=1 -c 'DROP SCHEMA public CASCADE; CREATE SCHEMA public;'
	$(MAKE) migrate-up
	$(MAKE) seed

.PHONY: seed
seed: ## Carga los datos iniciales
	@for f in $(SEEDS_DIR)/*.sql; do \
		echo "psql $$f"; \
		psql "$(DATABASE_URL)" -v ON_ERROR_STOP=1 -f "$$f" || exit 1; \
	done

.PHONY: sqlc
sqlc: ## Regenera el código de acceso a datos con sqlc
	cd $(API_DIR) && sqlc generate

# ----------------------------------------------------------------------------
# Backend (Go)
# ----------------------------------------------------------------------------
.PHONY: api-run
api-run: ## Ejecuta el backend
	cd $(API_DIR) && go run .

.PHONY: api-build
api-build: ## Compila el backend
	cd $(API_DIR) && go build -o bin/server .

.PHONY: api-test
api-test: ## Ejecuta las pruebas del backend
	cd $(API_DIR) && go test ./...

.PHONY: api-fmt
api-fmt: ## Formatea el código Go
	cd $(API_DIR) && gofmt -w .

.PHONY: api-lint
api-lint: ## Analiza el código Go con golangci-lint
	cd $(API_DIR) && golangci-lint run ./...

# ----------------------------------------------------------------------------
# Cliente de la API
# ----------------------------------------------------------------------------
.PHONY: gen-client
gen-client: ## Genera packages/api_client desde contracts/openapi.yaml
	./scripts/gen-client.sh

# ----------------------------------------------------------------------------
# App Flutter
# ----------------------------------------------------------------------------
.PHONY: pos-run
pos-run: ## Ejecuta la app Flutter
	cd $(POS_DIR) && flutter run

.PHONY: pos-test
pos-test: ## Ejecuta las pruebas de la app
	cd $(POS_DIR) && flutter test

.PHONY: pos-analyze
pos-analyze: ## Analiza el código Dart con flutter analyze
	cd $(POS_DIR) && flutter analyze

.PHONY: pos-fmt
pos-fmt: ## Formatea el código Dart
	cd $(POS_DIR) && dart format .
