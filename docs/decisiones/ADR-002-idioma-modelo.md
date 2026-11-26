# ADR-002: DBML en español, SQL en inglés

## Decisión

El modelo de datos se mantiene en dos representaciones:

- `docs/billiards_modelo.dbml` en español, como herramienta de modelado y conversación.
- Las migraciones SQL en inglés, como implementación real de la base de datos.

Cada cambio de columnas, tablas, enums o constraints debe aplicarse en ambas representaciones en el mismo cambio.

## Motivo

El modelado es más rápido en el idioma nativo del autor. El código y la base de datos usan inglés para seguir la convención del backend. La diferencia es deliberada y no debe resolverse traduciendo una representación sobre la otra.

## Consecuencias

- No se genera SQL automáticamente desde el DBML ni el DBML desde el SQL.
- La revisión de un cambio debe confirmar que ambas representaciones coinciden en nombres equivalentes, tipos y reglas.
- Las diferencias de idioma no son un error de consistencia; las diferencias de estructura sí.
