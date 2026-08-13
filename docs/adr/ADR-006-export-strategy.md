# ADR-006: Estrategia de exportación e importación

**Estado:** Aceptado  
**Fecha:** 2026-08-12  
**Autores:** Equipo Sin Anuncios Nunca

---

## Contexto

Pluma debe permitir exportar documentos a formatos estándar e importar texto. Toda la
exportación/importación debe ser local — sin servidores, sin APIs externas.

## Problema

¿Qué formatos soportar y cómo implementarlos sin dependencias externas costosas?

## Decisión

### Formatos de exportación

| Formato | Implementación | Paquete |
|---------|---------------|---------|
| `.txt`  | `document.plainText` directo | ninguno |
| `.md`   | Parser Delta → Markdown (implementación propia, ~100 líneas) | ninguno |
| `.pdf`  | `pdf` package, genera localmente | `pdf` + `printing` |

**Por qué no `.docx`:** Requiere un parser de ZIP + XML complejo. El paquete `docx_template`
existe pero el formato Word es demasiado complejo para garantizar fidelidad. Descartado en v1.

**Markdown export:** Los atributos Delta (bold, italic, heading, list) tienen correspondencia
directa con Markdown. El parser es determinístico y testeable en unit tests sin dependencias.
Si el documento tiene elementos sin equivalente en Markdown (p.ej. colores custom), se ignoran
gracefully.

**PDF export:** `pdf` package (Apache-2.0) genera PDFs 100% localmente. Usa `MultiPage` para
paginación automática. La tipografía usa los mismos fonts bundled (Merriweather). El usuario
puede previsualizar con `printing` antes de compartir.

### Compartir

`share_plus` delega al OS share sheet estándar (UIActivityViewController en iOS,
`ACTION_SEND` en Android). Soporta compartir texto, URIs y archivos.

### Importación

`file_picker` para seleccionar `.txt` o `.md`. El contenido se importa como nuevo
documento; el Markdown se convierte a Quill Delta via un parser simple.

### Backup local

En Fase 7: exportar todos los documentos como un ZIP de archivos `.md` nombrados
`YYYY-MM-DD-titulo.md`. Implementación con `dart:io` + `archive` package.

### Formatos explícitamente descartados en v1

- EPUB: demasiado complejo para garantizar fidelidad
- HTML: útil para web, no para un app móvil
- DOCX: complejidad del formato Word inaceptable para una implementación correcta

## Consecuencias

**Positivas:**
- TXT y MD se implementan sin dependencias adicionales
- PDF local es alta calidad y funciona offline
- Testabilidad: el parser Delta→Markdown es una función pura, fácilmente testeable

**Negativas / trade-offs:**
- Sin exportación a DOCX — los usuarios que necesiten Word deben exportar MD o TXT
- El parser Delta→Markdown debe mantenerse en sync si se añaden nuevos tipos de bloques
  en futuras versiones del editor
