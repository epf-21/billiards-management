API_DIR   := apps/api
POS_DIR   := apps/pos
COMPOSE   := docker compose -f infra/docker/compose.yml

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
	$(COMPOSE) up -d database

.PHONY: db-down
db-down: ## Detiene los contenedores de desarrollo
	$(COMPOSE) down

.PHONY: migrate
migrate: ## Aplica las migraciones de la base de datos
	./scripts/migrate.sh

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
