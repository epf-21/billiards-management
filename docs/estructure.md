# Sistema para Billar

Monorepo con un backend en **Go** (`apps/api`) y una app en **Flutter** (`apps/pos`), ambos organizados con **Clean Architecture**, sobre **PostgreSQL**.

---

## 1. Vista general

```
billar/
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
  Interfaces / Presentación   ──►  Aplicación (casos de uso)  ──►  Dominio
  Infraestructura / Datos     ──►  Aplicación (casos de uso)  ──►  Dominio
```

| Capa | Contiene | Puede depender de |
|---|---|---|
| **Dominio** | Entidades, objetos de valor, reglas de negocio, interfaces de repositorio, errores de dominio | Nada (solo el lenguaje) |
| **Aplicación** | Casos de uso, DTOs de entrada/salida, puertos | Dominio |
| **Infraestructura / Datos** | Implementación de repositorios, acceso a PostgreSQL, clientes HTTP | Dominio y Aplicación |
| **Interfaces / Presentación** | Handlers HTTP, WebSockets en el api; pantallas y estado en Flutter | Aplicación (y dominio para tipos) |

### Qué reglas viven en el dominio

Las reglas que no dependen de ningún framework: calcular el cobro de una sesión según la tarifa y las pausas, validar transiciones de estado de una mesa (libre → ocupada → libre), calcular el total de una cuenta, etc.

---

## 3. Backend: `apps/api` (Go)

Organización: **por módulo de dominio** (mesas, sesiones, caja...) y, dentro de cada módulo, **por capas** de Clean Architecture.

```
apps/api/
├── cmd/
│   └── server/
│       └── main.go                   # Punto de entrada; solo arranca bootstrap
│
├── internal/
│   ├── mesas/
│   │   ├── domain/
│   │   │   ├── mesa.go               # Entidad Mesa
│   │   │   ├── tipo_mesa.go          # Entidad TipoMesa (con tarifa)
│   │   │   ├── estado.go             # Estados y transiciones válidas
│   │   │   ├── repository.go         # Interfaz MesaRepository
│   │   │   └── errors.go             # Errores de dominio
│   │   ├── application/
│   │   │   ├── crear_mesa.go         # Caso de uso
│   │   │   ├── listar_mesas.go
│   │   │   ├── cambiar_estado.go
│   │   │   └── dto.go                # Entradas/salidas de los casos de uso
│   │   ├── infrastructure/
│   │   │   └── postgres/
│   │   │       └── mesa_repository.go  # Implementa domain.MesaRepository
│   │   └── interfaces/
│   │       ├── http/
│   │       │   ├── handler.go        # Handlers HTTP
│   │       │   ├── routes.go         # Registro de rutas del módulo
│   │       │   └── dto.go            # Request/Response HTTP
│   │       └── ws/                   # (opcional) eventos en tiempo real
│   │
│   ├── sesiones/                     # Sesiones de juego (tiempo)
│   │   ├── domain/
│   │   │   ├── sesion.go             # Entidad: inicio, pausas, fin
│   │   │   ├── pausa.go
│   │   │   ├── calculo_tarifa.go     # Regla: tiempo -> monto
│   │   │   ├── repository.go
│   │   │   └── errors.go
│   │   ├── application/
│   │   │   ├── iniciar_sesion.go
│   │   │   ├── pausar_sesion.go
│   │   │   ├── reanudar_sesion.go
│   │   │   ├── cambiar_mesa.go
│   │   │   └── finalizar_sesion.go
│   │   ├── infrastructure/postgres/
│   │   └── interfaces/http/
│   │
│   ├── productos/                    # Catálogo e inventario
│   │   ├── domain/
│   │   ├── application/
│   │   ├── infrastructure/postgres/
│   │   └── interfaces/http/
│   │
│   ├── consumos/                     # Consumos asociados a una sesión
│   │   ├── domain/
│   │   ├── application/
│   │   ├── infrastructure/postgres/
│   │   └── interfaces/http/
│   │
│   ├── caja/                         # Cobros, pagos, apertura y cierre
│   │   ├── domain/
│   │   │   ├── cuenta.go             # Tiempo + consumos
│   │   │   ├── pago.go               # Efectivo, QR, transferencia
│   │   │   ├── turno_caja.go         # Apertura/cierre
│   │   │   └── repository.go
│   │   ├── application/
│   │   │   ├── cobrar_cuenta.go
│   │   │   ├── abrir_caja.go
│   │   │   ├── cerrar_caja.go
│   │   │   └── reporte_cierre.go
│   │   ├── infrastructure/postgres/
│   │   └── interfaces/http/
│   │
│   ├── usuarios/                     # Usuarios, roles y autenticación
│   │   ├── domain/
│   │   ├── application/
│   │   ├── infrastructure/postgres/
│   │   └── interfaces/http/
│   │
│   ├── shared/                       # Núcleo compartido, sin dependencias externas
│   │   ├── money/                    # Tipo Dinero (enteros/centavos)
│   │   ├── clock/                    # Interfaz Clock (facilita pruebas con tiempo)
│   │   ├── apperror/                 # Errores comunes (no encontrado, conflicto...)
│   │   └── ids/                      # Generación de identificadores
│   │
│   ├── platform/                     # Infraestructura transversal
│   │   ├── config/                   # Carga de variables de entorno
│   │   ├── database/                 # Pool de conexión pgx y código sqlc generado
│   │   ├── httpserver/               # Servidor, middlewares, manejo de errores
│   │   ├── auth/                     # JWT y middleware de roles
│   │   ├── logger/
│   │   └── realtime/                 # Hub de WebSockets
│   │
│   └── bootstrap/
│       └── app.go                    # Composition root: crea y conecta todo
│
├── db/
│   ├── migrations/                   # SQL versionado (goose o Atlas)
│   ├── queries/                      # Consultas SQL para sqlc, por módulo
│   └── seeds/                        # Datos iniciales (tipos de mesa, admin)
│
├── go.mod
├── go.sum
└── sqlc.yaml
```

### Responsabilidades por capa (api)

| Carpeta | Responsabilidad | No debe |
|---|---|---|
| `domain/` | Entidades, reglas de negocio e interfaces de repositorio | Importar `pgx`, `net/http` ni nada de infraestructura |
| `application/` | Orquestar un caso de uso: validar, llamar al dominio, usar repositorios por interfaz, devolver DTOs | Conocer HTTP ni SQL |
| `infrastructure/postgres/` | Implementar los repositorios con `pgx` y el código de `sqlc` | Contener reglas de negocio |
| `interfaces/http/` | Traducir HTTP a casos de uso y viceversa; validar formato de entrada; mapear errores a códigos HTTP | Contener lógica de negocio ni consultas SQL |
| `bootstrap/` | Crear repositorios, casos de uso y handlers, y conectarlos (inyección manual de dependencias) | Contener lógica |

### Reglas del backend

- **Los módulos no importan la infraestructura de otros módulos.** Si `caja` necesita datos de `sesiones`, depende de una **interfaz** definida en su propio `application/` o `domain/`, y `bootstrap` la conecta.
- **`internal/`** impide que otros proyectos importen este código.
- **Dinero** siempre con el tipo de `shared/money` (enteros), nunca `float`.
- **El tiempo se calcula en el servidor**, a partir de timestamps guardados, usando la interfaz `Clock` para poder probarlo.
- **Una transacción por caso de uso** cuando toque varias tablas (por ejemplo, cobrar una cuenta).

### Flujo de una petición (ejemplo: iniciar sesión en una mesa)

```
HTTP POST /sesiones
   │
   ▼
sesiones/interfaces/http/handler.go     (valida el JSON, extrae el usuario)
   │
   ▼
sesiones/application/iniciar_sesion.go  (caso de uso)
   │   ├─► mesas (interfaz): verificar que la mesa esté libre
   │   ├─► sesiones/domain: crear Sesion (regla de negocio)
   │   └─► SesionRepository (interfaz)
   │
   ▼
sesiones/infrastructure/postgres/       (implementación: guarda en PostgreSQL)
```

### Pruebas (api)

- **Dominio**: pruebas unitarias puras (por ejemplo, `calculo_tarifa_test.go`), sin base de datos.
- **Aplicación**: pruebas con repositorios falsos (mocks o fakes) escritos a mano.
- **Infraestructura**: pruebas de integración contra un PostgreSQL de prueba (testcontainers o Docker).
- **HTTP**: pruebas de handlers con `httptest`.

---

## 4. App Flutter: `apps/pos`

Organización: **por feature** y, dentro de cada feature, **por capas** (`domain`, `data`, `presentation`).

```
apps/pos/
├── lib/
│   ├── main.dart                     # Arranque de la app
│   ├── app.dart                      # MaterialApp, tema y router
│   │
│   ├── core/                         # Transversal a todas las features
│   │   ├── config/                   # URL de la API, entornos
│   │   ├── di/                       # Inyección de dependencias (providers)
│   │   ├── network/                  # Cliente HTTP, interceptores, WebSocket
│   │   ├── router/                   # Rutas y guards por rol
│   │   ├── theme/                    # Colores, tipografía, estilos
│   │   ├── errors/                   # Failures y excepciones comunes
│   │   ├── utils/                    # Formato de dinero, fechas, duraciones
│   │   └── widgets/                  # Widgets reutilizables (botones, diálogos...)
│   │
│   └── features/
│       ├── auth/
│       │   ├── domain/
│       │   │   ├── entities/         # Usuario, Rol
│       │   │   ├── repositories/     # AuthRepository (abstracta)
│       │   │   └── usecases/         # IniciarSesion, CerrarSesion
│       │   ├── data/
│       │   │   ├── datasources/      # AuthRemoteDataSource, AuthLocalDataSource (token)
│       │   │   ├── models/           # DTOs / mapeo desde el cliente de la API
│       │   │   └── repositories/     # AuthRepositoryImpl
│       │   └── presentation/
│       │       ├── pages/            # LoginPage
│       │       ├── widgets/
│       │       └── state/            # Providers/Notifiers (Riverpod) o Blocs
│       │
│       ├── mesas/                    # Vista del salón y estado de las mesas
│       │   ├── domain/
│       │   ├── data/
│       │   └── presentation/
│       │
│       ├── sesiones/                 # Iniciar, pausar, cambiar de mesa, finalizar
│       │   ├── domain/
│       │   ├── data/
│       │   └── presentation/
│       │
│       ├── consumos/                 # Agregar o quitar consumos de una cuenta
│       │   ├── domain/
│       │   ├── data/
│       │   └── presentation/
│       │
│       ├── caja/                     # Cobro, apertura y cierre de caja
│       │   ├── domain/
│       │   ├── data/
│       │   └── presentation/
│       │
│       └── configuracion/            # Solo administrador: tarifas, productos, usuarios
│           ├── domain/
│           ├── data/
│           └── presentation/
│
├── test/                             # Refleja la estructura de lib/
│   ├── core/
│   └── features/
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
| `domain/entities` | Objetos de negocio puros (Mesa, Sesion, Cuenta...) | Depender de Flutter ni de paquetes de red |
| `domain/repositories` | Contratos abstractos que usa la app | Tener implementación |
| `domain/usecases` | Una acción de negocio cada uno (`IniciarSesion`, `CobrarCuenta`) | Conocer widgets ni HTTP |
| `data/datasources` | Hablar con la API (remoto) o con almacenamiento local | Contener reglas de negocio |
| `data/models` | Convertir lo que devuelve la API a entidades del dominio (y al revés) | Salir de la capa de datos |
| `data/repositories` | Implementar los contratos del dominio usando los datasources | Exponer modelos de la API hacia arriba |
| `presentation/pages` | Pantallas | Llamar directamente a la API |
| `presentation/state` | Estado de la pantalla; invoca casos de uso | Contener lógica de negocio compleja |

### Reglas de la app

- **El cliente de la API** viene de `packages/api_client`. Solo la capa `data/` lo usa; el dominio y la presentación nunca ven sus clases.
- **El cronómetro en pantalla es solo visual**: la fuente de verdad es el servidor (hora de inicio y pausas). La app calcula lo mostrado a partir de esos datos.
- **Dinero** con un tipo propio en `core/utils` (enteros), no `double`.
- **Estado en tiempo real**: la feature `mesas` escucha el WebSocket y actualiza su estado; el resto de features lo consume vía providers.
- **Código común** va en `core/`. Si más adelante se crea otra app Flutter, `core/` y los widgets compartidos se extraen a `packages/`.

### Flujo en la app (ejemplo: cobrar una cuenta)

```
CajaPage (presentation/pages)
   │  usuario toca "Cobrar"
   ▼
CajaNotifier (presentation/state)
   │
   ▼
CobrarCuenta (domain/usecases)
   │
   ▼
CajaRepository (domain/repositories, abstracta)
   ▲
   │ implementada por
CajaRepositoryImpl (data/repositories)
   │
   ▼
CajaRemoteDataSource (data/datasources) ──► packages/api_client ──► API Go
```

### Pruebas (pos)

- **Dominio y casos de uso**: pruebas unitarias con repositorios falsos.
- **Data**: pruebas de mapeo de modelos y de repositorios con datasources falsos.
- **Presentación**: pruebas de widgets y de notifiers/blocs.
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
│   └── docker-compose.yml        # api + postgres para desarrollo
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

- **Idioma**: un solo idioma para nombres de dominio en todo el repo (por ejemplo, español: `mesa`, `sesion`, `cuenta`, `caja`) para que backend, base de datos y app hablen igual.
- **Nombres de módulo = nombres de feature**: `mesas`, `sesiones`, `consumos`, `caja` existen igual en `api` y en `pos`, lo que facilita ubicar el código.
- **Commits y ramas**: un cambio que toque el contrato debe incluir en el mismo commit el `openapi.yaml`, el backend y el cliente regenerado.
- **Decisiones importantes** se registran en `docs/decisiones/` (un archivo corto por decisión).

---

## 8. Orden sugerido para empezar

1. Crear el esqueleto de carpetas y el `Makefile`.
2. Levantar PostgreSQL con Docker Compose.
3. Escribir las primeras migraciones (mesas, tipos de mesa, usuarios).
4. Implementar el módulo `mesas` completo en el api (domain → application → infrastructure → http) como plantilla para los demás.
5. Definir `openapi.yaml`, generar `api_client` y construir la feature `mesas` en `pos`.
6. Repetir con `sesiones`, `consumos` y `caja`.
