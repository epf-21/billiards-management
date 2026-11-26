# ADR-003: Alcance del MVP

## Decisión

El primer alcance implementable incluye:

- Sucursales, configuración y usuarios.
- Roles, permisos y asignación de sucursales.
- Tarifas y mesas.
- Sesiones de juego con tiempo libre o tiempo fijo.
- Consumos de productos.
- Caja, pagos y cierre de turno.

Quedan como esquema futuro, sin endpoints en esta etapa:

- Clientes.
- Reservas.
- Inventario, compras y proveedores.
- Gastos.
- Prepago, saldo y créditos.
- Promociones y torneos.

## Motivo

El primer objetivo es validar el camino que cobra: abrir turno, abrir sesión, calcular tiempo, cobrar y cerrar caja. Construir las funciones futuras antes de validar ese camino aumenta el coste y congela decisiones que todavía no se probaron.

## Consecuencias

- Las tablas de funciones futuras pueden existir en la base de datos, pero no se implementan endpoints ni pantallas para ellas.
- El primer slice vertical es: seed de arranque, login y sucursal, abrir turno, abrir sesión, finalizar, cobrar y cerrar turno.
- El seed de desarrollo crea el usuario `admin` con contraseña `admin123`, la sucursal `Sucursal Principal`, la tarifa `Mesa estandar` a 15 Bs por hora y la `Mesa 1`. La contraseña debe cambiarse antes de desplegar.
- Cualquier función fuera de este alcance requiere una decisión posterior.
