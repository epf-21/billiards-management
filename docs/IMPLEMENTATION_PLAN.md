# Plan de implementación por fases

Proyecto: Billiards Management
Estado: borrador para aprobación
Versión: 1.0
Fecha: 2026-11-26
Método: Spec-Driven Development (SDD)

Fuentes de verdad:

- `docs/architecture.md`
- `docs/estructure.md`
- `docs/billiards_modelo.dbml`
- `contracts/openapi.yaml`
- `docs/decisiones/ADR-001-dinero-y-cobro.md`
- `docs/decisiones/ADR-002-idioma-modelo.md`
- `docs/decisiones/ADR-003-alcance-mvp.md`

Regla principal: este plan no crea requisitos nuevos. Los IDs `SPEC` son etiquetas de trazabilidad para requisitos que ya existen en los documentos anteriores. Cuando un requisito no está definido, se registra como decisión pendiente y no se implementa.

---

## 1. Resumen ejecutivo

El proyecto tiene un diseño sólido y un esquema de datos avanzado, pero todavía no tiene backend, consultas, pruebas ni cliente Dart. El objetivo de este plan es convertir ese diseño en un MVP operativo sin construir las funciones futuras antes de validar el camino que cobra.

Estrategia:

1. Ordenar el trabajo en 8 fases pequeñas.
2. Cada fase empieza con un SPEC aprobado.
3. Cada fase termina con una demostración verificable.
4. El MVP se valida con un solo flujo completo: login, sucursal, turno de caja, sesión, consumo, cobro y cierre.
5. Las funciones F2 a F7 del DBML quedan como esquema futuro, sin endpoints ni pantallas hasta que el MVP esté estable.

Resultado esperado del MVP:

- Un cajero puede abrir turno, abrir una sesión, pausarla, cambiarla de mesa, finalizarla, agregar consumos, cobrar y cerrar turno.
- Un administrador puede crear tarifas, mesas, productos y usuarios.
- El cobro por tiempo es proporcional a los minutos jugados, con dos decimales.
- Cada operación crítica queda asociada a una sucursal y a un usuario.
- La caja cierra con efectivo esperado contra efectivo contado.

---

## 2. Análisis previo

### 2.1. Especificaciones existentes

| Documento | Qué define | Estado |
|---|---|---|
| `docs/architecture.md` | Visión completa, módulos, API, seguridad, persistencia, NFR, multi-sucursal y evolución | Vigente como visión |
| `docs/estructure.md` | Estructura de código, capas, convenciones y orden sugerido | Vigente para el MVP |
| `docs/billiards_modelo.dbml` | Modelo de datos en español, 38 tablas, enums y reglas | Vigente como modelo |
| `contracts/openapi.yaml` | Contrato HTTP con 16 rutas del MVP | Parcial, faltan endpoints administrativos |
| `docs/decisiones/ADR-001` | Dinero decimal, cobro por hora, dos modalidades | Aprobado |
| `docs/decisiones/ADR-002` | DBML en español, SQL en inglés, actualizar ambos | Aprobado |
| `docs/decisiones/ADR-003` | Alcance del MVP y funciones futuras | Aprobado |

### 2.2. Arquitectura

Monolito modular con Clean Architecture.

```
POS Flutter  ->  API Client Dart  ->  Backend Go  ->  PostgreSQL
                                      |
                                      +-- Identity & Access
                                      +-- Organization
                                      +-- Billiards Operations
                                      +-- Sales & Consumptions
                                      +-- Cash & Payments
                                      +-- Audit
```

Reglas que el plan debe respetar:

- El dominio no depende de HTTP, PostgreSQL ni Flutter.
- La lógica de cobro vive en el dominio y se prueba sin base de datos.
- El backend es la fuente de verdad de las reglas críticas.
- OpenAPI es el contrato HTTP.
- El DBML y el SQL se mantienen en paralelo, con nombres equivalentes.
- Las operaciones que tocan varias tablas usan una transacción.
- El dinero se representa con decimales, nunca con `float64`.

### 2.3. Modelo de datos

El esquema actual tiene 38 tablas de negocio y migraciones goose hasta la versión 9.

Tablas del MVP:

- Acceso: `branches`, `business_settings`, `roles`, `permissions`, `role_permissions`, `users`, `user_branches`, `refresh_tokens`, `audit_logs`.
- Operación: `rates`, `tables`, `sessions`, `session_pauses`, `table_changes`.
- Ventas: `product_categories`, `products`, `consumptions`.
- Caja: `cash_shifts`, `accounts`, `cash_movements`, `payments`.
- Futuro: clientes, reservas, inventario, compras, proveedores, gastos, prepago, créditos, promociones y torneos.

Estado actual de la base:

- `make db-reset` aplica las 9 migraciones y carga el seed.
- El seed crea roles, sucursal, configuración, 13 permisos, usuario `admin`, tarifa de 15.00 y Mesa 1.
- No hay índices explícitos en las migraciones.
- No hay restricciones únicas parciales para doble sesión o doble turno. Esa protección debe resolverse en la aplicación o en una decisión posterior.
- Las columnas `branch_id` existen en el flujo principal, pero las FKs compuestas por sucursal se retiraron junto con los índices.

### 2.4. Dependencias entre módulos

```
Fundaciones y contrato
        |
        v
Identidad, usuarios y sucursales
        |
        +--------------+
        v              v
Catálogo          Autorización por sucursal
(tarifas, mesas, productos)
        |
        v
Sesiones y pricing
        |
        +--------------+
        v              v
Consumos          Cuenta de la sesión
        |              |
        +------+-------+
               v
        Caja, pagos y cierre
               |
               v
              POS
               |
               v
        Endurecimiento y release
```

Dependencias duras:

- `sessions` necesita `tables`, `rates`, `users` y `branches`.
- `accounts` necesita `sessions`.
- `consumptions` necesita `sessions` y `products`.
- `payments` necesita `accounts` y `cash_shifts`.
- `cash_movements` necesita `cash_shifts` y, cuando corresponde, `accounts`.
- `audit_logs` necesita el usuario y la sucursal del contexto.
- El POS necesita todos los endpoints del MVP y el cliente Dart generado.

### 2.5. Funcionalidades existentes y pendientes

| Área | Existe | Falta |
|---|---|---|
| Base de datos | 9 migraciones, 38 tablas, seed idempotente | Revisar constraints y columnas cuando cambie el alcance |
| Contrato | 16 rutas OpenAPI | Rutas de tarifas, sucursales, usuarios, categorías, refresh y reportes |
| Backend | `go.mod` y `main.go` vacío | Todo el código de dominio, aplicación, infraestructura y presentación |
| Consultas | `sqlc.yaml` | Archivos `db/queries/*.sql` y código generado |
| Pruebas | Ninguna | Unitarias, integración, handlers y e2e |
| Cliente Dart | Ninguno | `packages/api_client` y `scripts/gen-client.sh` |
| POS | Demo por defecto de Flutter | Login, mesas, sesiones, consumos, cobro y caja |
| Infra | Compose con PostgreSQL | Servicio de API, Dockerfile, CI, backups y despliegue |
| Documentación | Arquitectura, estructura, DBML y 3 ADR | SPECs por módulo y ADR de decisiones pendientes |

### 2.6. Riesgos técnicos y de negocio

| Riesgo | Impacto | Mitigación |
|---|---|---|
| Cobro mal calculado | Alto | ADR-001, pruebas de dominio, ejemplos de aceptación |
| Doble sesión o doble caja por concurrencia | Alto | Bloqueos en transacción, pruebas concurrentes y decisión D-02 |
| Fuga de datos entre sucursales | Alto | Middleware de sucursal, consultas filtradas y pruebas |
| Caja que no cuadra | Alto | Un solo libro de caja, pago ligado a turno y pruebas |
| Alcance demasiado grande | Alto | ADR-003, fases con gate y prohibición de endpoints F2 a F7 |
| Falta de código y pruebas | Medio | Fase 0 con esqueleto, CI y pirámide de pruebas |
| Autenticación mal diseñada | Alto | ADR de autenticación, librerías estándar y revisión |
| Documentos y esquema desalineados | Medio | ADR-002 y checklist de cambio |
| Sin índices y con crecimiento de datos | Medio | Medir en Fase 7 y agregar índices solo con aprobación |
| Cuentas compartidas sin responsable | Medio | `responsible_name`, permisos restringidos y auditoría |
| Multi-tenant retroactivo | Alto | Decidir D-07 antes de Fase 1 |
| Contraseña de seed en producción | Alto | Cambiar antes de desplegar y usar bootstrap seguro |

### 2.7. Decisiones pendientes

| ID | Decisión | Bloquea | Opción recomendada para discutir |
|---|---|---|---|
| D-01 | Mecanismo de autenticación | Fase 1 | JWT de acceso corto y refresh rotativo hasheado, compatible con `refresh_tokens` |
| D-02 | Control de concurrencia sin índices | Fases 3 y 5 | Bloqueos de fila o advisory locks en transacción; revisar índices únicos parciales más adelante |
| D-03 | Tipos de mesa | Fase 2 | Mantener la tarifa como clasificador del MVP y diferir `table_types` |
| D-04 | Comportamiento de tiempo fijo | Fase 3 | Cobrar minutos jugados con límite contratado; definir salida anticipada y exceso |
| D-05 | Descuentos y promociones en el MVP | Fases 3 y 4 | Diferirlos a post-MVP porque ADR-003 no los incluye |
| D-06 | Baja lógica o campo `active` | Fase 2 | Agregar `active` o `archived_at` a tarifas, mesas y productos antes del CRUD |
| D-07 | Multi-tenant por organización | Fases 1 y 7 | Un negocio por despliegue en el MVP; `branch_id` para aislamiento |
| D-08 | Política de índices | Fase 7 | Sin índices en el MVP; medir y agregar solo con aprobación |
| D-09 | Libro único de caja | Fase 5 | Usar `cash_movements` como libro de efectivo y enlazar pagos al turno |
| D-10 | Detalle del reporte de cierre | Fases 5 y 6 | Totales por método y concepto, esperado, contado y diferencia |
| D-11 | Credenciales del admin | Fase 7 | Seed solo para desarrollo; bootstrap de producción por variable o comando |
| D-12 | Plataforma del POS | Fase 6 | Definir Linux, Android o web antes de construir las pantallas |
| D-13 | Zona horaria y moneda por sucursal | Fases 2 y 5 | Guardar zona horaria en configuración; BOB para el MVP |
| D-14 | Inmutabilidad de auditoría | Fase 7 | Permisos de solo inserción y protección contra update/delete |

### 2.8. Estado del repositorio

- `apps/api/main.go` está vacío.
- `apps/api/go.mod` existe, pero no hay paquetes internos.
- `apps/pos` es el proyecto Flutter por defecto.
- No existe `packages/api_client`.
- No existe `scripts/gen-client.sh`.
- El compose actual solo tiene PostgreSQL.
- No hay pruebas de backend ni de integración del POS.
- El esquema y el seed funcionan con goose.
- Los ADR 001 a 003 están aprobados.
- La documentación no tiene un catálogo formal de SPEC. Este plan lo introduce.

---

## 3. Método Spec-Driven Development

### 3.1. Reglas del método

1. Ninguna tarea de código empieza sin un SPEC aprobado.
2. Cada SPEC debe citar los documentos fuente y las líneas que lo respaldan.
3. Cada requisito debe tener un ID `SPEC-*`.
4. Cada tarea debe referenciar al menos un ID `SPEC-*`.
5. Cada fase debe tener criterios de aceptación verificables.
6. Cada fase termina con una demostración funcional.
7. Si aparece un requisito no documentado, se detiene la implementación y se abre una decisión.
8. Si cambia el esquema, se actualizan DBML y SQL en el mismo cambio.
9. No se agregan índices sin una decisión explícita.
10. No se implementan endpoints de funciones F2 a F7 hasta cerrar el MVP.

### 3.2. Estructura de un SPEC

Cada archivo `docs/specs/SPEC-*.md` debe contener:

- Contexto y problema.
- Alcance.
- Fuera de alcance.
- Requisitos con ID.
- Reglas de negocio.
- Contrato de API cuando aplique.
- Modelo de datos afectado.
- Criterios de aceptación.
- Casos de error.
- Plan de pruebas.
- Decisiones pendientes.
- Trazabilidad a documentos fuente.

### 3.3. Catálogo de SPEC

Los IDs son etiquetas de trazabilidad, no requisitos nuevos.

| ID | Requisito | Fuente | Fase | Estado |
|---|---|---|---|---|
| SPEC-ORG-01 | Toda operación se asocia a una sucursal | `docs/architecture.md:1045-1052` | 0, 1 | Existente |
| SPEC-ORG-02 | Configuración por sucursal: moneda, horarios, ticket | `docs/architecture.md:458-472`, DBML 133-142 | 1 | Existente |
| SPEC-ORG-03 | Usuarios asignados a una o varias sucursales | `docs/architecture.md:1046`, DBML 182-186 | 1 | Existente |
| SPEC-ORG-04 | Reportes por sucursal o consolidados | `docs/architecture.md:1047`, 406-428 | 7, futuro | Existente |
| SPEC-ORG-05 | Sucursal inactiva conserva historial | DBML 125-131 | 1 | Existente |
| SPEC-IAM-01 | Login con usuario y contraseña | `docs/architecture.md:797-804`, OpenAPI 450 | 1 | Existente |
| SPEC-IAM-02 | Expiración, renovación y revocación de tokens | `docs/architecture.md:801-803`, DBML 188-195 | 1 | Existente |
| SPEC-IAM-03 | Roles admin, manager y cashier | `README.md:64-68`, `docs/architecture.md:96-100` | 1 | Existente |
| SPEC-IAM-04 | Permisos y relación rol-permiso | `docs/architecture.md:810-835`, DBML 154-163 | 1 | Existente |
| SPEC-IAM-05 | Autorización en backend por usuario, permiso, sucursal y recurso | `docs/architecture.md:810-837` | 1, 2, 3, 5 | Existente |
| SPEC-IAM-06 | Reglas de cuentas compartidas | DBML 169-180 | 1 | Existente |
| SPEC-IAM-07 | Auditoría de operaciones relevantes | `docs/architecture.md:850-864`, DBML 197-206 | 1 | Existente |
| SPEC-CAT-01 | Tarifas por sucursal con precio por hora | `docs/architecture.md:155-174`, DBML 228-238 | 2 | Existente |
| SPEC-CAT-02 | Mesas con nombre, tarifa y estado | `docs/architecture.md:135-153`, DBML 240-249 | 2 | Existente |
| SPEC-CAT-03 | Categorías y productos con precio y stock | `docs/architecture.md:176-195`, DBML 317-333 | 2, 4 | Existente |
| SPEC-CAT-04 | Snapshots de precios y tarifas | `docs/architecture.md:712-726` | 2, 3, 4 | Existente |
| SPEC-CAT-05 | El administrador configura sin ayuda del desarrollador | `README.md:64-68`, `docs/architecture.md:520-537` | 2 | Existente |
| SPEC-CAT-06 | Clasificación por tipo de mesa | `docs/architecture.md:142` | 2, futuro | Pendiente D-03 |
| SPEC-SESSION-01 | Iniciar, pausar, reanudar y finalizar sesión | `docs/architecture.md:144-150`, OpenAPI 573-693 | 3 | Existente |
| SPEC-SESSION-02 | Modalidades tiempo libre y tiempo fijo | DBML 281-282, ADR-001 | 3 | Existente |
| SPEC-SESSION-03 | Cambio de mesa sin perder tiempo acumulado | `docs/architecture.md:145-148`, DBML 301-311 | 3 | Existente |
| SPEC-SESSION-04 | Una sola sesión activa o en pausa por mesa | DBML 291, `docs/architecture.md:772-774` | 3 | Existente, control en app |
| SPEC-SESSION-05 | El tiempo se calcula en el servidor con `Clock` | `docs/estructure.md:193`, 330 | 3 | Existente |
| SPEC-SESSION-06 | Historial y tarifa aplicada conservada | `docs/architecture.md:153`, 712-726 | 3 | Existente |
| SPEC-PRICING-01 | Cobro proporcional por minuto y dos decimales | ADR-001, `docs/architecture.md:174`, DBML 237 | 3 | Existente |
| SPEC-PRICING-02 | Sin fracciones de 15/30 ni redondeo a unidad | ADR-001 | 3 | Existente |
| SPEC-PRICING-03 | Regla de tiempo fijo, salida anticipada y exceso | DBML 282 | 3 | Pendiente D-04 |
| SPEC-PRICING-04 | Descuentos por porcentaje o monto fijo | DBML 450-466 | 3, futuro | Pendiente D-05 |
| SPEC-PRICING-05 | Promociones por día y tarifa | DBML 566-580 | Futuro | Futuro |
| SPEC-SALES-01 | Agregar y quitar consumos a una sesión activa | `docs/architecture.md:176-195`, DBML 335-344 | 4 | Existente |
| SPEC-SALES-02 | Descontar stock y registrar movimiento | `docs/architecture.md:237-255`, DBML 379-391 | 4 | Existente, mínimo |
| SPEC-SALES-03 | Cuenta = tiempo + consumos - descuento | DBML 412-430 | 4 | Existente, sin descuento en MVP |
| SPEC-SALES-04 | Pagos parciales y combinados | `docs/architecture.md:203-207`, DBML 432-442 | 5 | Existente |
| SPEC-CASH-01 | Apertura y cierre de turno de caja | `docs/architecture.md:215-233`, DBML 397-410 | 5 | Existente |
| SPEC-CASH-02 | Un solo turno abierto por sucursal | DBML 409, `docs/architecture.md:774` | 5 | Existente, control en app |
| SPEC-CASH-03 | Métodos de pago efectivo, QR y transferencia | `docs/architecture.md:203-207`, DBML 432-442 | 5 | Existente |
| SPEC-CASH-04 | Movimientos de caja: ingreso, retiro, gasto, devolución | DBML 472-485, `docs/architecture.md:225-232` | 5 | Existente |
| SPEC-CASH-05 | Efectivo esperado contra efectivo contado | `docs/architecture.md:229-232`, DBML 484 | 5 | Existente |
| SPEC-CASH-06 | Reporte de cierre por método y concepto | `docs/architecture.md:406-428`, 215-233 | 5, 7 | Parcial, detalle D-10 |
| SPEC-CASH-07 | Cada pago pertenece al turno en que se cobra | DBML 432-442, `docs/architecture.md:213` | 5 | Existente |
| SPEC-POS-01 | El cajero opera mesas, sesiones, ventas, pagos y caja | `docs/architecture.md:498-518` | 6 | Existente |
| SPEC-POS-02 | El POS usa el cliente Dart generado | `docs/architecture.md:539-550`, `docs/estructure.md:365-378` | 6 | Existente |
| SPEC-POS-03 | Permisos en UI y backend como fuente de verdad | `docs/architecture.md:518`, 835-837 | 6 | Existente |
| SPEC-NFR-01 | Atributos de calidad del sistema | `docs/architecture.md:1005-1023` | 0, 7 | Existente |
| SPEC-NFR-02 | Transacciones en operaciones multi-tabla | `docs/architecture.md:755-768` | 3, 4, 5 | Existente |
| SPEC-NFR-03 | Manejo de concurrencia | `docs/architecture.md:770-780` | 3, 5 | Existente, D-02 |
| SPEC-NFR-04 | Idempotencia en ventas, pagos y reembolsos | `docs/architecture.md:782-793` | 5, 7 | Existente |
| SPEC-NFR-05 | Auditoría protegida y sin secretos | `docs/architecture.md:850-864` | 1, 7 | Existente |
| SPEC-NFR-06 | Backups con RPO, RTO y restauración probada | `docs/architecture.md:952-973` | 7 | Existente |
| SPEC-NFR-07 | Logs, métricas y alertas | `docs/architecture.md:975-1003` | 0, 7 | Existente |
| SPEC-NFR-08 | Migraciones versionadas con goose | `docs/architecture.md:728-736` | 0 | Existente |
| SPEC-NFR-09 | Dinero decimal en base y dominio | `docs/architecture.md:700-710`, ADR-001 | 0, 3 | Existente |
| SPEC-NFR-10 | OpenAPI como contrato | `docs/architecture.md:657-682`, ADR-002 | 0-6 | Existente |
| SPEC-NFR-11 | Zona horaria y moneda por sucursal | `docs/architecture.md:458-472` | 2, 5, 7 | Parcial, D-13 |

---

## 4. Fases

### Fase 0: Fundaciones SDD y esqueleto ejecutable

#### 1. Objetivo

Dejar un punto de partida reproducible para desarrollar sin romper el esquema existente: SPECs aprobados, decisiones registradas, backend que arranca y CI mínima.

#### 2. Alcance y funcionalidades

- Crear `docs/specs/` con los SPEC del MVP.
- Crear ADR para las decisiones que bloquean F1, F3 y F5.
- Crear el esqueleto de `apps/api` con `cmd/server`, configuración, pool de PostgreSQL, logger, health check y apagado ordenado.
- Fijar el contrato de errores HTTP y el formato de respuesta.
- Configurar CI para build, lint, tests y migraciones.
- Verificar que goose, seed y sqlc funcionan.

No incluye: lógica de negocio, endpoints de usuarios, mesas, sesiones o caja.

#### 3. Requisitos relacionados (IDs de SPEC)

- SPEC-NFR-01, SPEC-NFR-07, SPEC-NFR-08, SPEC-NFR-09, SPEC-NFR-10.
- SPEC-ORG-01 como contexto de configuración.
- SPEC-IAM-01 como primer contrato a especificar, sin implementarlo.

#### 4. Tareas concretas y orden de ejecución

1. F0-T1: crear `docs/specs/` con un SPEC por módulo del MVP.
2. F0-T2: crear ADR-004 (autenticación), ADR-005 (concurrencia sin índices), ADR-006 (tiempo fijo) y ADR-007 (multi-tenant o negocio único). Aprobarlos antes de F1.
3. F0-T3: crear `apps/api/cmd/server/main.go`, configuración por entorno y logger estructurado.
4. F0-T4: crear pool `pgx`, health check de base de datos y endpoint `GET /health`.
5. F0-T5: crear middleware de request ID, recuperación de panics y respuesta de error común.
6. F0-T6: crear `apps/api/internal/infrastructure/bootstrap/app.go` como composition root.
7. F0-T7: agregar `make api-test` con un smoke test del health check.
8. F0-T8: configurar CI para `go build`, `go test`, `golangci-lint`, `goose up/down` y `sqlc generate`.
9. F0-T9: verificar que `make db-reset`, `make seed` y `make migrate-status` siguen funcionando.
10. F0-T10: documentar el flujo de trabajo SDD en `docs/specs/README.md`.

#### 5. Dependencias con otras fases

- Ninguna. Es la base de todas.

#### 6. Archivos o módulos afectados

- `docs/specs/`
- `docs/decisiones/ADR-004-*`, `ADR-005-*`, `ADR-006-*`, `ADR-007-*`
- `apps/api/cmd/server/`
- `apps/api/internal/infrastructure/platform/config/`
- `apps/api/internal/infrastructure/platform/database/`
- `apps/api/internal/infrastructure/platform/logger/`
- `apps/api/internal/infrastructure/bootstrap/`
- `apps/api/internal/presentation/http/`
- `Makefile`
- `.github/workflows/`
- `contracts/openapi.yaml` solo para `GET /health` si se decide publicarlo.

#### 7. Pruebas necesarias

- Smoke test del health check.
- Prueba de carga de configuración con variables válidas y faltantes.
- Prueba de conexión a PostgreSQL.
- Prueba de migración `up` y `down` en base limpia.
- Prueba de idempotencia del seed.
- `go build` y `golangci-lint`.

#### 8. Criterios de aceptación

- `make api-run` arranca el servidor.
- `GET /health` responde 200 con estado de la base.
- `make api-test` ejecuta al menos el smoke test.
- `make db-reset` deja la base en goose versión 9 y con el seed cargado.
- CI falla si build, lint, tests o migraciones fallan.
- Los ADR de D-01, D-02, D-04 y D-07 están aprobados.

#### 9. Definición de terminado (Definition of Done)

- SPECs creados y aprobados.
- ADR creados y aprobados.
- Esqueleto compila y arranca.
- Health check probado.
- CI verde.
- Documentación de arranque actualizada.

#### 10. Riesgos y consideraciones

- Riesgo de sobre-documentar. Mitigación: SPEC cortos, una página por módulo, con criterios de aceptación concretos.
- Riesgo de bloquear F1 por decisiones abiertas. Mitigación: resolver D-01 y D-07 en F0.
- Riesgo de agregar infraestructura innecesaria. Mitigación: solo configuración, logger, pool, health y CI.

---

### Fase 1: Identidad, sucursales y autorización

#### 1. Objetivo

Permitir que un usuario inicie sesión, reciba un token, elija una sucursal y opere solo dentro de los permisos y sucursales que le corresponden.

#### 2. Alcance y funcionalidades

- Login con usuario y contraseña.
- Refresh token y revocación.
- Logout.
- Lista de sucursales del usuario.
- Selección de sucursal y contexto de sucursal en el token.
- Middleware de autenticación y autorización por permiso.
- Reglas de cuentas compartidas.
- Registro de auditoría de login, logout y acciones administrativas.
- CRUD mínimo de usuarios y asignación de sucursales, solo para administrador.

No incluye: tarifas, mesas, sesiones, consumos, caja ni POS.

#### 3. Requisitos relacionados (IDs de SPEC)

- SPEC-IAM-01, SPEC-IAM-02, SPEC-IAM-03, SPEC-IAM-04, SPEC-IAM-05, SPEC-IAM-06, SPEC-IAM-07.
- SPEC-ORG-01, SPEC-ORG-02, SPEC-ORG-03, SPEC-ORG-05.
- SPEC-NFR-02, SPEC-NFR-03, SPEC-NFR-05, SPEC-NFR-09.

#### 4. Tareas concretas y orden de ejecución

1. F1-T1: aprobar SPEC-IAM y SPEC-ORG con criterios de aceptación.
2. F1-T2: crear entidades y value objects de dominio: `User`, `Role`, `Permission`, `Branch`, `PasswordHash`, `Token`.
3. F1-T3: crear pruebas unitarias de hash de contraseña y reglas de cuenta compartida.
4. F1-T4: crear puertos y casos de uso: `Login`, `Refresh`, `Logout`, `ListBranches`, `SelectBranch`, `CreateUser`, `AssignBranches`.
5. F1-T5: escribir consultas sqlc para usuario por username, permisos por rol, sucursales por usuario, refresh tokens y auditoría.
6. F1-T6: implementar repositorios PostgreSQL y pruebas de integración.
7. F1-T7: implementar firma y verificación de tokens, middleware de autenticación y middleware de permisos.
8. F1-T8: implementar handlers HTTP, mapeo de errores y rutas de auth, usuarios y sucursales.
9. F1-T9: actualizar `contracts/openapi.yaml` y regenerar el cliente Dart cuando exista el script.
10. F1-T10: registrar auditoría y verificar el flujo completo con el seed `admin`.

#### 5. Dependencias con otras fases

- Depende de Fase 0.
- Bloquea Fase 2, Fase 3, Fase 4 y Fase 5.

#### 6. Archivos o módulos afectados

- `apps/api/internal/domain/users/`
- `apps/api/internal/domain/auth/`
- `apps/api/internal/domain/branches/`
- `apps/api/internal/application/auth/`
- `apps/api/internal/application/users/`
- `apps/api/internal/application/branches/`
- `apps/api/internal/infrastructure/postgres/auth/`
- `apps/api/internal/infrastructure/postgres/users/`
- `apps/api/internal/infrastructure/postgres/branches/`
- `apps/api/internal/infrastructure/platform/auth/`
- `apps/api/internal/presentation/http/auth/`
- `apps/api/internal/presentation/http/users/`
- `apps/api/internal/presentation/http/branches/`
- `apps/api/db/queries/auth.sql`
- `apps/api/db/queries/users.sql`
- `apps/api/db/queries/branches.sql`
- `contracts/openapi.yaml`
- `apps/api/db/seeds/0002_bootstrap.sql`

#### 7. Pruebas necesarias

- Unitarias: hash de contraseña, token expirado, token revocado, reglas de cuenta compartida.
- Aplicación: login correcto, login inválido, refresh válido, refresh revocado, lista de sucursales.
- Integración: consultas de usuario, permisos y sucursales contra PostgreSQL.
- Handlers: 200, 400, 401, 403, 404 y 409.
- Seguridad: usuario sin permiso no accede, usuario de otra sucursal no accede.
- Auditoría: login y acción administrativa generan registro.

#### 8. Criterios de aceptación

- `admin` puede iniciar sesión con la contraseña del seed de desarrollo.
- El login devuelve token, usuario y lista de sucursales.
- Un usuario con varias sucursales puede elegir una y el token incluye el `branchId`.
- Un usuario sin permiso recibe 403.
- Un usuario sin acceso a una sucursal recibe 403.
- El refresh token rota y el token anterior queda revocado.
- Logout revoca el refresh token.
- Las acciones administrativas quedan en `audit_logs`.
- El contrato OpenAPI coincide con la implementación.

#### 9. Definición de terminado (Definition of Done)

- SPEC y ADR de autenticación aprobados.
- Endpoints implementados y documentados.
- Pruebas unitarias, de aplicación, integración y handlers en verde.
- OpenAPI actualizado.
- Seed de admin verificado.
- Auditoría registrada.
- Sin contraseñas ni secretos en logs.
- Revisión de seguridad completada.

#### 10. Riesgos y consideraciones

- Riesgo de elegir un esquema de tokens que no permita revocación. Mitigación: ADR-004 y refresh tokens hasheados.
- Riesgo de fuga entre sucursales. Mitigación: middleware de sucursal y pruebas de aislamiento.
- Riesgo de cuentas compartidas sin responsable. Mitigación: `responsible_name` y permisos restringidos.
- Riesgo de bloqueo por D-07. Mitigación: decidir si el MVP es un negocio por despliegue.

---

### Fase 2: Catálogo de tarifas, mesas y productos

#### 1. Objetivo

Permitir que el administrador configure la operación básica: tarifas, mesas, categorías y productos.

#### 2. Alcance y funcionalidades

- CRUD de tarifas por sucursal.
- CRUD de mesas con tarifa y estado.
- CRUD de categorías y productos.
- Campos de baja lógica o `active` si se aprueba D-06.
- Validación de nombres únicos por sucursal.
- Asignación de tarifa de la misma sucursal.
- Snapshot de precio en la venta, no en el catálogo.

No incluye: sesiones, consumos, caja ni inventario completo.

#### 3. Requisitos relacionados (IDs de SPEC)

- SPEC-CAT-01, SPEC-CAT-02, SPEC-CAT-03, SPEC-CAT-04, SPEC-CAT-05.
- SPEC-ORG-01, SPEC-IAM-05.
- SPEC-NFR-09, SPEC-NFR-10.

#### 4. Tareas concretas y orden de ejecución

1. F2-T1: aprobar SPEC-CAT y resolver D-03 y D-06.
2. F2-T2: crear entidades de dominio `Rate`, `Table`, `Product`, `ProductCategory`.
3. F2-T3: crear reglas de validación: precio positivo, nombre único por sucursal, tarifa de la misma sucursal, estado válido.
4. F2-T4: crear casos de uso de creación, edición, listado y baja lógica.
5. F2-T5: escribir consultas sqlc y repositorios PostgreSQL.
6. F2-T6: implementar handlers HTTP y rutas de tarifas, mesas, categorías y productos.
7. F2-T7: actualizar OpenAPI con los endpoints administrativos faltantes.
8. F2-T8: agregar pruebas de aislamiento por sucursal y permisos.
9. F2-T9: actualizar DBML y SQL si D-03 o D-06 agregan columnas o tablas.
10. F2-T10: verificar que el seed de tarifa y mesa sigue funcionando.

#### 5. Dependencias con otras fases

- Depende de Fase 1.
- Bloquea Fase 3 y Fase 4.

#### 6. Archivos o módulos afectados

- `apps/api/internal/domain/rates/`
- `apps/api/internal/domain/tables/`
- `apps/api/internal/domain/products/`
- `apps/api/internal/application/rates/`
- `apps/api/internal/application/tables/`
- `apps/api/internal/application/products/`
- `apps/api/internal/infrastructure/postgres/rates/`
- `apps/api/internal/infrastructure/postgres/tables/`
- `apps/api/internal/infrastructure/postgres/products/`
- `apps/api/internal/presentation/http/rates/`
- `apps/api/internal/presentation/http/tables/`
- `apps/api/internal/presentation/http/products/`
- `apps/api/db/queries/rates.sql`
- `apps/api/db/queries/tables.sql`
- `apps/api/db/queries/products.sql`
- `apps/api/db/migrations/` si cambia el esquema
- `docs/billiards_modelo.dbml` si cambia el esquema
- `contracts/openapi.yaml`

#### 7. Pruebas necesarias

- Unitarias: validación de precio, nombre, estado y tarifa.
- Aplicación: crear, editar, listar y desactivar.
- Integración: unicidad por sucursal, FK de tarifa, aislamiento por sucursal.
- Handlers: 201, 200, 400, 403, 404, 409.
- Contrato: esquemas y ejemplos de OpenAPI.
- Regresión: el seed sigue creando una tarifa y una mesa.

#### 8. Criterios de aceptación

- El administrador crea una tarifa de 15.00 por hora.
- El administrador crea una mesa asociada a esa tarifa.
- El administrador crea una categoría y un producto con precio.
- Un cajero no puede crear ni editar tarifas, mesas o productos.
- Un administrador de otra sucursal no puede ver ni editar estos datos.
- No se puede crear una mesa con una tarifa de otra sucursal.
- Los nombres son únicos dentro de la sucursal.
- El producto o la tarifa desactivada no aparece en el POS.

#### 9. Definición de terminado (Definition of Done)

- SPEC-CAT aprobado.
- D-03 y D-06 resueltas.
- Endpoints implementados y documentados.
- Pruebas en verde.
- OpenAPI actualizado.
- DBML y SQL sincronizados si hubo cambio.
- Seed verificado.

#### 10. Riesgos y consideraciones

- Riesgo de mezclar tipo de mesa con tarifa. Mitigación: D-03 y una sola fuente de clasificación.
- Riesgo de no poder retirar productos usados. Mitigación: D-06 y baja lógica.
- Riesgo de que el catálogo crezca sin control. Mitigación: paginación y filtros en el contrato.

### Fase 3: Sesiones y motor de cobro por tiempo

#### 1. Objetivo

Permitir que el cajero abra, pause, reanude, cambie de mesa y finalice una sesión, con un cobro correcto por tiempo.

#### 2. Alcance y funcionalidades

- Iniciar sesión en una mesa libre.
- Modo tiempo libre y tiempo fijo.
- Pausar y reanudar.
- Cambiar de mesa sin perder tiempo acumulado.
- Calcular el cobro por minuto con dos decimales.
- Guardar la tarifa aplicada al iniciar.
- Crear la cuenta al finalizar, sin pagos.
- Bloquear doble sesión por mesa a nivel de aplicación.
- Registrar eventos de auditoría.

No incluye: consumos, pagos, cierre de caja ni descuentos.

#### 3. Requisitos relacionados (IDs de SPEC)

- SPEC-SESSION-01 a SPEC-SESSION-06.
- SPEC-PRICING-01, SPEC-PRICING-02, SPEC-PRICING-03.
- SPEC-CAT-04, SPEC-NFR-02, SPEC-NFR-03, SPEC-NFR-09.

#### 4. Tareas concretas y orden de ejecución

1. F3-T1: aprobar SPEC-SESSION y SPEC-PRICING.
2. F3-T2: resolver D-02, D-04 y D-05.
3. F3-T3: implementar el dominio de pricing con pruebas antes del resto.
4. F3-T4: implementar la máquina de estados de sesión y sus pruebas.
5. F3-T5: implementar `Clock` y pruebas con tiempo controlado.
6. F3-T6: implementar casos de uso de iniciar, pausar, reanudar, cambiar mesa y finalizar.
7. F3-T7: implementar la transacción de inicio con bloqueo de mesa para evitar doble sesión.
8. F3-T8: implementar la transacción de finalización y la creación de cuenta con snapshot de tarifa.
9. F3-T9: escribir consultas sqlc y repositorios PostgreSQL.
10. F3-T10: implementar handlers HTTP, actualizar OpenAPI y pruebas de integración.

#### 5. Dependencias con otras fases

- Depende de Fase 2.
- Bloquea Fase 4 y Fase 5.

#### 6. Archivos o módulos afectados

- `apps/api/internal/domain/sessions/`
- `apps/api/internal/domain/pricing/`
- `apps/api/internal/domain/tables/`
- `apps/api/internal/application/sessions/`
- `apps/api/internal/infrastructure/postgres/sessions/`
- `apps/api/internal/presentation/http/sessions/`
- `apps/api/db/queries/sessions.sql`
- `apps/api/db/migrations/` si D-02 o D-06 lo requieren
- `docs/billiards_modelo.dbml` si cambia el esquema
- `contracts/openapi.yaml`

#### 7. Pruebas necesarias

- Unitarias de pricing: 15 Bs/h por 30 min = 7.50; 20 min = 5.00; 1 min = 0.25.
- Unitarias de pausas: 60 min con 10 min de pausa = 50 min cobrados.
- Unitarias de cambio de mesa: suma de tramos sin perder tiempo.
- Unitarias de estado: no pausar dos veces, no reanudar una sesión activa, no finalizar dos veces.
- Integración: dos inicios concurrentes en la misma mesa, solo uno gana.
- Integración: la cuenta se crea una sola vez y guarda tarifa y montos.
- Handlers: 201, 200, 400, 403, 404, 409.
- Regresión: cambiar la tarifa después no altera una sesión finalizada.

#### 8. Criterios de aceptación

- Una sesión de 30 minutos a 15.00 por hora cobra 7.50.
- Una sesión pausada no cobra el tiempo de pausa.
- Un cambio de mesa conserva el tiempo y el monto acumulado.
- Dos solicitudes simultáneas para abrir la misma mesa no crean dos sesiones.
- Finalizar una sesión crea una cuenta con `time_amount`, `total_amount` y tarifa snapshot.
- Una sesión finalizada no se puede pausar ni finalizar de nuevo.
- El cronómetro del cliente es solo visual y el servidor es la fuente de verdad.
- El contrato OpenAPI coincide con la implementación.

#### 9. Definición de terminado (Definition of Done)

- SPEC y ADR de pricing aprobados.
- D-02, D-04 y D-05 resueltas.
- Dominio de pricing y sesión con pruebas.
- Casos de uso y handlers implementados.
- Transacciones y concurrencia probadas.
- OpenAPI actualizado.
- Auditoría registrada.
- DBML y SQL sincronizados si hubo cambio.

#### 10. Riesgos y consideraciones

- Riesgo de redondeo incorrecto. Mitigación: cálculo por minuto, redondeo una sola vez, pruebas de borde.
- Riesgo de doble sesión sin índice único. Mitigación: bloqueo de fila o advisory lock y prueba concurrente.
- Riesgo de tiempo fijo ambiguo. Mitigación: D-04 antes de implementar.
- Riesgo de zona horaria. Mitigación: guardar timestamps en UTC y mostrar en la zona de la sucursal.
- Riesgo de descuentos fuera de alcance. Mitigación: D-05 y no implementarlos hasta aprobación.

---

### Fase 4: Consumos y cuenta

#### 1. Objetivo

Permitir agregar y quitar consumos de una sesión activa, actualizar la cuenta y registrar el movimiento de stock.

#### 2. Alcance y funcionalidades

- Agregar consumo con producto, cantidad y precio snapshot.
- Quitar o ajustar un consumo mientras la sesión está activa.
- Descontar stock mediante un movimiento de inventario.
- Calcular `consumptions_amount` y `total_amount` de la cuenta.
- Rechazar consumos en sesiones finalizadas o anuladas.
- Registrar auditoría.

No incluye: compras, proveedores, inventario completo ni ajustes manuales de stock.

#### 3. Requisitos relacionados (IDs de SPEC)

- SPEC-SALES-01, SPEC-SALES-02, SPEC-SALES-03.
- SPEC-CAT-03, SPEC-CAT-04.
- SPEC-NFR-02, SPEC-NFR-03.

#### 4. Tareas concretas y orden de ejecución

1. F4-T1: aprobar SPEC-SALES.
2. F4-T2: crear entidad `Consumption` y reglas de cantidad y sesión activa.
3. F4-T3: crear el puerto de inventario y el movimiento de stock mínimo.
4. F4-T4: implementar el caso de uso `AddConsumption` dentro de una transacción.
5. F4-T5: implementar `RemoveConsumption` y la reversión del stock.
6. F4-T6: actualizar la cuenta con el total de consumos.
7. F4-T7: escribir consultas sqlc y repositorios.
8. F4-T8: implementar handlers y actualizar OpenAPI.
9. F4-T9: agregar pruebas de concurrencia de stock.
10. F4-T10: verificar que la sesión finalizada rechaza consumos.

#### 5. Dependencias con otras fases

- Depende de Fase 3.
- Bloquea Fase 5 y Fase 6.

#### 6. Archivos o módulos afectados

- `apps/api/internal/domain/consumptions/`
- `apps/api/internal/domain/inventory/`
- `apps/api/internal/application/consumptions/`
- `apps/api/internal/infrastructure/postgres/consumptions/`
- `apps/api/internal/infrastructure/postgres/inventory/`
- `apps/api/internal/presentation/http/consumptions/`
- `apps/api/db/queries/consumptions.sql`
- `apps/api/db/queries/inventory.sql`
- `contracts/openapi.yaml`

#### 7. Pruebas necesarias

- Unitarias: cantidad positiva, producto activo, sesión activa.
- Aplicación: agregar, quitar y recalcular total.
- Integración: stock antes y después, movimiento de inventario, transacción completa.
- Concurrencia: dos consumos simultáneos no dejan stock negativo sin control.
- Handlers: 201, 200, 400, 403, 404, 409.
- Regresión: el precio del producto cambia y el consumo mantiene el snapshot.

#### 8. Criterios de aceptación

- Agregar 2 bebidas de 2.50 suma 5.00 a la cuenta.
- El stock baja en 2 y queda un movimiento de inventario.
- Quitar el consumo revierte el total y el stock.
- No se puede consumir en una sesión finalizada.
- El precio del consumo es el precio al momento de la venta.
- La cuenta se actualiza en la misma transacción.

#### 9. Definición de terminado (Definition of Done)

- SPEC-SALES aprobado.
- Dominio, aplicación, infraestructura y presentación implementados.
- Pruebas en verde.
- OpenAPI actualizado.
- Auditoría registrada.
- DBML y SQL sincronizados si hubo cambio.

#### 10. Riesgos y consideraciones

- Riesgo de stock negativo por concurrencia. Mitigación: bloqueo o actualización atómica y pruebas.
- Riesgo de productos retirados. Mitigación: D-06 y baja lógica.
- Riesgo de que el ledger de inventario se desincronice. Mitigación: una transacción y un movimiento por consumo.

---

### Fase 5: Caja, pagos y cierre de turno

#### 1. Objetivo

Permitir abrir un turno, cobrar una cuenta con uno o varios pagos y cerrar el turno con efectivo esperado contra efectivo contado.

#### 2. Alcance y funcionalidades

- Abrir turno con fondo inicial.
- Un solo turno abierto por sucursal, controlado en aplicación.
- Registrar pagos en efectivo, QR o transferencia.
- Pagos parciales y combinados.
- Vincular cada pago al turno en que se cobra.
- Registrar movimientos de caja.
- Calcular efectivo esperado.
- Cerrar turno con efectivo contado y diferencia.
- Reporte de cierre por método y concepto.
- Idempotencia de pagos.

No incluye: gastos, compras, prepago, créditos, promociones ni reportes históricos avanzados.

#### 3. Requisitos relacionados (IDs de SPEC)

- SPEC-CASH-01 a SPEC-CASH-07.
- SPEC-SALES-04.
- SPEC-NFR-02, SPEC-NFR-03, SPEC-NFR-04.

#### 4. Tareas concretas y orden de ejecución

1. F5-T1: aprobar SPEC-CASH y resolver D-09 y D-10.
2. F5-T2: crear entidades `CashShift`, `Payment`, `CashMovement` y reglas de estado.
3. F5-T3: implementar apertura de turno con bloqueo por sucursal.
4. F5-T4: implementar registro de pago con validación de total y saldo.
5. F5-T5: implementar idempotencia de pagos.
6. F5-T6: implementar movimientos de caja y cálculo de efectivo esperado.
7. F5-T7: implementar cierre de turno y reporte por método y concepto.
8. F5-T8: escribir consultas sqlc y repositorios.
9. F5-T9: implementar handlers y actualizar OpenAPI.
10. F5-T10: pruebas de concurrencia, idempotencia y conciliación.

#### 5. Dependencias con otras fases

- Depende de Fase 3 y Fase 4.
- Bloquea Fase 6 y el flujo completo del MVP.

#### 6. Archivos o módulos afectados

- `apps/api/internal/domain/cash/`
- `apps/api/internal/domain/payments/`
- `apps/api/internal/application/cash/`
- `apps/api/internal/infrastructure/postgres/cash/`
- `apps/api/internal/infrastructure/postgres/payments/`
- `apps/api/internal/presentation/http/cash/`
- `apps/api/db/queries/cash.sql`
- `apps/api/db/queries/payments.sql`
- `contracts/openapi.yaml`

#### 7. Pruebas necesarias

- Unitarias: transiciones de turno, pago no mayor al saldo, pago parcial, cierre.
- Aplicación: abrir, pagar, cerrar y reporte.
- Integración: pago ligado al turno, efectivo esperado, diferencia.
- Concurrencia: dos aperturas simultáneas, solo una gana.
- Idempotencia: mismo request repetido no duplica pago.
- Handlers: 200, 201, 400, 403, 404, 409.
- E2E de backend: sesión, consumo, cuenta, pago y cierre.

#### 8. Criterios de aceptación

- El cajero abre un turno con 50.00 de fondo.
- No se puede abrir un segundo turno en la misma sucursal.
- Un pago en efectivo se registra en el turno actual.
- Un pago parcial deja la cuenta pendiente; el pago final la marca pagada.
- Dos pagos simultáneos no exceden el total.
- El cierre calcula esperado, contado y diferencia.
- El reporte muestra totales por método y por concepto.
- Un reintento con la misma clave de idempotencia no duplica el pago.

#### 9. Definición de terminado (Definition of Done)

- SPEC-CASH aprobado.
- D-09 y D-10 resueltas.
- Dominio, aplicación, infraestructura y presentación implementados.
- Pruebas en verde.
- OpenAPI actualizado.
- Auditoría registrada.
- Reporte de cierre documentado.
- Flujo de backend completo probado.

#### 10. Riesgos y consideraciones

- Riesgo de caja descuadrada. Mitigación: pago ligado al turno y un libro de caja.
- Riesgo de doble pago por reintento. Mitigación: idempotencia.
- Riesgo de doble turno sin índice único. Mitigación: bloqueo en aplicación y prueba concurrente.
- Riesgo de reporte incompleto. Mitigación: D-10 antes de implementar.
- Riesgo de mezclar ventas con recargas o créditos. Mitigación: dejar esas funciones fuera del MVP.

---

### Fase 6: POS mínimo

#### 1. Objetivo

Permitir que el cajero complete el flujo del MVP desde la app Flutter.

#### 2. Alcance y funcionalidades

- Login y selección de sucursal.
- Mapa de mesas con estado.
- Abrir, pausar, reanudar, cambiar y finalizar sesión.
- Cronómetro visual.
- Agregar y quitar consumos.
- Cobrar con uno o varios métodos.
- Abrir y cerrar turno.
- Manejo de errores y estados vacíos.
- Guards por rol.

No incluye: clientes, reservas, inventario completo, reportes avanzados, offline ni Web Admin.

#### 3. Requisitos relacionados (IDs de SPEC)

- SPEC-POS-01, SPEC-POS-02, SPEC-POS-03.
- SPEC-IAM-01, SPEC-IAM-05.
- SPEC-SESSION-01 a SPEC-SESSION-05.
- SPEC-SALES-01, SPEC-CASH-01, SPEC-CASH-03, SPEC-CASH-05.

#### 4. Tareas concretas y orden de ejecución

1. F6-T1: aprobar SPEC-POS y resolver D-12.
2. F6-T2: generar `packages/api_client` desde OpenAPI y crear `scripts/gen-client.sh`.
3. F6-T3: configurar router, tema, DI y cliente HTTP.
4. F6-T4: implementar login y selección de sucursal.
5. F6-T5: implementar mapa de mesas y estado en tiempo real o refresco.
6. F6-T6: implementar pantalla de sesión con cronómetro y acciones.
7. F6-T7: implementar consumos y cuenta.
8. F6-T8: implementar cobro y cierre de turno.
9. F6-T9: implementar guards, mensajes de error y estados de carga.
10. F6-T10: pruebas de widgets e integración del turno completo.

#### 5. Dependencias con otras fases

- Depende de Fase 1 a Fase 5.
- Bloquea la demostración del MVP.

#### 6. Archivos o módulos afectados

- `apps/pos/lib/domain/`
- `apps/pos/lib/application/`
- `apps/pos/lib/infrastructure/`
- `apps/pos/lib/presentation/`
- `apps/pos/lib/main.dart`
- `apps/pos/lib/app.dart`
- `packages/api_client/`
- `scripts/gen-client.sh`
- `contracts/openapi.yaml`
- `apps/pos/test/`
- `apps/pos/integration_test/`

#### 7. Pruebas necesarias

- Widget tests de login, mesas, sesión, consumos, cobro y cierre.
- Pruebas de estado con repositorios falsos.
- Pruebas de mapeo de modelos del cliente.
- Integration test del turno completo.
- Prueba de error de red y reintento.
- Prueba de guard por rol.

#### 8. Criterios de aceptación

- El cajero inicia sesión y elige sucursal.
- El cajero ve las mesas y sus estados.
- El cajero abre una sesión y ve el cronómetro.
- El cajero agrega un consumo y el total se actualiza.
- El cajero finaliza y cobra.
- El cajero cierra el turno y ve el resumen.
- Un usuario sin permiso no ve acciones administrativas.
- El flujo completo funciona en la plataforma definida en D-12.

#### 9. Definición de terminado (Definition of Done)

- SPEC-POS aprobado.
- Cliente Dart generado y versionado.
- Pantallas implementadas.
- Pruebas en verde.
- Integration test del turno completo.
- Manual de uso mínimo.
- Demo aceptada.

#### 10. Riesgos y consideraciones

- Riesgo de UI demasiado ambiciosa. Mitigación: solo el flujo del MVP.
- Riesgo de que el cronómetro del cliente sea la fuente de verdad. Mitigación: servidor como fuente.
- Riesgo de red inestable. Mitigación: estados de error, reintento e idempotencia.
- Riesgo de plataforma no definida. Mitigación: D-12 antes de F6.
- Riesgo de que el cliente generado se edite a mano. Mitigación: regla de no edición y regeneración.

---

### Fase 7: Endurecimiento y release

#### 1. Objetivo

Preparar el MVP para operar de forma estable, segura y recuperable en un entorno real.

#### 2. Alcance y funcionalidades

- Reportes del MVP: cierre de turno, ventas y caja.
- Idempotencia completa en pagos y operaciones críticas.
- Auditoría protegida.
- Backups y restauración probada.
- Observabilidad: logs, métricas y alertas.
- Seguridad: rate limiting, headers, revisión de secretos.
- Rendimiento: medición y decisión de índices.
- CI/CD y despliegue a staging.
- Runbook de operación.

No incluye: nuevas funciones de negocio.

#### 3. Requisitos relacionados (IDs de SPEC)

- SPEC-NFR-01, SPEC-NFR-04, SPEC-NFR-05, SPEC-NFR-06, SPEC-NFR-07.
- SPEC-ORG-04, SPEC-CASH-06.
- SPEC-CAT-05.

#### 4. Tareas concretas y orden de ejecución

1. F7-T1: aprobar D-08, D-11 y D-14.
2. F7-T2: implementar reportes de cierre, ventas y caja.
3. F7-T3: implementar idempotencia en todos los pagos.
4. F7-T4: proteger auditoría contra update/delete.
5. F7-T5: medir consultas y decidir índices.
6. F7-T6: configurar backups, retención y prueba de restauración.
7. F7-T7: configurar logs, métricas y alertas.
8. F7-T8: configurar CI/CD y despliegue a staging.
9. F7-T9: revisión de seguridad y secretos.
10. F7-T10: escribir runbook y checklist de release.

#### 5. Dependencias con otras fases

- Depende de Fase 6.
- Cierra el MVP.

#### 6. Archivos o módulos afectados

- `apps/api/internal/application/reports/`
- `apps/api/internal/presentation/http/reports/`
- `apps/api/db/queries/reports.sql`
- `apps/api/db/migrations/` si se aprueban índices o triggers
- `docs/billiards_modelo.dbml` si cambia el esquema
- `infra/`
- `.github/workflows/`
- `docs/runbook.md`
- `contracts/openapi.yaml`

#### 7. Pruebas necesarias

- Pruebas de reportes con datos conocidos.
- Pruebas de idempotencia.
- Pruebas de restauración de backup.
- Pruebas de carga con datos representativos.
- Pruebas de seguridad y autorización.
- Smoke test post-deploy.
- Prueba de migración en staging.

#### 8. Criterios de aceptación

- El reporte de cierre coincide con los pagos y movimientos.
- Un reintento de pago no duplica.
- La auditoría no se puede modificar desde la aplicación.
- Un backup se restaura en un entorno limpio.
- Logs y métricas muestran salud del servicio.
- El despliegue a staging funciona y el smoke test pasa.
- La política de índices está documentada y aprobada.

#### 9. Definición de terminado (Definition of Done)

- Reportes implementados.
- Idempotencia y auditoría probadas.
- Backup y restauración probados.
- Observabilidad activa.
- Staging desplegado.
- Runbook y checklist de release.
- Riesgos residuales documentados.

#### 10. Riesgos y consideraciones

- Riesgo de agregar índices sin medir. Mitigación: D-08 y pruebas de carga.
- Riesgo de backup no restaurable. Mitigación: prueba de restauración.
- Riesgo de secretos en el repositorio. Mitigación: revisión y variables de entorno.
- Riesgo de alcance tardío. Mitigación: no agregar funciones de negocio en esta fase.

---

## 5. Grafo de dependencias y orden de ejecución

```
F0 Fundaciones
  +-> F1 Identidad y sucursales
        +-> F2 Catálogo
        |     +-> F3 Sesiones y pricing
        |           +-> F4 Consumos y cuenta
        |           +-> F5 Caja, pagos y cierre
        |                 +-> F6 POS mínimo
        |                       +-> F7 Endurecimiento y release
        +-> (F5 también depende de F3 y F4)
```

Orden de ejecución:

1. F0.
2. F1.
3. F2.
4. F3.
5. F4.
6. F5.
7. F6.
8. F7.

Reglas de avance:

- No se empieza una fase sin cerrar la anterior.
- No se empieza una tarea de código sin SPEC aprobado.
- Si una decisión pendiente bloquea la fase, se resuelve antes de la primera tarea de código.
- Si aparece un requisito nuevo, se abre un SPEC y se detiene la implementación.

---

## 6. Roadmap post-MVP

Estas fases no están aprobadas ni detalladas. Se planificarán después de validar el MVP y tendrán su propio SPEC.

| Orden | Módulo | Depende de | Disparador |
|---|---|---|---|
| 1 | Clientes y reservas | F5 | MVP estable y demanda de reservas |
| 2 | Inventario y compras | F4 | Necesidad de stock confiable y costos |
| 3 | Gastos y reportes financieros | F5 | Necesidad de ganancia neta |
| 4 | Prepago, créditos y promociones | F5 | Demanda de fidelización y fiado |
| 5 | Torneos | F3 | Demanda de torneos |
| 6 | Web Admin | F1-F5 | Necesidad de administración fuera del POS |
| 7 | Multi-tenant y multi-sucursal avanzado | F1, F7 | Varias cadenas o negocios |
| 8 | Offline y hardware | F6 | Conectividad inestable o impresoras |

Regla: no se implementa ninguna de estas fases sin un SPEC aprobado y sin validar antes el flujo del MVP.

---

## 7. Registro de riesgos

| ID | Riesgo | Probabilidad | Impacto | Mitigación | Fase |
|---|---|---|---|---|---|
| R-01 | Cobro por tiempo incorrecto | Media | Alto | ADR-001, pruebas de dominio y ejemplos de aceptación | 3 |
| R-02 | Doble sesión o doble caja | Media | Alto | Bloqueos en transacción y pruebas concurrentes | 3, 5 |
| R-03 | Fuga de datos entre sucursales | Media | Alto | Middleware, consultas filtradas y pruebas | 1-5 |
| R-04 | Caja descuadrada | Media | Alto | Pago ligado a turno, libro de caja y pruebas | 5 |
| R-05 | Alcance demasiado grande | Alta | Alto | ADR-003, fases con gate y F2-F7 fuera del MVP | Todas |
| R-06 | Falta de pruebas | Alta | Medio | F0 con CI y pirámide de pruebas | 0-7 |
| R-07 | Autenticación insegura | Baja | Alto | ADR, librerías estándar, revisión de seguridad | 1, 7 |
| R-08 | Documentos y esquema desalineados | Media | Medio | ADR-002 y checklist de cambio | Todas |
| R-09 | Sin índices y consultas lentas | Media | Medio | Medir en F7 y decidir con datos | 7 |
| R-10 | Cuenta compartida sin responsable | Media | Medio | `responsible_name`, permisos y auditoría | 1 |
| R-11 | Multi-tenant retroactivo | Baja | Alto | D-07 antes de F1 | 1, 7 |
| R-12 | Contraseña de seed en producción | Media | Alto | Cambiar antes de desplegar y bootstrap seguro | 7 |
| R-13 | Tiempo fijo ambiguo | Alta | Medio | D-04 antes de F3 | 3 |
| R-14 | POS en plataforma equivocada | Media | Medio | D-12 antes de F6 | 6 |
| R-15 | Backup no restaurable | Baja | Alto | Prueba de restauración en F7 | 7 |

---

## 8. Decisiones que bloquean fases

| Fase | Decisión | Efecto si no se resuelve |
|---|---|---|
| F1 | D-01 autenticación, D-07 multi-tenant | No se puede implementar login ni contexto de sucursal |
| F2 | D-03 tipos de mesa, D-06 baja lógica | No se puede cerrar el catálogo |
| F3 | D-02 concurrencia, D-04 tiempo fijo, D-05 descuentos | No se puede implementar sesiones sin ambigüedad |
| F5 | D-09 libro de caja, D-10 reporte de cierre | No se puede cerrar caja con criterio verificable |
| F6 | D-12 plataforma del POS | No se puede elegir la UI y el empaquetado |
| F7 | D-08 índices, D-11 credenciales, D-14 auditoría | No se puede cerrar el release |

---

## 9. Definition of Done global del MVP

El MVP se considera terminado cuando:

- El flujo completo funciona: login, sucursal, abrir turno, abrir sesión, consumo, finalizar, cobrar y cerrar turno.
- El cobro por tiempo coincide con ADR-001 en todos los casos probados.
- No se puede abrir dos veces la misma mesa ni dos turnos en la misma sucursal.
- Los pagos quedan ligados al turno y la caja cierra con esperado, contado y diferencia.
- Un usuario sin permiso o sin sucursal recibe 403.
- OpenAPI y el cliente Dart están sincronizados.
- DBML y SQL coinciden en estructura.
- Las pruebas unitarias, de integración, de handlers y el e2e del turno pasan.
- El backup se restauró al menos una vez en un entorno limpio.
- El runbook de operación está escrito.
- No hay decisiones bloqueantes sin resolver.

---

## 10. Primeros cinco días sugeridos

Día 1:

- Crear `docs/specs/` y los SPEC de IAM, ORG y NFR.
- Abrir los ADR de autenticación, concurrencia y multi-tenant.

Día 2:

- Aprobar los ADR y los SPEC de F0 y F1.
- Crear el esqueleto del backend y el health check.

Día 3:

- Configurar CI, `make api-test` y el smoke test.
- Verificar migraciones, seed y sqlc.

Día 4:

- Empezar el dominio de usuarios, roles y sucursales.
- Escribir las pruebas unitarias de contraseña y cuenta compartida.

Día 5:

- Implementar el login y la lista de sucursales.
- Revisar el flujo con el usuario `admin` del seed.
- Actualizar `IMPLEMENTATION_PLAN.md` con el estado real.

---

## Apéndice A: Lo que ya existe y no se debe reconstruir

- Las 9 migraciones goose y el esquema de 38 tablas.
- Los seeds de roles y bootstrap.
- Los ADR 001 a 003.
- La estructura de documentación y el DBML.
- El contrato OpenAPI base con 16 rutas.
- El `Makefile`, el compose de PostgreSQL y el entorno Nix.
- La app Flutter por defecto, que se reemplaza de forma incremental.

## Apéndice B: Lo que falta y no se debe olvidar

- `apps/api/cmd/server`
- `apps/api/internal/`
- `apps/api/db/queries/*.sql`
- `packages/api_client`
- `scripts/gen-client.sh`
- `infra/docker/api.Dockerfile`
- Servicio de API en el compose
- CI
- Pruebas
- Reportes
- Backups y runbook

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|---|---|---|---|---|---|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | - | - |
| Outside Review | no ejecutado | Independent 2nd opinion | 0 | NOT RUN | - |
| Eng Review | `/plan-eng-review` | Architecture & tests | 1 | ISSUES OPEN | 15 findings, 5 critical gaps |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | - | - |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | - | - |

**OUTSIDE COVERAGE:** no ejecutada en esta revisión. La revisión se basó en los documentos y en el estado del repositorio.

**VERDICT:** ENG REVIEW ISSUES OPEN. El plan está listo para aprobación, pero las decisiones pendientes bloquean F1, F2, F3, F5, F6 y F7. eng review required.

**UNRESOLVED DECISIONS:**
- D-01: definir el mecanismo de autenticación y el ciclo de tokens antes de F1.
- D-02: definir el control de concurrencia sin índices antes de F3 y F5.
- D-04: definir la regla de tiempo fijo antes de F3.
- D-07: definir si el MVP es un negocio por despliegue o multi-tenant antes de F1.
- D-10: definir el detalle del reporte de cierre antes de F5.
