# ADR-004: State management — Riverpod

**Estado:** Aceptado  
**Fecha:** 2026-08-12  
**Autores:** Equipo Sin Anuncios Nunca

---

## Contexto

La aplicación necesita gestión de estado reactiva para: lista de documentos, estado del
editor (contenido, word count, autosave), estadísticas, y preferencias. En todos los casos,
el estado proviene de un stream de base de datos local (Drift) o de Hive CE.

## Problema

¿Qué solución de state management usar en Flutter en 2026 para un equipo de 1-2 devs?

## Opciones consideradas

### A. Riverpod 3.x con codegen ✅ ELEGIDA

- **Licencia:** MIT. Autor: Remi Rousselet.
- **Boilerplate:** ~42% menos código que BLoC en features equivalentes (benchmarks 2026)
- **DI:** Integrado — providers son el grafo de dependencias; sin GetIt ni injectable
- **Streams reactivos:** `StreamProvider` y `AsyncNotifier` envuelven Drift streams nativamente
- **Testing:** `ProviderContainer` con overrides — no requiere `BuildContext`
- **Codegen:** `@riverpod` annotation + `riverpod_generator` — errors en compile time

### B. BLoC / Cubit 9.x

- **Licencia:** MIT. Muy maduro.
- **Pro:** "Disciplina como feature" — evento/estado separados hacen el flujo explícito
- **Contra:** ~42% más boilerplate. Para equipo de 2 personas la ceremonia no aporta valor.
  Los eventos sealed necesitan un archivo por feature. Requiere `get_it` + `injectable` para DI.
  Adecuado para equipos grandes o industrias reguladas.

### C. Provider

- **Licencia:** MIT.
- **Pro:** Mínimo boilerplate
- **Contra:** Considerado legado. La Flutter team señala Riverpod como sucesor.
  Sin streams reactivos nativos — `notifyListeners()` manual. Sin type-safety en providers.

### D. MobX

- **Licencia:** MIT.
- **Pro:** Bajo boilerplate, familar para developers de React
- **Contra:** Reactivity implícita (reactions basadas en observable access) es más difícil
  de debuggear que el grafo explícito de Riverpod. No crece en la comunidad Flutter en 2026.

## Decisión

**Riverpod 3.x con `riverpod_annotation` (codegen).**

El patrón estándar es `AsyncNotifier` para state que viene de streams async (documentos,
estadísticas) y `Notifier` para state síncrono (filtros de búsqueda, UI state).

### Codegen vs manual

Con codegen: se añade un paso `dart run build_runner watch` al workflow de desarrollo.
Sin codegen: completamente válido, especialmente para notifiers simples. La decisión de
usar codegen es por feature, no global — un `Notifier` simple puede ser manual.

### Regla para Notifiers gordos

Si un `AsyncNotifier` supera ~200 líneas o coordina 2+ repositorios, extraer un `XService`
en `features/X/domain/` e inyectarlo via provider. Ver ADR-001.

## Consecuencias

**Positivas:**
- DI sin framework adicional — `ProviderScope.overrides` en tests
- `ref.watch(streamProvider)` es idiomático para Drift streams
- `AsyncValue` maneja loading/error/data automáticamente en la UI
- Compile-time safety con codegen

**Negativas / trade-offs:**
- Curva de aprendizaje inicial para desarrolladores que vienen de Provider o BLoC
- `build_runner watch` necesita estar corriendo durante el desarrollo con codegen
- Riverpod 3.x tuvo breaking changes desde 2.x — documentación en transición
