# ADR-002: Editor de texto — flutter_quill

**Estado:** Aceptado  
**Fecha:** 2026-08-12  
**Autores:** Equipo Sin Anuncios Nunca

---

## Contexto

El editor es el corazón de Pluma. Los usuarios pasan la mayor parte del tiempo en él.
Necesitamos un editor WYSIWYG (not Markdown raw) con: bold/italic/headers/lists/quotes,
undo/redo, word count, y soporte para focus mode y typewriter mode.

## Problema

¿Qué paquete de editor de texto usar en Flutter para iOS y Android?

## Opciones consideradas

### A. flutter_quill 11.5.1 ✅ ELEGIDA

- **Licencia:** MIT
- **Último release:** Mayo 2026 (activo)
- **Comunidad:** 2,150 likes, 225k descargas/semana, 2.9k GitHub stars
- **Formato:** Quill Delta JSON (industria estándar)
- **Pro:** Mayor comunidad, MIT limpio, toolbar altamente customizable
- **Contra:** Bug documentado de scroll en documentos >~5,000 palabras (issue #2351)

### B. appflowy_editor 6.2.0

- **Licencia:** MPL-2.0 (obliga a publicar modificaciones al código fuente del editor)
- **Último release:** Diciembre 2025 (8 meses sin actualización)
- **Pro:** Tiene search/replace y word count integrados
- **Contra:** Licencia MPL complica el uso en app comercial; dependencias pesadas (pdf, file_picker bundled)

### C. super_editor 0.2.7

- **Licencia:** MIT
- **Último stable:** Junio 2024 — **2+ años sin release estable**
- **Pro:** Mejor arquitectura tipográfica, Stylesheet model
- **Contra:** Sin stable reciente, undo/redo no estabilizado, sin search/replace

### D. fleather 1.27.0

- **Licencia:** MIT + BSD-3
- **Pro:** 160 pub points, ligero, long-doc performance mejorada explícitamente
- **Contra:** Publisher no verificado (sin accountability institucional), comunidad mínima (191 likes)

### E. Custom Markdown + TextField

- **Pro:** Control total, sin dependencias
- **Contra:** Requiere implementar desde cero: selección, formatos, search/highlight, paste. 
  Prácticamente reescribir lo que flutter_quill ya provee.

## Decisión

**flutter_quill 11.5.1.**

El único editor con un release estable publicado en 2026. MIT sin restricciones. La mayor
comunidad reduce el riesgo de encontrar un bug sin solución ni documentación.

### Mitigación del bug de large documents

El bug de scroll en documentos >5,000 palabras (issue #2351) se mitiga con rendering lazy:
documentos que superen 4,000 palabras se renderizan en secciones con `ListView.builder`.
Esta estrategia entra en Fase 3. Para Fases 1-2, el render completo es aceptable dado que
la mayoría de documentos iniciales serán menores a ese umbral.

### Formato de almacenamiento

Los documentos se guardan en Drift como **Quill Delta JSON** (campo `content`) con un campo
adicional `plainText` siempre sincronizado. Esto permite:
- Word count y FTS sin deserializar Delta en cada lectura
- Migración futura a otro editor: el `plainText` nunca se pierde; solo se necesita un parser Delta

### Revisión futura

Revisar **super_editor** cuando publique 0.3.0 stable. Su modelo de Stylesheet es superior.
El `EditorRepository` actúa como interfaz de aislamiento que facilita un eventual swap.

## Consecuencias

**Positivas:**
- Ecosystem maduro, muchos ejemplos y Stack Overflow answers
- MIT sin restricciones legales
- Delta format facilita futura colaboración o sincronización si se desea

**Negativas / trade-offs:**
- Acoplamiento a Quill Delta format. Mitigado con `plainText` siempre disponible.
- Search/replace debe implementarse como overlay custom (no viene incluido).
- Typewriter mode requiere implementación manual via `QuillController.addListener` +
  `Scrollable.ensureVisible(alignment: 0.5)`.
- El bug de large documents requiere trabajo adicional en Fase 3.
