# ADR-003: Persistencia local — Drift

**Estado:** Aceptado  
**Fecha:** 2026-08-12  
**Autores:** Equipo Sin Anuncios Nunca

---

## Contexto

Pluma es completamente offline. Todos los datos (documentos, proyectos, estadísticas,
objetivos) viven localmente. Necesitamos una solución de persistencia que soporte:
- Queries complejas: filtrar por favorito, ordenar por fecha, buscar texto completo
- Streams reactivos: la UI se actualiza automáticamente cuando cambian los datos
- Migraciones seguras: el esquema evolucionará con nuevas features
- Tests in-memory: los tests de repositorio deben ser rápidos y reproducibles

## Problema

¿Qué base de datos local usar para Flutter en 2026?

## Opciones consideradas

### A. Drift 2.21+ ✅ ELEGIDA

- **Licencia:** MIT
- **Backend:** SQLite (vía `sqlite3_flutter_libs`)
- **Mantenimiento:** Activo, patrocinado por Stream y PowerSync, releases en 2026
- **Pro:** Type-safe queries en Dart, streams reactivos nativos, FTS5, threading en isolate integrado,
  migraciones con pasos explícitos, `NativeDatabase.memory()` para tests in-memory
- **Contra:** Requiere `build_runner` para codegen; curva de aprendizaje inicial

### B. sqflite

- **Licencia:** MIT
- **Pro:** Conocido, simple, sin codegen
- **Contra:** Raw SQL con `Map<String, dynamic>` — sin type safety, sin streams reactivos,
  migraciones 100% manuales, sin FTS5 out of the box, threading manual requerido

### C. ObjectBox 5.x

- **Licencia:** Apache-2.0 (bindings) + **Binary License** en la librería nativa
- **Pro:** Muy rápido, tiene sync integrado
- **Contra:** Licencia binaria propietaria en la librería nativa — riesgo legal para app comercial.
  Sin FTS5 nativo. Migraciones más frágiles que Drift.

### D. Isar / isar_community

- **Licencia:** Apache-2.0
- **Pro:** Rápido (Rust), API limpia
- **Contra:** El autor original abandonó el proyecto. `isar_community` es un fork de bug fixes
  sin desarrollo activo de features. **No recomendado para proyectos nuevos** (consenso 2026).

### E. Hive CE

- **Licencia:** Apache-2.0
- **Pro:** Muy rápido para key-value, AES-256 incluido
- **Contra:** Sin query engine. Filtrar documentos requiere iterar toda la colección O(n).
  Inaceptable para una biblioteca con miles de documentos y búsqueda de texto completo.

## Decisión

**Drift** como base de datos principal.  
**Hive CE** exclusivamente para preferencias de usuario (app_settings) — acceso síncrono,
inicialización antes de que AppDatabase esté lista.

### Por qué dos sistemas

Mantener Hive CE para settings es un trade-off: introduce un segundo sistema de persistencia
pero evita una complejidad de bootstrap donde AppDatabase (async) aún no está lista cuando
se necesita el ThemeMode para renderizar el primer frame. Hive CE síncrono resuelve esto elegantemente.

### FTS5 para búsqueda

Se crean triggers SQLite en `MigrationStrategy.onCreate` para mantener la tabla virtual
`documents_fts` sincronizada con `documents`. Esto permite `MATCH` queries sobre `title`
y `plain_text` sin trabajo adicional en el nivel Dart.

### Migraciones

`schemaVersion` se incrementa en cada cambio de esquema. `MigrationStrategy.onUpgrade`
tiene pasos explícitos con `ADD COLUMN` — nunca `DROP`. Tests de migración con
`drift_dev verifyAll`.

## Consecuencias

**Positivas:**
- Queries type-safe: errores de schema se detectan en compile time, no en runtime
- Streams reactivos: `watchAll()` actualiza la UI automáticamente sin `setState` manual
- Tests rápidos: `NativeDatabase.memory()` hace los unit tests de repositorio instantáneos
- FTS5: búsqueda de texto completo sobre miles de documentos en <10ms

**Negativas / trade-offs:**
- `build_runner` debe correr después de cada cambio de schema (automatizable en CI)
- Dos sistemas de persistencia (Drift + Hive CE): un desarrollador nuevo debe saber cuándo
  usar cada uno. Regla clara: Drift para todos los datos de dominio; Hive CE solo para settings.
