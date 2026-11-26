# Billiards Management

Sistema de gestión para un salón de billar: controla **mesas, tiempo de juego, consumos y caja**, y cobra sin errores. Reemplaza el cuaderno o la hoja de cálculo con una vista clara del salón y un historial confiable de cada cobro.


## Arquitectura

Monorepo con **Clean Architecture** en ambos lados, sobre **PostgreSQL**.

| Componente | Tecnología | Ruta |
|---|---|---|
| Backend | Go + pgx + sqlc | `apps/api` |
| Punto de venta | Flutter / Dart | `apps/pos` |
| Contrato de la API | OpenAPI | `contracts/openapi.yaml` |
| Cliente Dart generado | OpenAPI Generator | `packages/api_client` (pendiente) |
| Infraestructura | Docker, PostgreSQL, backups | `infra/` |

La regla de dependencia apunta siempre hacia adentro: **dominio ← aplicación ← infraestructura/presentación**.

## Estructura del repositorio

```
billiards-management/
├── apps/
│   ├── api/     # Backend en Go
│   └── pos/     # App de punto de venta en Flutter
├── docs/        # Alcance del MVP y arquitectura
├── infra/       # Contenedores, despliegue y respaldos
├── flake.nix    # Entorno de desarrollo (Nix)
└── Makefile     # Atajos de comandos del monorepo
```

La estructura objetivo completa (módulos, capas, paquetes) está descrita en [`docs/estructure.md`](docs/estructure.md).

## Requisitos

- [Nix](https://nixos.org/) con flakes habilitados y `direnv` (opcional, pero recomendado).
- Flutter SDK para `apps/pos`.
- Docker para PostgreSQL en desarrollo.

## Puesta en marcha

```bash
# Activa el entorno de desarrollo (Go, gopls, golangci-lint, delve)
direnv allow        # o: nix develop

# Ver todos los comandos disponibles
make help

# Levantar la base de datos
make db-up

# Aplicar migraciones y datos iniciales
make migrate-up
make seed

# Ejecutar el backend
make api-run

# Ejecutar la app
make pos-run
```

## Roles

- **Administrador**: configuración general, usuarios, tarifas, productos y reportes.
- **Encargado**: supervisión de la operación y del personal de la sucursal.
- **Cajero**: operación de mesas, consumos y cobros.

## Documentación

- [`docs/architecture.md`](docs/architecture.md): visión completa del sistema.
- [`docs/estructure.md`](docs/estructure.md): estructura de código, capas y convenciones.
- [`docs/decisiones/`](docs/decisiones/): decisiones de arquitectura y cobro.
- [`contracts/openapi.yaml`](contracts/openapi.yaml): contrato de la API.

## Estado del proyecto

Fase inicial: la arquitectura y el alcance están definidos; el backend y la app se encuentran en proceso de implementación.
