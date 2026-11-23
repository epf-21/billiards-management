# Sistema de Gestión para Billar: MVP y Mejoras

Documento de definición del proyecto.

## 1. Objetivo del proyecto

Construir un sistema que permita **controlar mesas, tiempo de juego y consumos, y cobrar sin errores** en un salón de billar, reemplazando el cuaderno o la hoja de cálculo que normalmente se usa.

Problemas que resuelve:

- Cobros de tiempo mal calculados o sin registrar.
- Consumos (bebidas, snacks) olvidados en la cuenta.
- Falta de control del inventario y de la caja diaria.
- Ausencia de reportes para que el dueño sepa cuánto ganó realmente.

## 2. Alcance del MVP

El MVP incluye únicamente lo necesario para operar un día completo de trabajo en el local, de la apertura al cierre de caja.

### 2.1 Gestión de mesas

- Registro de mesas con nombre o número.
- Tipo de mesa (pool, carambola, snooker u otros), cada tipo con su tarifa.
- Estado de cada mesa: **libre**, **ocupada**, **reservada** o **en mantenimiento**.
- Vista general del salón con el estado de todas las mesas de un vistazo.

### 2.2 Control de tiempo

- Iniciar, pausar, reanudar y finalizar una sesión de juego por mesa.
- Cobro por hora, por fracción (cada 15 o 30 minutos) o por tiempo libre, configurable.
- Cambio de una sesión a otra mesa sin perder el tiempo acumulado.
- Cronómetro visible en tiempo real para cada mesa ocupada.

### 2.3 Consumos

- Catálogo de productos (bebidas, snacks, comida) con nombre, categoría y precio.
- Agregar y quitar consumos de la cuenta de una mesa mientras está activa.
- Descuento automático del stock al registrar un consumo.

### 2.4 Cobro y caja

- Cuenta final = tiempo de juego + consumos.
- División de la cuenta entre jugadores, cuando se necesite.
- Registro del método de pago: efectivo, QR o transferencia.
- Apertura y cierre de caja por turno.
- Reporte del cierre: total cobrado, desglose por método de pago y por concepto (tiempo y consumos).

### 2.5 Usuarios y roles

- Inicio de sesión con usuario y contraseña.
- **Administrador**: configura tarifas, productos, mesas y usuarios, y ve todos los reportes.
- **Encargado**: supervisa la operación y al personal de la sucursal; controla productos, existencias y movimientos.
- **Cajero**: opera mesas, registra consumos y cobra.

## 3. Fuera del alcance del MVP

Lo siguiente no se construye en esta primera versión, pero el diseño de datos debe permitir agregarlo después sin rehacer lo existente:

- Reservas de mesas.
- Registro y fidelización de clientes.
- Torneos y rankings.
- Aplicación para clientes.

## 4. Requisitos no funcionales del MVP

- **Simplicidad**: el cajero debe poder iniciar una mesa y cobrarla en pocos toques o clics.
- **Fiabilidad**: el tiempo de una sesión no debe perderse si se cierra el navegador o se reinicia el dispositivo (el estado se guarda en el servidor).
- **Seguridad básica**: contraseñas cifradas y permisos por rol.
- **Trazabilidad**: cada cobro, consumo y movimiento de caja queda registrado con usuario y hora.

## 5. Entidades principales del modelo de datos

- Usuario (con rol) → feature `users`
- Mesa y TipoDeMesa (con tarifa) → feature `tables`
- Sesión de juego (mesa, hora de inicio, pausas, hora de fin) → feature `sessions`
- Producto y Categoría → feature `products`
- Consumo (producto, cantidad, sesión) → feature `consumptions`
- Cuenta/Venta y Pago → feature `cash`
- Caja (apertura, cierre, movimientos) → feature `cash`

## 6. Criterios de aceptación del MVP

El MVP se considera terminado cuando un cajero puede, en un turno completo:

1. Abrir caja.
2. Iniciar una sesión en una mesa libre y agregarle consumos.
3. Pausar, cambiar de mesa y finalizar la sesión.
4. Cobrar la cuenta con el método de pago elegido.
5. Cerrar caja y obtener un reporte correcto del día.

y el administrador puede configurar mesas, tarifas, productos y usuarios sin ayuda del desarrollador.

---

# Mejoras Futuras

Funciones que se agregan una vez que el MVP está en uso y estable. Están agrupadas por fases en orden de prioridad sugerido.

## Fase 2: Operación más completa

### Reservas

- Reservar una mesa por fecha, hora y duración estimada.
- Calendario visual de reservas por mesa.
- Cambio automático del estado de la mesa a "reservada" a la hora indicada.
- Aviso al cajero cuando se acerca una reserva.

### Clientes

- Registro de clientes con nombre y teléfono.
- Historial de visitas y consumos por cliente.
- Tarjetas de horas prepagadas y membresías.
- Descuentos o tarifas especiales por cliente.

### Inventario completo

- Registro de compras y proveedores.
- Alertas de stock bajo.
- Ajustes de inventario (mermas, pérdidas, conteos físicos).
- Costo de cada producto para calcular la ganancia real.

### Reportes avanzados

- Ingresos por mesa, por día, por semana y por mes.
- Horas de mayor y menor concurrencia.
- Productos más vendidos y de mayor margen.
- Ganancia neta (ingresos menos costos y gastos).
- Exportación a Excel o PDF.

### Comprobantes

- Ticket de cuenta imprimible.
- Envío del comprobante por WhatsApp o correo.

## Fase 3: Crecimiento y diferenciación

### Torneos y ligas

- Inscripción de jugadores.
- Generación de llaves o grupos y registro de resultados.
- Ranking de jugadores y premios.

### Pantalla pública

- Monitor en el local que muestra mesas libres y ocupadas, el ranking o promociones.

### App o web para clientes

- Ver mesas disponibles en tiempo real.
- Reservar y pagar en línea.
- Consultar saldo de horas prepagadas y puntos.

### Promociones

- Happy hour con tarifas distintas por horario.
- Combos (tiempo de juego + consumo).
- Programa de puntos o recompensas.

## Fase 4: Escala e integraciones

### Hardware

- Control automático de luces de las mesas al iniciar y finalizar la sesión.
- Impresora térmica de tickets y lector de código de barras.
- Cajón de dinero conectado.

### Facturación fiscal

- Emisión de facturas electrónicas según la normativa del país.

### Multi-sucursal

- Varias sedes bajo una misma cuenta, con reportes consolidados y por sucursal.
- Inventario y precios por sede.

### Modo offline

- Funcionamiento sin internet con sincronización posterior, útil si la conexión del local es inestable.

### Seguridad y auditoría

- Registro detallado de acciones (anulaciones, descuentos, cambios de precio).
- Respaldos automáticos de la base de datos.
- Autorización del administrador para anular cuentas o aplicar descuentos grandes.

## Orden de prioridad sugerido

| Prioridad | Mejora | Motivo |
| --- | --- | --- |
| 1 | Reportes avanzados e inventario completo | Dan control del negocio rápidamente |
| 2 | Clientes y prepago | Fidelizan y generan ingresos adelantados |
| 3 | Reservas | Reduce tiempos muertos de las mesas |
| 4 | Comprobantes y facturación | Depende de requisitos legales del local |
| 5 | Torneos, pantalla pública y app de clientes | Diferenciación frente a otros billares |
| 6 | Hardware y multi-sucursal | Solo si el negocio crece |
