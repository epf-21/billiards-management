# ADR-001: Dinero decimal y cobro por hora

## Decisión

Los importes monetarios se guardan como `NUMERIC(12,2)` en PostgreSQL y como tipo decimal en Go, nunca como `float64`.

El cobro por tiempo tiene dos modalidades: tiempo libre y tiempo fijo. La tarifa es por hora y se cobra de forma proporcional a los minutos jugados. El importe se redondea a dos decimales al generar la cuenta.

Ejemplo: una mesa a 15 Bs por hora, jugada 30 minutos, cobra 7.50 Bs.

No se cobra por fracciones de 15 o 30 minutos y no se redondea a la unidad.

## Motivo

El local cobra por hora y necesita cobrar fracciones de hora sin perder centavos. El redondeo por tramo o a la unidad produce diferencias entre lo que ve el cliente y lo que registra la caja.

## Consecuencias

- El DBML y las migraciones usan `numeric(12,2)` para todos los montos.
- La sesión conserva la tarifa aplicada al iniciar.
- El cálculo se hace por minuto y se redondea una sola vez, al total de la cuenta.
- Queda prohibido el redondeo a la unidad entera y el cobro por bloques de 15 o 30 minutos.
