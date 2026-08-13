# ADR-001: Arquitectura de la aplicación

**Estado:** Aceptado  
**Fecha:** 2026-08-12  
**Autores:** Equipo Sin Anuncios Nunca

---

## Contexto

Pluma es la primera app de la iniciativa "Sin Anuncios Nunca": una herramienta de escritura
premium, completamente offline, sin cuentas ni backend. Es un proyecto de 1-2 desarrolladores.

Se necesita una arquitectura que:
- Sea mantenible a largo plazo sin sobreingeniería
- Permita testing unitario real en domain y data layers
- Separe claramente la UI de la lógica de negocio
- Escale a 10+ features sin volverse un monolito plano

## Problema

¿Qué patrón arquitectónico adoptar para un proyecto Flutter de tamaño medio con un equipo pequeño?

## Opciones consideradas

### A. Feature-first + Clean Architecture simplificada ✅ ELEGIDA

Cada feature tiene sus propias carpetas `data/`, `domain/`, `presentation/`.
Clean Architecture en cuanto a dirección de dependencias: `Presentation → Domain ← Data`.

**Sin**:
- Capa Application explícita (se introduce solo si una lógica cruza 2+ repositorios)
- Use Cases / Interactors (sobreingeniería para este scope)
- Inyección de dependencias con frameworks como GetIt (Riverpod ya actúa como DI)

### B. Layer-first (global)

Agrupar todos los modelos juntos, todos los repositorios juntos, todos los screens juntos.

Descartada: a medida que crece el proyecto, hay que navegar entre 3-4 carpetas para hacer
un cambio en una sola feature.

### C. Clean Architecture completa con Use Cases

Añadir `domain/use_cases/` con un archivo por cada operación.

Descartada: añade ~30-40% de archivos sin aportar valor real en un equipo de 1-2 devs.
El contrato ya está en la interfaz del repositorio.

## Decisión

**Feature-first + Clean Architecture simplificada.**

```
lib/
  features/
    <feature>/
      data/        # DAOs, implementaciones de repositorios
      domain/      # Modelos Freezed, interfaces de repositorios
      presentation/# Screens, Notifiers, Widgets
  core/            # Theme, router, database, extensions — sin lógica de negocio
  shared/          # Widgets y modelos genuinamente cross-feature
```

**Regla de extracción de `XService`:** Si un `AsyncNotifier` supera ~200 líneas
o necesita coordinar 2+ repositorios, extraer un `XService` en `features/X/domain/`.
Esta regla evita Notifiers gordos sin forzar la abstracción antes de tiempo.

## Consecuencias

**Positivas:**
- Cambios en una feature están co-localizados en su carpeta
- Testing directo sin frameworks de DI complejos
- Bajo tiempo de onboarding para un nuevo desarrollador

**Negativas / trade-offs:**
- Sin Use Cases: riesgo de duplicar lógica si dos features necesitan la misma operación.
  Mitigación: mover la lógica al `domain/` de la feature más relevante y referenciarla.
- Feature-first puede resultar en `shared/` hinchado si no se disciplina. Regla: nada
  entra en `shared/` hasta que lo necesiten dos features distintas.
