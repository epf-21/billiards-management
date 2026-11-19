# Sistema para Billar

Monorepo con un backend en **Go** (`apps/api`) y una app en **Flutter** (`apps/pos`), ambos organizados con **Clean Architecture**, sobre **PostgreSQL**.

---

## 1. Vista general

```
billiards-management/
├── apps/
│   ├── api/                      # Backend (Go)
│   └── pos/                      # App de punto de venta (Flutter)
│
├── packages/
│   └── api_client/               # Cliente Dart generado desde OpenAPI
│
├── contracts/
│   └── openapi.yaml              # Contrato de la API (fuente de verdad)
│
├── infra/
│   ├── docker/                   # Dockerfile del api y compose de desarrollo
│   ├── deploy/                   # Scripts/config de despliegue (VPS)
│   └── backups/                  # Scripts de respaldo de PostgreSQL
│
├── docs/
│   ├── mvp.md                    # Alcance del MVP y mejoras futuras
│   └── decisiones/               # ADRs: decisiones técnicas y su motivo
│
├── scripts/                      # Utilidades: generar cliente, seeds, etc.
├── .github/workflows/            # CI (si se usa GitHub)
├── Makefile                      # Atajos de comandos del monorepo
├── .gitignore
└── README.md
```

| Carpeta | Propósito |
|---|---|
| `apps/` | Aplicaciones ejecutables o desplegables. Hoy `api` y `pos`|
| `packages/` | Código compartido entre apps (por ahora, el cliente Dart de la API). |
| `contracts/` | Contrato OpenAPI. De aquí se genera el cliente Dart y la documentación. |
| `infra/` | Todo lo operativo: contenedores, despliegue y respaldos. |
| `docs/` | Documentación del proyecto y decisiones de arquitectura. |
| `scripts/` | Scripts auxiliares invocados desde el `Makefile`. |

---

## 2. Principios de Clean Architecture aplicados

### Regla de dependencia

Las dependencias solo apuntan **hacia adentro**. Las capas internas no conocen a las externas.

```
  Presentation   ──►  Application (use cases)  ──►  Domain
  Infrastructure ──►  Application (use cases)  ──►  Domain
```

| Capa | Contiene | Puede depender de |
|---|---|---|
| **Domain** | Entidades, objetos de valor, reglas de negocio, interfaces de repositorio, errores de dominio | Nada (solo el lenguaje) |
| **Application** | Casos de uso, DTOs de entrada/salida, puertos | Domain |
| **Infrastructure** | Implementación de repositorios, acceso a PostgreSQL, clientes HTTP | Domain y Application |
| **Presentation** | Handlers HTTP, WebSockets en el api; pantallas y estado en Flutter | Application (y dominio para tipos) |

### Qué reglas viven en el dominio

Las reglas que no dependen de ningún framework: calcular el cobro de una sesión según la tarifa y las pausas, validar transiciones de estado de una mesa (free → busy → free), calcular el total de una cuenta, etc.

---

## 3. Backend: `apps/api` (Go)

Organización: **por capa** de Clean Architecture (`domain`, `application`, `presentation`, `infrastructure`) y, dentro de cada capa, **por feature** de dominio (`tables`, `sessions`, `products`, `consumptions`, `cash`, `users`). Todos los nombres de carpetas y archivos van en inglés.

```
apps/api/
├── cmd/
│   └── server/
│       └── main.go                   # Punto de entrada; solo arranca bootstrap
│
├── internal/
│   ├── domain/                       # Reglas de negocio puras
│   │   ├── tables/
│   │   │   ├── table.go              # Entidad Table
│   │   │   ├── table_type.go         # Entidad TableType (con tarifa)
│   │   │   ├── status.go             # Estados y transiciones válidas
│   │   │   ├── repository.go         # Interfaz TableRepository
│   │   │   └── errors.go             # Errores de dominio
│   │   ├── sessions/
│   │   │   ├── session.go            # Entidad: inicio, pausas, fin
│   │   │   ├── pause.go
│   │   │   ├── pricing.go            # Regla: tiempo -> monto
│   │   │   ├── repository.go
│   │   │   └── errors.go
│   │   ├── products/
│   │   ├── consumptions/
│   │   ├── cash/
│   │   │   ├── account.go            # Tiempo + consumos
│   │   │   ├── payment.go            # Efectivo, QR, transferencia
│   │   │   ├── cash_shift.go         # Apertura/cierre
│   │   │   └── repository.go
│   │   ├── users/
│   │   └── shared/
│   │       ├── money/                # Tipo Money (enteros/centavos)
│   │       ├── clock/                # Interfaz Clock (pruebas con tiempo)
│   │       ├── apperror/             # Errores comunes (not found, conflict...)
│   │       └── ids/                  # Generación de identificadores
│   │
│   ├── application/                  # Casos de uso y DTOs
│   │   ├── tables/
│   │   │   ├── create_table.go
│   │   │   ├── list_tables.go
│   │   │   ├── change_status.go
│   │   │   └── dto.go
│   │   ├── sessions/
│   │   │   ├── start_session.go
│   │   │   ├── pause_session.go
│   │   │   ├── resume_session.go
│   │   │   ├── change_table.go
│   │   │   └── finish_session.go
│   │   ├── products/
│   │   ├── consumptions/
│   │   ├── cash/
│   │   │   ├── charge_account.go
│   │   │   ├── open_cash_shift.go
│   │   │   ├── close_cash_shift.go
│   │   │   └── shift_report.go
│   │   └── users/
│   │
│   ├── presentation/                 # Entrada/salida: HTTP y WebSocket
│   │   ├── http/
│   │   │   ├── tables/
│   │   │   │   ├── handler.go
│   │   │   │   ├── routes.go
│   │   │   │   └── dto.go
│   │   │   ├── sessions/
│   │   │   ├── products/
│   │   │   ├── consumptions/
│   │   │   ├── cash/
│   │   │   └── users/
│   │   └── ws/                       # (opcional) eventos en tiempo real
│   │
│   ├── infrastructure/               # Implementaciones concretas
│   │   ├── postgres/
│   │   │   ├── tables/
│   │   │   │   └── repository.go     # Implementa domain.TableRepository
│   │   │   ├── sessions/
│   │   │   ├── products/
│   │   │   ├── consumptions/
│   │   │   ├── cash/
│   │   │   └── users/
│   │   ├── platform/                 # Infraestructura transversal
│   │   │   ├── config/               # Carga de variables de entorno
│   │   │   ├── database/             # Pool pgx y código sqlc generado
│   │   │   ├── auth/                 # JWT y middleware de roles
│   │   │   ├── logger/
│   │   │   └── realtime/             # Hub de WebSockets
│   │   └── bootstrap/
│   │       └── app.go                # Composition root: crea y conecta todo
│   │
│   └── (las cuatro capas de arriba son la única organización interna)
│
├── db/
│   ├── migrations/                   # SQL versionado (goose o Atlas)
│   ├── queries/                      # Consultas SQL para sqlc, por feature
│   └── seeds/                        # Datos iniciales (table types, admin)
│
├── go.mod
├── go.sum
└── sqlc.yaml
```

### Responsabilidades por capa (api)

| Carpeta | Responsabilidad | No debe |
|---|---|---|
| `domain/<feature>/` | Entidades, reglas de negocio e interfaces de repositorio | Importar `pgx`, `net/http` ni nada de infraestructura |
| `application/<feature>/` | Orquestar un caso de uso: validar, llamar al dominio, usar repositorios por interfaz, devolver DTOs | Conocer HTTP ni SQL |
| `infrastructure/postgres/<feature>/` | Implementar los repositorios con `pgx` y el código de `sqlc` | Contener reglas de negocio |
| `presentation/http/<feature>/` | Traducir HTTP a casos de uso y viceversa; validar formato de entrada; mapear errores a códigos HTTP | Contener lógica de negocio ni consultas SQL |
| `infrastructure/bootstrap/` | Crear repositorios, casos de uso y handlers, y conectarlos (inyección manual de dependencias) | Contener lógica |

### Reglas del backend

- **Las features no importan la infraestructura de otras features.** Si `cash` necesita datos de `sessions`, depende de una **interfaz** definida en su propio `application/` o `domain/`, y `bootstrap` la conecta.
- **`internal/`** impide que otros proyectos importen este código.
- **Dinero** siempre con el tipo de `domain/shared/money` (enteros), nunca `float`.
- **El tiempo se calcula en el servidor**, a partir de timestamps guardados, usando la interfaz `Clock` para poder probarlo.
- **Una transacción por caso de uso** cuando toque varias tablas (por ejemplo, cobrar una cuenta).

### Flujo de una petición (ejemplo: iniciar sesión en una mesa)

```
HTTP POST /sessions
   │
   ▼
presentation/http/sessions/handler.go     (valida el JSON, extrae el usuario)
   │
   ▼
application/sessions/start_session.go     (caso de uso)
   │   ├─► domain/tables (interfaz): verificar que la mesa esté libre
   │   ├─► domain/sessions: crear Session (regla de negocio)
   │   └─► domain/sessions/repository.go (interfaz)
   │
   ▼
infrastructure/postgres/sessions/repository.go  (guarda en PostgreSQL)
```

### Pruebas (api)

- **Domain**: pruebas unitarias puras (por ejemplo, `domain/sessions/pricing_test.go`), sin base de datos.
- **Application**: pruebas con repositorios falsos (mocks o fakes) escritos a mano.
- **Infrastructure**: pruebas de integración contra un PostgreSQL de prueba (testcontainers o Docker).
- **Presentation**: pruebas de handlers con `httptest`.

---

## 4. App Flutter: `apps/pos`

Organización: **por capa** (`domain`, `application`, `presentation`, `infrastructure`) y, dentro de cada capa, **por feature** (`auth`, `tables`, `sessions`, `consumptions`, `cash`, `configuration`). Todos los nombres de carpetas y archivos van en inglés.

```
apps/pos/
├── lib/
│   ├── main.dart                     # Arranque de la app
│   ├── app.dart                      # MaterialApp, tema y router
│   │
│   ├── domain/                       # Entidades y contratos puros
│   │   ├── auth/
│   │   │   ├── entities/
│   │   │   │   ├── user.dart
│   │   │   │   └── role.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart   # Contrato abstracto
│   │   ├── tables/
│   │   ├── sessions/
│   │   ├── consumptions/
│   │   ├── cash/
│   │   ├── configuration/
│   │   └── shared/
│   │       └── value_objects/
│   │           └── money.dart        # Tipo Money (enteros)
│   │
│   ├── application/                  # Casos de uso
│   │   ├── auth/
│   │   │   └── usecases/
│   │   │       ├── login.dart
│   │   │       └── logout.dart
│   │   ├── tables/
│   │   ├── sessions/
│   │   ├── consumptions/
│   │   ├── cash/
│   │   │   └── usecases/
│   │   │       └── charge_account.dart
│   │   └── configuration/
│   │
│   ├── presentation/                 # Pantallas, estado y widgets
│   │   ├── auth/
│   │   │   ├── pages/
│   │   │   │   └── login_page.dart
│   │   │   ├── widgets/
│   │   │   └── state/                # Providers/Notifiers (Riverpod) o Blocs
│   │   ├── tables/
│   │   ├── sessions/
│   │   ├── consumptions/
│   │   ├── cash/
│   │   │   ├── pages/
│   │   │   └── state/
│   │   ├── configuration/
│   │   └── shared/
│   │       ├── router/               # Rutas y guards por rol
│   │       ├── theme/                # Colores, tipografía, estilos
│   │       ├── widgets/              # Widgets reutilizables
│   │       └── utils/                # Formato de dinero, fechas, duraciones
│   │
│   └── infrastructure/               # Implementaciones y servicios externos
│       ├── auth/
│       │   ├── datasources/
│       │   │   ├── auth_remote_data_source.dart
│       │   │   └── auth_local_data_source.dart   # Token
│       │   ├── models/               # DTOs / mapeo desde el cliente de la API
│       │   └── repositories/
│       │       └── auth_repository_impl.dart
│       ├── tables/
│       ├── sessions/
│       ├── consumptions/
│       ├── cash/
│       ├── configuration/
│       └── shared/
│           ├── config/               # URL de la API, entornos
│           ├── di/                   # Inyección de dependencias (providers)
│           ├── network/             # Cliente HTTP, interceptores, WebSocket
│           ├── errors/               # Failures y excepciones comunes
│           └── utils/                # Utilidades de infraestructura
│
├── test/                             # Refleja la estructura de lib/
│   ├── domain/
│   ├── application/
│   ├── presentation/
│   └── infrastructure/
├── integration_test/                 # Flujos completos (turno de caja)
├── android/
├── ios/                              # Si se publica en iOS
├── linux/                            # Si se genera versión de escritorio
├── pubspec.yaml
└── analysis_options.yaml
```

### Responsabilidades por capa (pos)

| Carpeta | Responsabilidad | No debe |
|---|---|---|
| `domain/<feature>/entities` | Objetos de negocio puros (Table, Session, Account...) | Depender de Flutter ni de paquetes de red |
| `domain/<feature>/repositories` | Contratos abstractos que usa la app | Tener implementación |
| `application/<feature>/usecases` | Una acción de negocio cada uno (`Login`, `ChargeAccount`) | Conocer widgets ni HTTP |
| `infrastructure/<feature>/datasources` | Hablar con la API (remoto) o con almacenamiento local | Contener reglas de negocio |
| `infrastructure/<feature>/models` | Convertir lo que devuelve la API a entidades del dominio (y al revés) | Salir de la capa de infraestructura |
| `infrastructure/<feature>/repositories` | Implementar los contratos del dominio usando los datasources | Exponer modelos de la API hacia arriba |
| `presentation/<feature>/pages` | Pantallas | Llamar directamente a la API |
| `presentation/<feature>/state` | Estado de la pantalla; invoca casos de uso | Contener lógica de negocio compleja |

### Reglas de la app

- **El cliente de la API** viene de `packages/api_client`. Solo la capa `infrastructure/` lo usa; el dominio y la presentación nunca ven sus clases.
- **El cronómetro en pantalla es solo visual**: la fuente de verdad es el servidor (hora de inicio y pausas). La app calcula lo mostrado a partir de esos datos.
- **Dinero** con un tipo propio en `domain/shared/value_objects/money.dart` (enteros), no `double`.
- **Estado en tiempo real**: la feature `tables` escucha el WebSocket y actualiza su estado; el resto de features lo consume vía providers.
- **Código común** va en `presentation/shared/` o `domain/shared/`. Si más adelante se crea otra app Flutter, lo compartido se extrae a `packages/`.

### Flujo en la app (ejemplo: cobrar una cuenta)

```
presentation/cash/pages/... (usuario toca "Charge")
   │
   ▼
presentation/cash/state/... (CashNotifier)
   │
   ▼
application/cash/usecases/charge_account.dart
   │
   ▼
domain/cash/repositories/cash_repository.dart (abstracta)
   ▲
   │ implementada por
infrastructure/cash/repositories/cash_repository_impl.dart
   │
   ▼
infrastructure/cash/datasources/... ──► packages/api_client ──► API Go
```

### Pruebas (pos)

- **Domain y Application**: pruebas unitarias con repositorios falsos.
- **Infrastructure**: pruebas de mapeo de modelos y de repositorios con datasources falsos.
- **Presentation**: pruebas de widgets y de notifiers/blocs.
- **`integration_test/`**: flujo completo de un turno (abrir caja, iniciar sesión, consumir, cobrar, cerrar).

---

## 5. Paquete compartido: `packages/api_client`

```
packages/api_client/
├── lib/
│   └── src/                  # Código generado desde contracts/openapi.yaml
├── pubspec.yaml
└── README.md
```

- Se **genera** a partir de `contracts/openapi.yaml`; no se edita a mano.
- `apps/pos` lo declara como dependencia local (por ruta o mediante Dart workspaces).
- Cada vez que cambia el contrato de la API, se regenera con un comando del `Makefile`.

---

## 6. Infraestructura y utilidades

```
infra/
├── docker/
│   ├── api.Dockerfile
│   └── compose.yml        # api + postgres para desarrollo
├── deploy/                       # Scripts o configuración del servidor
└── backups/                      # Scripts de respaldo y restauración

scripts/
├── gen-client.sh                 # Genera packages/api_client desde OpenAPI
├── migrate.sh                    # Aplica migraciones
└── seed.sh                       # Carga datos iniciales
```

### Comandos sugeridos (`Makefile`)

| Comando | Acción |
|---|---|
| `make db-up` | Levanta PostgreSQL con Docker |
| `make migrate` | Aplica las migraciones |
| `make sqlc` | Regenera el código de acceso a datos |
| `make api-run` | Ejecuta el backend |
| `make api-test` | Pruebas del backend |
| `make gen-client` | Regenera el cliente Dart desde OpenAPI |
| `make pos-run` | Ejecuta la app Flutter |
| `make pos-test` | Pruebas de la app |

---

## 7. Convenciones

- **Idioma**: **inglés** para nombres de carpetas y archivos (`tables`, `sessions`, `account`, `cash_shift`) para que backend, base de datos y app hablen igual. La documentación puede estar en español.
- **Mismo nombre de feature en todas las capas**: `auth`, `tables`, `sessions`, `consumptions`, `cash` y `configuration` se repiten igual dentro de `domain/`, `application/`, `presentation/` e `infrastructure/`, lo que facilita ubicar el código.
- **Commits y ramas**: un cambio que toque el contrato debe incluir en el mismo commit el `openapi.yaml`, el backend y el cliente regenerado.
- **Decisiones importantes** se registran en `docs/decisiones/` (un archivo corto por decisión).

---

## 8. Orden sugerido para empezar

1. Crear el esqueleto de carpetas y el `Makefile`.
2. Levantar PostgreSQL con Docker Compose.
3. Escribir las primeras migraciones (tables, table types, users).
4. Implementar la feature `tables` completa en el api (domain → application → infrastructure → presentation) como plantilla para las demás.
5. Definir `openapi.yaml`, generar `api_client` y construir la feature `tables` en `pos`.
6. Repetir con `sessions`, `consumptions` y `cash`.
